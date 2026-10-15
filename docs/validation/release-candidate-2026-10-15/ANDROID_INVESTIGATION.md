# Android lifecycle investigation — October 15

## Scope and evidence

API 36 arm64 emulator, System WebView 153.0.8010.36. This is not a physical phone
or final production-signed release acceptance. The live integration fixture uses
production hybrid/Chromium/MediaKit ownership with PiP disabled, catalog fixture
resolution and real YouTube media. No URL extraction/native YouTube substitution,
repeated seek/play recovery, forced screen-on or new visibility spoof was added.

- `android-baseline.log`: Home 12.793→21.902 seconds, then screen-off
  22.327→41.698 in 20 wall seconds. Explicit system pause remained paused.
  After play, media advanced briefly then buffered at 46.336 seconds; the test
  subsequently failed Activity restoration behind the secure keyguard. The
  20-second screen-off interval is a narrow pass, not full acceptance.
- `android-extended.log`: failure before screen-off, after Home. Position froze
  at 13.309321 seconds for repeated one-second heartbeats. YouTube state was
  buffering (3), loadedFraction remained 0.0223278, duration 1343.661, document
  visibility remained visible and JavaScript performance timestamps advanced.
  Cleanup returned the Activity, and the same buffered state persisted briefly
  before teardown. This reproduces the historical ~13-second failure without
  screen-off as a necessary trigger. The strengthened 90-second screen-off and
  sustained-resume checks were not reached.
- `android-offline-control.log`: same WebView implementation, autoplay profile
  and Chromium support service, but inline local PCM audio and no YouTube iframe
  or network request. Home (15 seconds) and screen-off (20 seconds) both passed;
  audio remained unpaused, readyState 4, without media errors and with advancing
  media position. This is an emulator control, not physical audible acceptance.
- `android-offline-video-control.log`: looping local MP4 control attempted, but
  the Activity was already stopped before HOME_READY and later resumed during
  setup. It failed the Activity-state assertion. Invalid lifecycle control;
  do not classify it as a decoder or product failure. Added secure-lock preflight
  to prevent this class of locked-start run; the retry is recorded separately.
- `android-offline-video-retry.log`: PASS from a confirmed foreground start.
  Looping local MP4 advanced through Home and screen-off, readyState 4, no media
  error. This narrows the live stall further toward iframe/remote-media behavior;
  it does not prove network or YouTube is the sole cause.

## What this establishes

The Flutter process and wrapper JavaScript remain alive during the live stall.
A foreground service does not itself establish continued iframe media progress.
The existing getWindowVisibility/onWindowVisibilityChanged patch leaves the
wrapper visible but does not resolve the observed media buffering. The passing
local audio control argues against a universal WebView/timer suspension on this
emulator; it does not rule out video-pipeline suspension, cross-frame visibility,
YouTube adaptive media/network behavior, or audio-focus/decoder interactions.
Loaded fraction is an iframe API estimate, not a direct native buffered-range
trace. These observations do **not** establish one proven causal mechanism.

Chromium's upstream AwContents separately manages view/window visibility,
attachment, pause state and native WebContents visibility. Wrapper JavaScript
visibility alone cannot certify those states or an embedded media pipeline:
https://chromium.googlesource.com/chromium/src/+/refs/heads/main/android_webview/java/src/org/chromium/android_webview/AwContents.java

## Next diagnostic step / blocker

The valid local-video control passed. Next compare network-served
video and live YouTube with native media/decoder/network traces. Capture the
cross-origin iframe media state using a debug-only, authorized diagnostic path;
do not enable production remote debugging. Separate source/network availability
from display/lifecycle transitions using repeated foreground controls. Confirm
any correction across prolonged Home, screen lock, system pause/resume and source
switches, then physical ARM64 audible acceptance. No speculative production
architecture switch or workaround is justified by the present evidence.

The acceptance fixture now checks nine ten-second screen-off progress intervals
and ten seconds of sustained system-resume progress. Cleanup has its own marker,
so it cannot inflate successful-phase counts. The runners retain failed exit
status; passing unit tests cannot clear this blocker.

## Focused P0 follow-up

See [October15 focused Android investigation](../android-p0-2026-10-15/REPORT.md)
for WebView154 results, actual cross-origin video buffering/decoder/network
observations, direct-online controls, invalid attempts and the provider's
documented background-player restriction. The historical13.309s failure remains
unresolved; new diagnostic findings do not certify a correction.
