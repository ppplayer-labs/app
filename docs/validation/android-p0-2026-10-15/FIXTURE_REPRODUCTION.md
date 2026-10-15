# Diagnostic controls and reproduction

All commands run from app/. Run Flutter builds/tests sequentially in this
checkout. Unlock the emulator normally before each test; never dismiss its
secure keyguard automatically. Do not interact with it during a measurement.

## Observer

`python3 scripts/capture_android_playback.py --directory <fresh-evidence-directory> --seconds 240`

Requires the host's Python websocket-client package. Uses only the debuggable
app's existing WebView DevTools socket; no native production debugging switch
was added. It observes all accessible JS contexts, actual media buffered ranges,
video frame counters, Chromium Media events, network status/byte/timing events,
audio focus, service ownership and Android codec/resource diagnostics. No response
body, request headers, cookies or media URL query/fragment is exported by CDP.
Native Android dumps may include previous events; correlate wall timestamps/PID.

Use a fresh directory per run. Wrapper JS performance time, iframe performance
time, CDP monotonic time, JS epoch and observer/device epoch are distinct clocks;
records provide corresponding epoch/monotonic samples. Attachment can perturb
runtime timing; diagnostic success is not unobserved acceptance. The first live
observer attempted unavailable media.codec dumps; failures were retained. The
observer now uses available media.player/resource_manager/audio_flinger services
and records an unavailable dump without aborting subsequent diagnostics.

## Live controls

- Extended lifecycle: `python3 scripts/test_chromium_android.py --log <log>`.
- 90-second foreground only: add `--foreground-only`.
- Requires production ownership, real iframe media and system commands.
- Source control setup includes pause/resume, seek and volume checks before the
  measurement. A future no-seek source control may be necessary if that setup
  itself proves causal. Cleanup is distinct from successful acceptance phases.

## Direct remote video

`python3 scripts/test_android_webview_control.py --online-url https://media.w3.org/2010/05/sintel/trailer.mp4 --log <log>`

The public BigBuckBunny bucket endpoint returned HTTP403 XML; Android reported
ERR_BLOCKED_BY_ORB / media error4. That attempt is retained as an invalid remote
source, not background failure. The W3C video endpoint returned HTTP200 video/mp4
and produced the successful direct-online comparison.

## Codec-matched control

Generate only local test assets outside app assets; no product size increase:

```sh
mkdir -p /tmp/ppplayer-android-codec-control
ffmpeg -f lavfi -i testsrc2=size=1280x720:rate=24 -f lavfi -i sine=frequency=440:sample_rate=48000 -t 12 -c:v libvpx-vp9 -deadline realtime -cpu-used 8 -b:v 700k -c:a libopus /tmp/ppplayer-android-codec-control/vp9.webm
ffmpeg -f lavfi -i testsrc2=size=854x480:rate=24 -f lavfi -i sine=frequency=440:sample_rate=48000 -t 12 -c:v libvpx-vp9 -deadline realtime -cpu-used 8 -b:v 500k -c:a libopus /tmp/ppplayer-android-codec-control/vp9-480.webm
python3 -m http.server 8769 --bind 127.0.0.1 --directory /tmp/ppplayer-android-codec-control
adb -s emulator-5554 reverse tcp:8769 tcp:8769
```

Control: `python3 scripts/test_android_webview_control.py --online-url http://127.0.0.1:8769/vp9.webm --log <log>`.
This is socket-delivered fully-buffered VP9, not a public internet-network test.
For adaptive MSE control use the 480 file as --online-url and add
`--mse-second-url http://127.0.0.1:8769/vp9.webm --foreground-only`.
The first interleaved VP9/Opus MSE attempts were rejected before decoding due
to nonmonotonic WebM block timestamps, including after parser-reset retry. For
a valid isolated adaptive video control, remux each fixture with
`ffmpeg -i <fixture> -map 0:v -c copy -an <video-only.webm>` and pass those files
to the MSE options. The final fixture uses a video/vp9 SourceBuffer, resets
its parser between files and advances timestampOffset to the prior buffered end.
It appends two separate VP9 WebM initializations, then
loops the media element; this is a deliberate test source loop, not an application
stall-recovery loop. Confirm Chromium's decoder/config logs actually show the
resolution transition before treating it as an adaptive control.

`--foreground-only` checks nine ten-second foreground progress intervals.
Ordinary controls check 30 seconds foreground, 15 seconds Home, 20 seconds
screen-off. These controls are narrower than the full 90-second YouTube screen-off
acceptance; they do not certify system media pause/resume or physical audio.
