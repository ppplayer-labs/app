# P0 Android live YouTube investigation — October 15, 2026

Candidate **4.0.0+12** remains **NOT READY**. Android P0 is **not resolved**.
This is a diagnostic continuation; other release gates remain unchanged.

## Evidence and clock/version caveats

Earlier failing API36 emulator runs used WebView153.0.8010.36. The current
emulator reports WebView154.0.8037.106 without an app playback correction.
No provider upgrade/downgrade was performed by this investigation. Results must
not be called application before/after-fix evidence across that change.

Historical 153 run: Home stalled at13.309321s, iframe API state3 buffering,
wrapper JS alive, loadedFraction unchanged. Offline audio and small H.264/AAC
MP4 passed Home/screen-off. These logs remain in the prior candidate directory.

New CDP observations use the debuggable app's existing local socket, sample
cross-origin iframe media state and Chromium Media/Network domains, and pair
observer epoch/JS epoch/performance clocks. Signed URL query strings/fragments,
headers and response bodies are omitted. Debugger attachment and repeated dumps
can perturb runtime; observed tests do not replace unobserved acceptance.
`ARCHITECTURE.md` covers the seven requested subsystems.

## Current controlled matrix

| Source / run | Foreground | Home | Screen-off | System pause/resume | Return foreground |
| --- | --- | --- | --- | --- | --- |
| Historical live YouTube / WebView153 | Brief control pass | FAIL13.309s | Historical FAIL; some short passes | Pause narrow pass; sustained resume not qualified | Not qualified |
| New live YouTube / WebView154 observed | Brief controls PASS | 10s progress PASS | INVALID: interactive became true; one interval progressed23.338→31.773 | NOT REACHED | Cleanup could not restore secure Activity; not a product pass |
| Direct remote BigBuckBunny sample | INVALID SOURCE: HTTP403 XML / ORB / error4 | NOT REACHED | NOT REACHED | NOT TESTED | NOT TESTED |
| Direct remote W3C Sintel H.264/AAC | PASS30s | PASS15s | PASS20s | NOT TESTED | Secure lock not dismissed; NOT TESTED |
| Offline PCM audio (prior control) | Brief PASS | PASS15s | PASS20s | NOT TESTED | NOT TESTED |
| Inline H.264/AAC640x480 (prior valid retry) | Brief PASS | PASS15s | PASS20s | NOT TESTED | NOT TESTED |
| Local socket VP9/Opus1280x720 | PASS30s | PASS15s | INVALID: interactive=true, despite advancing media | NOT TESTED | NOT TESTED |
| Live YouTube foreground90s | Progress PASS: all9 intervals10.345→100.624; full test FAIL during teardown | Not exercised by design | Not exercised by design | UI setup only; not system acceptance | Foreground-only |
| Local MSE adaptive VP9/Opus480→720 | Two attempts INVALID FIXTURE: interleaved WebM append parser rejected nonmonotonic timestamps; isolated video-only retry pending | Not exercised by design | Not exercised by design | NOT TESTED | Foreground-only |

Failed and invalid cases remain failures/invalid cases even if media advanced.
Screen-off requires actual noninteractive state; a progress sample alone is not
screen-off evidence. No automatic keyguard dismissal was performed.

## Confirmed observations versus cause

The first new live trace shows **video DECODER_UNDERFLOW with media buffered
ahead**, not merely an unchanged wrapper loadedFraction. Iframe sample35.43991s
has buffered ranges[0,78.733] and[670.3,690.2], readyState2, paused=false, no media
error. Network requests continued delivering data. Native decoder is
MediaCodecVideoDecoder/c2.goldfish.vp9.decoder; audio uses OpusAudioDecoder.
Chromium reported adaptive854x480→1280x720 and elided EOS/flush for the transition.

Audio focus snapshot during underflow shows the app Chromium delegate GAIN,
loss:none. CustomWebViewService remains foreground/type mediaPlayback and owns
no additional WebView. Native Home logs show WebView attached to
FlutterMutatorView with effective window visibilityVISIBLE. Iframe samples also
report visible. Flutter reports buffering rather than manufacturing progress.

These observations identify the **affected video-decoding pipeline in one
current diagnostic run**, but **do not establish the root cause of the older
13.309s freeze**. Decoder underflow can be transient during adaptive playback;
its presence is not proof of a MediaCodec bug or intentional YouTube enforcement.
The current live run's acceptance failure was an interactive-state assertion,
not the old permanent13.309s stall. Its intermittent underflows and partial
progress must not be misreported as the identical historical failure. The
foreground-only trace also contains decoder underflow events while sustaining
all90s progress, confirming that underflow events alone are not a failure oracle.

