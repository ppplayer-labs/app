"""Whole-application preflight collector; group footprints are never summed."""
import argparse
import json
import os
from pathlib import Path
import re
import resource
import subprocess
import time
from macos_disposal_memory_capture import process_rows, identity, tree, capture, utc


def role(row, app):
    if row['pid'] == app: return 'flutter_application'
    if 'ChromiumWebView Helper' in row['command']:
        return row['utilitySubtype'] or row['role']
    if 'ChromiumWebViewHost' in row['command']: return 'cef_host'
    return 'other_owned_descendant'


def discover(rows, app, observer, prior):
    excluded = {r['pid'] for r in tree(rows, observer)}
    old = {tuple(v) for v in prior.get('knownIdentities', [])}
    selected = {r['pid'] for r in tree(rows, app)} - excluded
    selected |= {r['pid'] for r in rows if identity(r) in old and r['pid'] not in excluded}
    # Descendants of known reparented identities remain owned.
    while True:
        expanded = selected | {r['pid'] for r in rows if r['ppid'] in selected and r['pid'] not in excluded}
        if expanded == selected: break
        selected = expanded
    owned = [dict(r, processRole=role(r, app)) for r in rows if r['pid'] in selected]
    current = {identity(r): r for r in owned}
    previous = {tuple(r['identity']): r for r in prior.get('previous', [])}
    events = []
    for key, r in current.items():
        if key not in previous:
            reused = any(k[0] == key[0] and k != key for k in old)
            events.append(dict(event='pid_reuse' if reused else 'created', identity=key, ppid=r['ppid']))
        elif previous[key]['ppid'] != r['ppid']:
            events.append(dict(event='reparented', identity=key, before=previous[key]['ppid'], after=r['ppid']))
    events += [dict(event='exited', identity=key) for key in previous if key not in current]
    known = old | set(current)
    return owned, dict(knownIdentities=[list(k) for k in sorted(known)],
                       previous=[dict(identity=k, ppid=r['ppid']) for k,r in current.items()]), events


def footprint_values(data, pids):
    if data.get('unit') != 'byte' or data.get('bytes per unit') != 1:
        raise ValueError('Unsupported footprint units')
    if data.get('errors'): raise ValueError(f"Footprint errors: {data['errors']}")
    if {p['pid'] for p in data['processes']} != set(pids):
        raise ValueError('Footprint process scope mismatch')
    total = data.get('total footprint')
    dirty = data.get('summary', {}).get('total', {}).get('dirty')
    if not isinstance(total, (int,float)) or total != dirty:
        raise ValueError('Missing or incompatible deduplicated group footprint')
    return dict(groupChargedBytes=total,
                groupMetrics=data['summary']['total'],
                categories=data['summary'],
                perProcessChargedBytes={str(p['pid']):p.get('auxiliary',{}).get('phys_footprint') for p in data['processes']})


def numeric_fds(text): return len(set(re.findall(r'^f(\d+)$',text,re.M)))


def listing():
    return process_rows(subprocess.check_output(['/bin/ps','-axo','pid=,ppid=,lstart=,rss=,command='],text=True))


