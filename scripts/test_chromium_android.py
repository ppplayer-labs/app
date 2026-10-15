"""Run Android lifecycle acceptance from macOS, Linux, or Windows (Python 3)."""
import argparse
from pathlib import Path
import re
import json
import shutil
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', default='emulator-5554')
    parser.add_argument('--log', default='build/validation/chromium-android-live.log')
    parser.add_argument('--foreground-only', action='store_true', help='90-second live YouTube foreground control')
    parser.add_argument('--foreground-system-controls', action='store_true', help='Add native system pause/resume to foreground-only control')
    args = parser.parse_args()
    if args.foreground_system_controls and not args.foreground_only:
        parser.error('--foreground-system-controls requires --foreground-only')
    root = Path(__file__).resolve().parents[1]
    log = Path(args.log).resolve()
    log.parent.mkdir(parents=True, exist_ok=True)
    flutter = shutil.which('flutter')
    adb = shutil.which('adb')
    if not flutter or not adb:
        parser.error('flutter and adb must be available in PATH')

    def device(*command):
        return subprocess.check_output(
            [adb, '-s', args.device, *command], text=True, timeout=30,
        )

    def restore():
        device('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
        time.sleep(0.5)
        device('shell', 'am', 'start', '-n', 'com.ppplayer.app/.MainActivity')

    policy = device('shell', 'dumpsys', 'window', 'policy')
    if re.search(r'^\s+showing=true$', policy, re.MULTILINE) and re.search(
        r'^\s+secure=true$', policy, re.MULTILINE,
    ):
        raise RuntimeError('Unlock the test device before running Android acceptance.')

    markers = {
        'CHROMIUM_BACKGROUND_READY': ('shell', 'input', 'keyevent', 'KEYCODE_HOME'),
        'CHROMIUM_SCREEN_OFF_READY': ('shell', 'input', 'keyevent', 'KEYCODE_SLEEP'),
        'CHROMIUM_SCREEN_ON_READY': ('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP'),
        'CHROMIUM_MEDIA_PAUSE_READY': ('shell', 'cmd', 'media_session', 'dispatch', 'pause'),
        'CHROMIUM_MEDIA_PLAY_READY': ('shell', 'cmd', 'media_session', 'dispatch', 'play'),
        'CHROMIUM_BACKGROUND_DONE': None,
    }
    if args.foreground_only:
        markers = {'CHROMIUM_FOREGROUND_PASS': None}
        if args.foreground_system_controls:
            markers = {'CHROMIUM_FOREGROUND_PAUSE_READY': ('shell','cmd','media_session','dispatch','pause'), 'CHROMIUM_FOREGROUND_PLAY_READY': ('shell','cmd','media_session','dispatch','play'), **markers}
    seen = set()
    with log.open('w') as output:
        process = subprocess.Popen([
            flutter, 'test', 'integration_test/chromium_live_ui_test.dart',
            '-d', args.device, '--dart-define=PPPLAYER_CHROMIUM=true',
            '--dart-define=PPPLAYER_BACKGROUND_PROBE=true',
            '--dart-define=PPPLAYER_SOURCE_SWITCH_PROBE=true',
            *(['--dart-define=PPPLAYER_FOREGROUND_PROBE=true'] if args.foreground_only else []),
            *(['--dart-define=PPPLAYER_FOREGROUND_SYSTEM_CONTROLS=true'] if args.foreground_system_controls else []),
        ], cwd=root, stdout=output, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 600
        try:
            while True:
                content = log.read_text(errors='replace')
                if 'CHROMIUM_BACKGROUND_CLEANUP' in content and 'cleanup' not in seen:
                    # Cleanup is not a successful acceptance phase.
                    seen.add('cleanup')
                    if not args.foreground_only: restore()
                for marker, command in markers.items():
                    if marker in content and marker not in seen:
                        seen.add(marker)
                        with log.with_suffix('.actions.jsonl').open('a') as trace:
                            trace.write(json.dumps({'wallMs':int(time.time()*1000),'marker':marker,'command':command})+'\n')
                        if command:
                            device(*command)
                        elif not args.foreground_only:
                            restore()
                        if marker == 'CHROMIUM_SCREEN_OFF_READY':
                            time.sleep(0.5)
                            power = device('shell', 'dumpsys', 'power')
                            log.with_suffix('.screen-off.txt').write_text(power)
                            if not any(f'mWakefulness={s}' in power for s in ('Asleep', 'Dozing')):
                                raise RuntimeError('Device did not turn its screen off')
                        print(f'Handled {marker}', flush=True)
                if process.poll() is not None:
                    break
                if time.monotonic() > deadline:
                    raise TimeoutError(f'Android acceptance timed out: {log}')
                time.sleep(0.1)
            if process.returncode or not set(markers).issubset(seen):
                raise RuntimeError(
                    f'Android acceptance failed (exit={process.returncode}, '
                    f'phases={len(set(markers) & seen)}/{len(markers)}): {log}',
                )
            scope = ('90-second foreground-only live YouTube control with system pause/resume' if args.foreground_system_controls else '90-second foreground-only live YouTube control') if args.foreground_only else 'background, screen-off, media controls and source switching'
            print(f'PASS: {scope}: {log}')
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            if 'CHROMIUM_BACKGROUND_READY' in seen and 'CHROMIUM_BACKGROUND_DONE' not in seen:
                try:
                    restore()
                except (subprocess.SubprocessError, OSError) as error:
                    # Flutter may already have uninstalled the integration host.
                    print(f'Activity restoration unavailable: {error}', flush=True)


if __name__ == '__main__':
    main()
