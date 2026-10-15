"""Capture matched, same-host disposal memory diagnostics without altering CEF."""
import argparse
import datetime
import json
from pathlib import Path
import re
import subprocess
import time


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def process_rows(text):
    rows = []
    for line in text.splitlines():
        fields = line.split(None, 8)
        if len(fields) != 9:
            continue
        pid, parent = map(int, fields[:2])
        command = re.sub(r'--ipc-token=\S+', '--ipc-token=<redacted>', fields[8])
        role = re.search(r'--type=(\S+)', command)
        subtype = re.search(r'--utility-sub-type=(\S+)', command)
        rows.append(dict(pid=pid, ppid=parent, startLocal=' '.join(fields[2:7]),
                         rssKiB=int(fields[7]), command=command,
                         role=role[1] if role else 'host',
                         utilitySubtype=subtype[1] if subtype else None))
    return rows


def tree(rows, host):
    selected = {host}
    while True:
        expanded = selected | {r['pid'] for r in rows if r['ppid'] in selected}
        if expanded == selected:
            return [r for r in rows if r['pid'] in selected]
        selected = expanded


def snapshot(host):
    return tree(process_rows(subprocess.check_output(
        ['/bin/ps', '-axo', 'pid=,ppid=,lstart=,rss=,command='], text=True)), host)


def identity(row):
    return row['pid'], row['startLocal'], row['command']


def capture(command, path, timeout=60):
    record = dict(command=command, startedUtc=utc())
    start = time.monotonic()
    with path.open('w') as output:
        try:
            result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT,
                                    timeout=timeout)
            record['exitStatus'] = result.returncode
        except (OSError, subprocess.TimeoutExpired) as error:
            output.write(f'\nCAPTURE ERROR: {error}\n')
            record.update(exitStatus=None, error=str(error))
    record.update(endedUtc=utc(), durationSeconds=time.monotonic() - start,
                  output=path.name)
    return record


def run(host, directory):
    directory.mkdir(parents=True, exist_ok=False)
    report = dict(startedUtc=utc(), hostPid=host, captures=[], errors=[])
    before = snapshot(host)
    report['before'] = before
    if not any(p['pid'] == host for p in before):
        raise RuntimeError('Host absent; refusing to capture a different process set')
    command = ['/usr/bin/footprint', '--wide', '--format', 'bytes', '--json',
               str(directory / 'footprint.json')]
    for row in before:
        command += ['-p', str(row['pid'])]
    report['captures'].append(capture(command, directory / 'footprint.txt'))
    try:
        fp = json.loads((directory / 'footprint.json').read_text())
        captured = {p['pid'] for p in fp['processes']}
        if captured != {p['pid'] for p in before} or fp.get('errors'):
            report['errors'].append('Footprint PID set mismatch or tool errors')
        if fp.get('unit') != 'byte' or fp.get('bytes per unit') != 1:
            report['errors'].append('Unexpected footprint units')
        report['footprintWarnings'] = fp.get('warnings')
    except (OSError, ValueError, KeyError) as error:
        report['errors'].append(f'Footprint JSON unavailable: {error}')
    for row in before:
        current = {p['pid']: p for p in snapshot(host)}
        if row['pid'] not in current or identity(current[row['pid']]) != identity(row):
            report['errors'].append(f"Process identity changed before vmmap: {row['pid']}")
            continue
        path = directory / f"vmmap-{row['pid']}.txt"
        report['captures'].append(capture(['/usr/bin/vmmap', '-summary', str(row['pid'])], path))
        content = path.read_text()
        if 'REGION TYPE' not in content or 'cannot examine' in content or 'unable to' in content:
            report['errors'].append(f"vmmap incomplete for PID {row['pid']}")
        # Numeric descriptors are separate from lsof's memory-map/cwd rows.
        fd = directory / f"lsof-{row['pid']}.txt"
        record = capture(['/usr/sbin/lsof', '-nP', '-p', str(row['pid']), '-Ff'], fd)
        report['captures'].append(record)
        row['numericFileDescriptors'] = len(set(re.findall(r'^f(\d+)', fd.read_text(), re.M)))
    after = snapshot(host)
    report['after'] = after
    if {identity(p) for p in before} != {identity(p) for p in after}:
        report['errors'].append('Process set or start identity changed during capture')
    if any(c['exitStatus'] != 0 for c in report['captures']):
        report['errors'].append('One or more capture commands failed')
    report.update(endedUtc=utc(), passed=not report['errors'])
    (directory / 'capture.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host-pid', type=int, required=True)
    parser.add_argument('--directory', type=Path, required=True)
    args = parser.parse_args()
    result = run(args.host_pid, args.directory)
    print(json.dumps(dict(passed=result['passed'], errors=result['errors'])))
    raise SystemExit(0 if result['passed'] else 1)