def run(app, host, directory, state_path, phase, mode):
    directory.mkdir(parents=True,exist_ok=False)
    started=time.monotonic(); started_utc=utc(); cpu_before=resource.getrusage(resource.RUSAGE_CHILDREN)
    previous=json.loads(state_path.read_text()) if state_path.exists() else {}
    owned,state,events=discover(listing(),app,os.getpid(),previous)
    errors=[]; commands=[]
    if not any(r['pid']==app for r in owned):errors.append('Application root absent')
    hosts=[r for r in owned if r['processRole']=='cef_host']
    if phase=='A' and any('ChromiumWebView' in r['command'] for r in owned):errors.append('CEF already present at A')
    if phase!='A' and (len(hosts)!=1 or hosts[0]['pid']!=host):errors.append('Missing or unexpected host')
    if phase.startswith('P') or phase.startswith('W'):
        expected={'gpu-process','network.mojom.NetworkService','storage.mojom.StorageService'}
        missing=expected-{r['processRole'] for r in owned}
        if missing:errors.append(f'Missing expected processes: {sorted(missing)}')
    if previous.get('hostIdentity') and hosts and list(identity(hosts[0]))!=previous['hostIdentity']:
        errors.append('Unexpected host restart')
    if hosts: state['hostIdentity']=list(identity(hosts[0]))
    for r in owned:
        r['executablePath']=subprocess.check_output(['/bin/ps','-p',str(r['pid']),'-o','comm='],text=True).strip()
    state['hostIdentity']=state.get('hostIdentity',previous.get('hostIdentity'))
    scopes={'wholeApplication':owned,'cefOnly':[r for r in owned if 'ChromiumWebView' in r['command']]}
    measures={}
    collect = mode=='measurement' or phase=='W2'
    for name,rows in scopes.items():
        measures[name]=dict(processCount=len(rows),summedRssKiB=sum(r['rssKiB'] for r in rows),
                            footprint=None,unavailableReason=None)
        if not rows:
            measures[name]['unavailableReason']='No CEF runtime exists at phase A'
            continue
        if not collect:
            measures[name]['unavailableReason']='Control: periodic footprint collection disabled; common W2 endpoint retained'
            continue
        command=['/usr/bin/footprint','--wide','--format','bytes','--json',str(directory/f'{name}.json')]
        for row in rows:command+=['-p',str(row['pid'])]
        record=capture(command,directory/f'{name}.txt');commands.append(record)
        try: measures[name]['footprint']=footprint_values(json.loads((directory/f'{name}.json').read_text()),[r['pid'] for r in rows])
        except (OSError,ValueError,KeyError,TypeError) as error: errors.append(f'{name}: {error}')
        now={identity(r) for r in listing()}
        if not {identity(r) for r in owned} <= now:errors.append('Selected process exited or PID identity changed during group capture')
    for name,command in {'pressure':['/usr/bin/memory_pressure','-Q'],
                          'swap':['/usr/sbin/sysctl','vm.swapusage'],
                          'vmstat':['/usr/bin/vm_stat'],
                          'cpu':['/bin/ps','-axo','pid=,pcpu=,rss=,comm=']}.items():
        commands.append(capture(command,directory/f'{name}.txt'))
    # One lsof invocation for all selected PIDs; only numeric descriptors are counted.
    if owned:
        commands.append(capture(['/usr/sbin/lsof','-nP','-p',','.join(str(r['pid']) for r in owned),'-Fpf'],directory/'fds.txt'))
        fds={}; pid=None
        for line in (directory/'fds.txt').read_text().splitlines():
            if line.startswith('p') and line[1:].isdigit():pid=int(line[1:]);fds[pid]=set()
            elif pid is not None and re.fullmatch(r'f\d+',line):fds[pid].add(int(line[1:]))
        for row in owned:row['numericFileDescriptors']=len(fds[row['pid']]) if row['pid'] in fds else None
    if any(c['exitStatus']!=0 for c in commands):errors.append('Capture command failure')
    after_owned,after_state,after_events=discover(listing(),app,os.getpid(),state)
    if {identity(r) for r in after_owned}!={identity(r) for r in owned}:errors.append('Owned process scope changed during capture')
    events+=after_events
    state.update(after_state)
    state['history']=previous.get('history',[])+[dict(phase=phase,utc=utc(),events=events,processes=owned,afterProcesses=after_owned)]
    state_path.parent.mkdir(parents=True,exist_ok=True);state_path.write_text(json.dumps(state,indent=2)+'\n')
    cpu_after=resource.getrusage(resource.RUSAGE_CHILDREN)
    result=dict(phase=phase,mode=mode,startedUtc=started_utc,collectorChildCpuSeconds=(cpu_after.ru_utime+cpu_after.ru_stime)-(cpu_before.ru_utime+cpu_before.ru_stime),
        endedUtc=utc(),durationSeconds=time.monotonic()-started,appPid=app,hostPid=host,
        hostGenerationProvenance='single observed host identity; restart is an error',processes=owned,events=events,
        scopes=measures,commands=commands,errors=errors,passed=not errors,
        observerExclusion='collector PID and descendants; not part of hosting workload',
        sequentialScopeCaptures=True)
    (directory/'capture.json').write_text(json.dumps(result,indent=2)+'\n')
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--app-pid',type=int,required=True);p.add_argument('--host-pid',type=int,default=0)
    p.add_argument('--directory',type=Path,required=True);p.add_argument('--state',type=Path,required=True)
    p.add_argument('--phase',required=True);p.add_argument('--mode',choices=['measurement','control'],required=True)
    a=p.parse_args();result=run(a.app_pid,a.host_pid,a.directory,a.state,a.phase,a.mode)
    print(json.dumps(dict(passed=result['passed'],errors=result['errors'])))
    raise SystemExit(0 if result['passed'] else 1)
