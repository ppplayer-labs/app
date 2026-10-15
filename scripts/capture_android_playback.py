"""Read-only debug WebView/media observer. Never persists signed URL queries or headers."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import threading
import time
from urllib.parse import urlsplit
from urllib.request import urlopen

SAMPLE = r'''(()=>({wallMs:Date.now(),perfMs:performance.now(),origin:location.origin,hidden:document.hidden,visibility:document.visibilityState,focus:document.hasFocus(),videos:Array.from(document.querySelectorAll('video,audio')).map(v=>({tag:v.tagName,time:v.currentTime,paused:v.paused,ended:v.ended,ready:v.readyState,network:v.networkState,error:v.error?{code:v.error.code,message:v.error.message}:null,buffered:Array.from({length:v.buffered.length},(_,i)=>[v.buffered.start(i),v.buffered.end(i)]),width:v.videoWidth,height:v.videoHeight,quality:v.getVideoPlaybackQuality? (()=>{const q=v.getVideoPlaybackQuality();return {total:q.totalVideoFrames,dropped:q.droppedVideoFrames,corrupted:q.corruptedVideoFrames}})():null})),mediaSession:navigator.mediaSession? navigator.mediaSession.playbackState:null}))()'''


def safe_url(url):
    try:
        value = urlsplit(url)
        if value.scheme not in ['http','https']:return value.scheme + ':[omitted]'
        host = value.hostname or ''
        if ':' in host:host = '['+host+']'
        authority = host + (':'+str(value.port) if value.port else '')
        return value.scheme + '://' + authority + value.path
    except ValueError:
        return '[invalid URL]'


def main():
    import websocket  # diagnostic host dependency; never an app/runtime dependency
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--device', default='emulator-5554')
    p.add_argument('--directory', required=True)
    p.add_argument('--seconds', type=int, default=240)
    a = p.parse_args()
    root = Path(a.directory); root.mkdir(parents=True, exist_ok=True)
    stop = threading.Event()
    lock = threading.Lock()
    def record(kind, value):
        with lock, (root/'cdp.jsonl').open('a') as f:
            f.write(json.dumps({'observerWallMs':int(time.time()*1000),'kind':kind,'value':value})+'\n')
    def adb(*args):
        return subprocess.check_output(['adb','-s',a.device,*args],text=True,timeout=20)
    log = (root/'native.log').open('w')
    native = subprocess.Popen(['adb','-s',a.device,'logcat','-T','1','-v','epoch','-s','ChromiumBG','MediaCodec','CCodec','ACodec','AudioTrack','AudioManager','MediaFocusControl','AudioService','cr_MediaCodecBridge','cr_AwContents','cr_MediaPlayerBridge','CCodecConfig','CCodecBufferChannel','BufferQueueProducer','SurfaceUtils','goldfish_vpx','PipDebug'],stdout=log,stderr=subprocess.STDOUT)
    workers=[]; attached=set(); forwards=[]
    def observe(url):
        ws=None
        try:
            ws=websocket.create_connection(url,timeout=1,suppress_origin=True)
            seq=0; contexts={}; next_sample=0
            def send(method,params=None):
                nonlocal seq
                seq+=1;ws.send(json.dumps({'id':seq,'method':method,'params':params or {}}))
            for method in ['Runtime.enable','Network.enable','Media.enable','Page.enable']:
                send(method)
            while not stop.is_set():
                if time.monotonic()>next_sample:
                    for context in list(contexts):
                        send('Runtime.evaluate',{'expression':SAMPLE,'contextId':context,'returnByValue':True})
                    next_sample=time.monotonic()+1
                try:message=json.loads(ws.recv())
                except websocket.WebSocketTimeoutException:continue
                method=message.get('method',''); params=message.get('params',{})
                if method=='Runtime.executionContextCreated':
                    context=params['context'];contexts[context['id']]=context.get('origin');record('context',{'id':context['id'],'origin':context.get('origin'),'aux':context.get('auxData')})
                elif method=='Runtime.executionContextDestroyed':contexts.pop(params['executionContextId'],None)
                elif method=='Runtime.executionContextsCleared':contexts.clear()
                elif method=='Network.requestWillBeSent':
                    req=params['request'];record(method,{'id':params['requestId'],'timestamp':params.get('timestamp'),'wallTime':params.get('wallTime'),'url':safe_url(req['url']),'type':params.get('type')})
                elif method=='Network.responseReceived':
                    r=params['response'];record(method,{'id':params['requestId'],'timestamp':params.get('timestamp'),'url':safe_url(r['url']),'status':r['status'],'mime':r.get('mimeType'),'protocol':r.get('protocol'),'cache':r.get('fromDiskCache')})
                elif method in ['Network.loadingFailed','Network.loadingFinished','Network.dataReceived']:
                    record(method,{k:v for k,v in params.items() if k in ['requestId','timestamp','errorText','canceled','blockedReason','encodedDataLength','dataLength','type']})
                elif method.startswith('Media.'):
                    # Player properties/events can contain signed media URLs.
                    clean=re.sub(r'https?[^\s\"<>]+',lambda m:safe_url(m.group()),json.dumps(params));record(method,json.loads(clean))
                elif 'id' in message:
                    result=message.get('result',{}).get('result',{}).get('value')
                    if result is not None:record('sample',result)
        except Exception as e:record('observerError',{'type':type(e).__name__,'message':str(e)[:180]})
        finally:
            if ws:ws.close()
    try:
        record('device',{'wallMs':int(time.time()*1000),'deviceEpoch':adb('shell','date','+%s'),'webview':adb('shell','dumpsys','webviewupdate').splitlines()[:7]})
        deadline=time.monotonic()+a.seconds;next_dump=0
        while time.monotonic()<deadline:
            try:
                pid=adb('shell','pidof','com.ppplayer.app').strip().split()[0]
                sockets=adb('shell','cat','/proc/net/unix')
                for sock in re.findall(r'@(webview_devtools_remote[^\s]*)',sockets):
                    if not sock.endswith('_'+pid):continue
                    port=9230
                    if sock not in attached:
                        adb('forward',f'tcp:{port}','localabstract:'+sock);forwards.append(port)
                        targets=json.load(urlopen(f'http://127.0.0.1:{port}/json',timeout=2))
                        for target in targets:
                            if target.get('type')=='page':
                                record('target',{'type':target['type'],'url':safe_url(target.get('url',''))})
                                t=threading.Thread(target=observe,args=(target['webSocketDebuggerUrl'],),daemon=True);t.start();workers.append(t)
                        if targets:attached.add(sock)
                if time.monotonic()>next_dump:
                    stamp=str(int(time.time()*1000))
                    for service in ['audio','media_session','media.player','media.resource_manager','media.audio_flinger','power','activity services com.ppplayer.app']:
                        cmd=service.split()
                        try:data=adb('shell','dumpsys',*cmd)
                        except subprocess.SubprocessError as e:data='Unavailable: '+type(e).__name__
                        (root/(stamp+'-'+cmd[0].replace('.','-')+'.txt')).write_text(data)
                    next_dump=time.monotonic()+10
            except Exception as e:record('pollError',{'type':type(e).__name__})
            stop.wait(0.5)
    finally:
        stop.set()
        for t in workers:t.join(timeout=3)
        native.terminate();native.wait(timeout=10);log.close()
        for port in set(forwards):
            subprocess.run(['adb','-s',a.device,'forward','--remove',f'tcp:{port}'],capture_output=True)


if __name__=='__main__':main()