The passing remote MP4 argues against general background network prohibition.
The fixed VP9 control argues against universally broken VP9 decoding; it showed
advancing decoded frames, with many frames dropped when backgrounded. A
codec/resolution/MSE transition, source-specific YouTube behavior, compositor or
emulator-specific adaptive-decoder interaction remain hypotheses. The adaptive
control is required before narrowing further. The live foreground control
maintained90s progress with the same pause/seek/volume setup, but a teardown
asynchronous-error/stack-demangling failure prevents an overall test pass.
The fixture now explicitly stops the controller before provider disposal; a
clean retry is required. No production disposal behavior was changed.

## Release-scope restriction, independent of technical causality

Official YouTube developer policies III.I.9 prohibit features playing content
through a player not displayed on the user's viewed page/tab/screen. The official
guide explicitly identifies closed/minimized API-client background playback as
disallowed. Read October15:

- https://developers.google.com/youtube/terms/developer-policies
- https://developers.google.com/youtube/terms/developer-policies-guide

This source restriction is not evidence that YouTube deliberately caused this
particular buffering trace. It does mean hidden YouTube playback is not a
supportable release promise through the embedded API, regardless of an emulator
pass. No attempt was made to bypass provider restrictions or silently extract
an audio-only source.

**Proposed scope decision:** qualify foreground, visibly presented YouTube
video; explicitly pause on Home/screen-off, preserve the item/position, and
require explicit user resume on return. Retain independently qualified local
and direct-media background playback. Visible PiP requires separate eligibility,
provider-policy and physical-device validation and is not automatically included.

That proposal changes expected product behavior and acceptance scope. It is
**not applied or approved** by this report. A reliable implementation would use
source-aware playback intent, stop recovery from restarting the hidden iframe,
remove the autoplay visibility deception for that path, and test pause/no-auto-
resume against actual lifecycle events. It would not convert a failed background
video acceptance test into a pass; the excluded behavior must be documented.

If continuous hidden YouTube video remains mandatory, keep the release blocked
until a supported provider integration and independently verified acceptance are
established. A replay/seek loop, codec/UA spoof or audio-only fallback is not the
correction proposed here.

## Exact changes and validation scope

No production playback engine, decoder, service ownership or platform visibility
behavior was changed in this continuation. Test/diagnostic changes:

- `scripts/capture_android_playback.py`: read-only native/CDP observations and
  safe URL export, decoder/video-frame/buffering/network/focus/service sampling.
- `integration_test/android_webview_background_control_test.dart`: direct remote
  video, configurable local-origin fixture, MSE two-resolution control,
  foreground-only90s comparison, epoch/buffered-range samples.
- `scripts/test_android_webview_control.py`: diagnostic source/MSE options,
  read-only secure-lock preflight and timestamped lifecycle-action traces.
- `integration_test/chromium_live_ui_test.dart` and runner:90s foreground-only
  control using existing live setup; corrected phase logging after keyguard
  removal, epoch action traces; original extended acceptance retained.
- `scripts/test_android_playback_diagnostics.py`: URL/query/inline-payload export
  regressions. These are tooling regressions, not evidence of a product fix.

See `FIXTURE_REPRODUCTION.md` for commands, source-generation parameters,
observer limits and invalid-source handling. No final physical ARM64 device is
attached; the available device is the API36 emulator only.

## Minimal scope correction to prepare for approval

This is a concrete proposed behavior change, not a claim of technical stall repair:

1. On Android Home or screen-off, when the active source is the YouTube iframe,
   set authoritative playback intent to paused and send one acknowledged iframe
   pause. Keep queue/item/position. Stop the support-service lease once paused.
2. Invalidate recovery/autoplay permission for that lifecycle pause. Returning to
   the foreground must remain paused until explicit UI/system play while visible.
   System play while hidden must not reopen hidden YouTube playback.
3. Use real visibility for YouTube and remove the force-visible/transparent parked
   player behavior from that source path. Local/direct MediaKit remains independently
   eligible for its existing background behavior.
4. Do not implicitly include PiP; determine visible-player eligibility and validate
   it separately. No extraction, codec/UA spoof, repeated seeking or replay.
5. Add source-aware lifecycle/intent regressions and actual emulator Release
   acceptance: Home/lock paused drift<0.5s over90s, no hidden resume, visible explicit
   resume and video-frame progression, then physical ARM64/device interruptions.

Choosing this scope would retire continuous hidden YouTube progress as a product
requirement, not mark the existing failing protocol green. Keep the release blocked
until that scope is approved, implemented, documented and qualified. No production
scope change has been made in this continuation.

## Remaining physical acceptance

A physical ARM64 phone must qualify the selected/approved behavior in actual
Release artifacts: visible moving YouTube video and audible output, foreground
long-run/adaptive quality/seek, Home/screen lock, system notification/Bluetooth
pause/resume, long explicit pause, focus interruption, OEM battery restrictions,
return-to-foreground and source transitions, with no unintended autoplay. If
hidden playback is excluded, test sustained paused intent for90s and explicit
resume instead of claiming continuous-video progress. Current90s continuous
screen-off/system-resume acceptance remains unpassed and cannot clear P0.
