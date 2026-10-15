"""Drive the offline Android WebView lifecycle control (no remote media)."""
import argparse
import re
import json
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', default='emulator-5554')
    parser.add_argument('--log', default='build/validation/android-webview-control.log')
    parser.add_argument('--video', action='store_true', help='Use offline looping video instead of audio')
    parser.add_argument('--online-url', default='', help='Direct HTTPS media control, no YouTube iframe')
    parser.add_argument('--mse-second-url', default='', help='Append second VP9/Opus WebM via MSE for adaptive resolution control')
    parser.add_argument('--foreground-only', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    path = Path(args.log).resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    actions = {
        'WEBVIEW_CONTROL_HOME_READY': ['input', 'keyevent', 'KEYCODE_HOME'],
        'WEBVIEW_CONTROL_SCREEN_OFF_READY': ['input', 'keyevent', 'KEYCODE_SLEEP'],
        'WEBVIEW_CONTROL_CLEANUP': ['input', 'keyevent', 'KEYCODE_WAKEUP'],
    }
    policy = subprocess.check_output(['adb', '-s', args.device, 'shell', 'dumpsys', 'window', 'policy'], text=True, timeout=20)
    if re.search(r'^\s+showing=true$', policy, re.MULTILINE) and re.search(r'^\s+secure=true$', policy, re.MULTILINE):
        raise RuntimeError('Unlock the test device before offline WebView acceptance.')
    seen = set()
    with path.open('w') as output:
        process = subprocess.Popen(['flutter', 'test', 'integration_test/android_webview_background_control_test.dart', '-d', args.device, *(['--dart-define=PPPLAYER_WEBVIEW_VIDEO_CONTROL=true'] if args.video else []), *(['--dart-define=PPPLAYER_WEBVIEW_ONLINE_URL='+args.online_url] if args.online_url else []), *(['--dart-define=PPPLAYER_WEBVIEW_MSE_SECOND_URL='+args.mse_second_url] if args.mse_second_url else []), *(['--dart-define=PPPLAYER_WEBVIEW_FOREGROUND_ONLY=true'] if args.foreground_only else [])], cwd=root, stdout=output, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 360
        try:
            while process.poll() is None:
                content = path.read_text(errors='replace')
                for marker, command in actions.items():
                    if marker in content and marker not in seen:
                        seen.add(marker)
                        with path.with_suffix('.actions.jsonl').open('a') as trace:
                            trace.write(json.dumps({'wallMs':int(time.time()*1000),'marker':marker,'command':command})+'\n')
                        subprocess.run(['adb', '-s', args.device, 'shell', *command], check=True, timeout=20)
                        if marker.endswith('SCREEN_OFF_READY'):
                            power = subprocess.check_output(['adb','-s',args.device,'shell','dumpsys','power'],text=True,timeout=20)
                            path.with_suffix('.screen-off.txt').write_text(power)
                        if marker.endswith('CLEANUP'):
                            subprocess.run(['adb', '-s', args.device, 'shell', 'am', 'start', '-n', 'com.ppplayer.app/.MainActivity'], check=False, timeout=20)
                if time.monotonic() > deadline:
                    raise TimeoutError('Offline WebView control timed out; retain log and unlock device if necessary')
                time.sleep(0.1)
            if process.returncode or 'WEBVIEW_CONTROL_PASS' not in path.read_text(errors='replace'):
                raise RuntimeError(f'Offline WebView control failed: exit={process.returncode}; {path}')
            source = 'MSE adaptive' if args.mse_second_url else 'direct online' if args.online_url else 'offline video' if args.video else 'offline audio'
            phases = '90-second foreground-only' if args.foreground_only else 'foreground/Home/screen-off'
            print(f'PASS: {source} WebView {phases} control: {path}')
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main()
