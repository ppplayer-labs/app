# Phase 2 — Android playback lifecycle and Chromium stabilization

Assessment date: October 13, 2026. App version remains **3.0.3+11**.

**Engineering result: PASS for the implemented ownership contract, automated
regressions and Android release-mode build smoke. Physical Android acceptance:
BLOCKED. Distribution signing and release eligibility: BLOCKED.**

Chromium remains the intended default YouTube engine on Android, macOS, Windows
and Linux. iOS retains WebKit iframe playback. MediaKit/libmpv retains local
media, network streams and radio on every platform. Product direction is distinct
from engineering certification; unvalidated platforms cannot be released.

No commit, push, tag, publication, application-version change, release-workflow
change or macOS memory-budget change occurred. Existing work and Phase 1 evidence
were preserved. Phase 3 has not started.

## A. Root-cause analysis

### Android ownership conflict

The Phase 1 tree disabled ordinary Activity foreground/background handoffs but
still allowed PiP dismissal/failure callbacks to activate the native background
WebView. HybridPlaybackEngine also prewarmed that inactive engine after online
playback. Consequently, “disabled handoff” did not mean one browser: the unused
native service could still start and create a second WebView.

Chromium service callbacks in playback_providers.dart were null. The native
start/stop hooks existed, but production selection did not acquire their service
lease. Experimental comments identify a Phase B experiment; they do not prove
why the original author disabled those calls or that screen-off playback passed.

Hybrid _initiateHandoff swallowed destination timeout into an empty status before
its intended error handler. Source pause, destination initialization and late
acknowledgment cleanup were therefore not reliably tied to the current transfer.
Child stream subscriptions were not retained for explicit cancellation.

The native media PlaybackView independently paused Android media when backgrounded,
contradicting ownership by the engine/media session. Foreground return did not
automatically repair that pause. The Android surface now leaves playback intent
with its controller, retaining the existing iOS behavior.

### Regression fixtures after the engine split

51 original failures came from broken test wiring/contracts: YouTube tests
instantiated MediaKitPlaybackEngine, fake controllers were disconnected, invalid
video IDs were used, or the view mock omitted its Widget renderer. The extracted
IframeYoutubePlaybackEngine declared a controller factory but did not use it.
Restoring that existing injection seam changes no default iOS player construction.
Assertions were retained; no test was deleted, skipped or weakened.

### Service and recovery races

Native service startup is asynchronous. Reserving ownership only after launching
a service leaves a window for competing modes. Dart service start/stop requests
also need ordering so a late successful start cannot escape an earlier stop.

The package and its lower WebView controller both independently recovered from a
browser crash. Android now opts out of both automatic recreation paths: the app
coordinates cleanup and recovery generations. Desktop defaults are unchanged.

NativeServicePlaybackEngine allocated commands after awaiting service creation,
allowing a stopped pending request to dispatch later. It also suppressed startup
failure and accepted stale state callbacks. Those paths are corrected.

## B. Chosen playback policy

**Strategy A: persistent Chromium owner for the Android default.**

The provider explicitly selects persistentForeground. Here “foreground” names
the Flutter-owned engine, not a claim that the Activity is visible. Home,
screen-off, notification shade and PiP events do not transfer ownership or
prewarm another WebView. NativeServicePlaybackEngine remains dormant in this
configuration. Local/network sources continue through the same facade to MediaKit.

Source evidence supports one safe ownership authority: the package retains the
Android WebView, its platform-view handling avoids creating a replacement merely
for navigation, and engine state is independent of Activity visibility. It does
**not** prove Android allows uninterrupted audible playback with a stopped
Activity. That remains a mandatory physical-device gate. No visibility spoofing,
VirtualDisplay reparenting or background-execution exemption was added.

The legacy nativeHandoff policy is retained explicitly for its existing tests and
service-backed callers, with repaired timeout behavior. It is not selected by the
Android production provider and is not a second simultaneous background policy.
It has not received physical-device certification.

| Transition | Default owner and action |
|---|---|
| Foreground YouTube | One package-owned System WebView; service lease starts before playback initialization |
| Home / screen off | Same owner; no handoff or second browser; OS behavior requires device validation |
| Notification shade | Intent unchanged; no new player |
| Foreground return | Same owner; no automatic resume of a user-paused session |
| PiP pending / confirmed | Same video/browser owner |
| PiP rejected / timed out / dismissed | Same owner; no fallback WebView created |
| Background track switch | Serialized old-browser disposal and new source opening |
| Explicit pause | Pause intent wins late playing events; Chromium support lease released after pause command |
| Explicit resume | Service acquired before play; failure propagates without autoplay |
| Stop / provider disposal | Browser teardown and service release; subscriptions invalidated |
| Task removal | Android handler clears intent and stops the actual controller, avoiding an Activity-backed orphan |
| Activity recreation | No intentional second player; actual reattachment behavior NOT TESTED |
| Process restart | START_NOT_STICKY support service; persisted track is prepared without autoplay/service lease |

AudioService remains the single media-control/MediaSession authority. The custom
foreground service is a support lease and creates **no WebView in Chromium mode**.
There are two service components, not two playback instances: AudioService publishes
controls/metadata, while CustomWebViewService supplies the Chromium support lease.
Its support notification is separate from AudioService's media notification;
actual notification presentation and command routing require device acceptance.

## C. Source changes

| File / symbols | Behavioral change |
|---|---|
| playback_providers.dart | Explicit persistent Android policy, lazy dormant native service, wired Chromium service callbacks, host-controlled Android crash recovery |
| hybrid_playback_engine.dart / PlaybackOwnershipPolicy | Suppress every handoff/prewarm path for persistent ownership; keep legacy behavior explicit |
| HybridPlaybackEngine._initiateHandoff | Confirm source pause; bound destination initialization/acknowledgment; observe errors; stop failed destination; prevent automatic source replay |
| Hybrid play/prepare/dispose/status handling | Generation checks, awaited inactive stop where applicable, paused-intent containment, subscription cancellation |
| chromium_media_service.dart | Serialized, idempotent start/stop lease; failed start does not acquire ownership |
| ChromiumPlaybackEngine | No service for paused restoration; service before resume, release on pause/terminal completion; crash cleanup invalidates stale generations before retry |
| Vendored Chromium controllers | Add default-true recovery options; Android disables automatic browser/page recreation and reports crash to the app; other defaults retained |
| WebViewPlugin.kt | Reserve service mode before startup, reject competing modes, wait up to five seconds for Chromium service readiness, stop only owned mode, propagate startup errors |
| CustomWebViewService.kt | Nonsticky/null-intent handling, prevent mode switching to a competing browser, support notification; cue commands use monotonically claimed IDs |
| NativeServicePlaybackEngine | Reject stale states, preserve pause intent, honor paused play, propagate startup failure, invalidate pending startup commands on stop |
| PpPlayerAudioHandler.stop/onTaskRemoved | Android-only stop of actual controller after authoritative pause; no restart permission granted |
| PlaybackView | Android native media surface no longer owns background pause/resume |
| IframeYoutubePlaybackEngine | Honor existing injected controller factory; production default factory unchanged |
| Tests | Reconnect extracted-engine fixtures and add ownership/service/crash/task-removal/background regressions |

Seven nested files received formatting-only consistency repairs in addition to
specific test wiring changes. Native MediaKit behavior and unrelated platform
engine selection were not rewritten. The frozen Chromium manifest records the
new source/test patch hashes; upstream checkout is unchanged.

## D. Regression inventory

[regression-inventory.json](regression-inventory.json) accounts for every original
failure individually. Phase 1 logs and baseline worktree patches remain intact.

| Original file | Failures | Root cause / correction | Final status |
|---|---:|---|---|
| media_sync_pause_test.dart | 5 | Disconnected YouTube fixture and wrong lifecycle flag | PASS |
| ios_media_commands_test.dart | 1 | Wrong engine/factory; invalid source ID | PASS |
| hybrid_playback_engine_test.dart | 4 | Disabled activity handoffs against active legacy contract; explicit policies and safe handoff logic | PASS |
| iframe_view_test.dart | 1 | Missing Widget renderer in mock | PASS |
| iframe_youtube_playback_engine_test.dart | 41 | Wrong extracted engine and unused injection factory; native session group retains native fake adapters | PASS |
| engine_error_test.dart | 3 | Wrong engine, disconnected fake, invalid IDs | PASS |
| **Total** | **55** | All original assertions restored | **PASS** |

Classification:

- Genuine production problems: inconsistent ownership, prewarm/service races,
  swallowed handoff timeout, stale pending service commands and dual crash recovery.
- Obsolete fixture contracts: 51 original failures; repair mocks/engine injection,
  not expected safety behavior.
- Environment/native-host diagnostics: missing Mpv.framework messages still occur
  when unit-hosting native constructors. They were not used to dismiss assertions;
  meaningful tests pass using existing fake adapters/controllers.
- Async/timing defects: covered by service pending-start, transfer timeout,
  late-playing containment, queued initialization and crash-generation tests.
- Unrelated-platform coverage: iOS tests are repaired through fixtures/injection;
  no change to iOS native sessions, background policy or engine selection.
- Remaining original failures: **0**. Remaining formatting failures: **0**.

## E. Automated results

| Executed check | Result | Evidence |
|---|---|---|
| Full app + nested engine + both Chromium packages | PASS, **576 tests** | full-tests-final.log |
| Focused native-crash coordination pass | PASS, 29 tests at its checkpoint | crash-tests.log |
| Mobile native-surface + pending-service tests | PASS, 6 tests | mobile-background-tests.log |
| Static analysis | PASS, no issues | analysis-final.log |
| Scoped app/test format check, language 3.8 | PASS | format-final.log |
| All nested lib/test formatting, language 3.7 | PASS, 19 files unchanged | nested-format-final.log |
| Chromium snapshot hashes | PASS, 149 files | scripts/verify_chromium_snapshot.py |
| Isolated enforced-lockfile resolution | PASS; original package paths absent; lock unchanged | clean-resolution.log, clean-resolution-summary.json |
| git diff --check | PASS | Executed exit 0 |

Main command:

```
flutter test --no-pub --reporter expanded test \
  lib/core/playback/packages/pp_playback_engine/test \
  third_party/chromium/packages/flutter_chromium_webview/test \
  third_party/chromium/packages/flutter_chromium_webview_platform_interface/test
```

Analysis: `flutter analyze --no-pub`. Formatting matches the existing app/nested
language versions. The nested formatter emits package-include resolution warnings
for its independently unresolved configuration, but exits successfully with no
format changes. App static analysis reports no issues.

The full suite ran against final behavioral source; the last subsequent change
was formatting of the additional Android test variant only. No failing tests were
suppressed. Logs remain local ignored evidence files, following repository policy.

## F. Device acceptance

**BLOCKED: no attached Android device.** ADB 37.0.1-15733141 reported an empty
`adb devices -l` inventory. USB/server access was checked with approved escalation.
No emulator was substituted. Device model, API, WebView version, actual MediaSession
state, PiP state and audible output therefore have no measured results.

| Required runtime scenario | Status |
|---|---|
| Audible YouTube foreground, Home, screen off, return | BLOCKED |
| Notification and Bluetooth/headset commands | BLOCKED |
| PiP entry, rejection, dismissal, return and late callbacks | BLOCKED |
| Background queue/track/source switches | BLOCKED |
| Long explicit pause and browser crash/recovery | BLOCKED |
| Local audio/network stream background acceptance | BLOCKED |
| Task removal, Activity recreation, process restart | BLOCKED |

Unit tests validate ownership and intent transitions; they do not establish
speaker output, battery behavior or OEM/WebView suspension behavior. See
[device-availability.txt](device-availability.txt).

## G. Build readiness

**PASS: clean Android release-mode smoke build**, using Flutter 3.44.8 / Dart
3.12.2 in `/private/tmp/ppplayer-phase2-release-smoke`. That checkout had no app
build output, no original absolute Chromium dependency paths and no release keys.
It used installed SDK/hosted caches, then native dependency downloads/builds.

```
flutter pub get --offline --enforce-lockfile
flutter build apk --release --target-platform android-arm64,android-x64
```

The first `--no-pub` attempt failed because pub-get's generated registrant included
integration_test while the release classpath excluded dev plugins. The SDK's
release plugin injection explicitly filters dev dependencies. Running the normal
build command regenerated release registration, without removing integration_test
or modifying dependency versions/workflows. That build passed; an incremental
build with the final production sources also passed. Failed output is preserved
in android-release-build.log; successful outputs are in the retry/final logs.

Final APK: approximately 94.6 MB; exact bytes, SHA-256 and location are in
[artifact-summary.json](artifact-summary.json).

Artifact checks:

- Version 3.0.3, versionCode 11; minimum API 24, target API 36, compile API 37.
- Exactly arm64-v8a and x86_64 native ABIs.
- Both libmpv/helper pairs match the resolved published native package's checksums.
- Required foreground-service/mediaPlayback and notification permissions present.
- AudioService and CustomWebViewService both declare mediaPlayback type; custom
  service is not exported; PiP Activity declaration is retained.
- APK signature verification PASS, certificate **Android Debug**.
- ZIP alignment check with 16 KiB native page alignment PASS. This does not prove
  ELF compatibility or actual playback on a physical 16 KiB-page device.
- Chromium uses System WebView on Android; no desktop CEF distribution is required.

**This APK is a smoke artifact, not a distributable release.** Debug signing is
explicitly confirmed; release-key signing, AAB generation and Play/device install
acceptance remain NOT TESTED/BLOCKED. No artifact was uploaded or installed.

SDK/Kotlin migration and deprecated Java/API warnings remain P1 follow-up. CI's
Flutter 3.47.4 was not run here. Build success does not certify background playback.

## H. Remaining P0/P1 issues

### P0 — must pass before an Android prerelease

1. Physical foreground/background/screen-off/PiP/notification/audible acceptance.
   A foreground service is not proof that Android will keep the Activity-backed
   WebView playing. If a supported device suspends it, retain Chromium and stabilize
   its native ownership/hosting; do not fall back to direct MediaKit YouTube.
2. Verify service startup restrictions, notification presentation, ownership,
   cleanup and user media-button exemptions on supported Android APIs/OEMs.
3. Validate Activity recreation, task removal and process restart without autoplay.
4. Produce and verify genuinely release-signed selected-platform artifacts.
5. Verify the selected platform's CI SDK and distribution path; the existing
   all-platform publisher/Linux packaging problem remains outside this phase.

### P1 — reliability/acceptance follow-up

- Long repeated browser/source/play-stop cycles and paused-crash recovery on real
  System WebView; initialization retries and mock crash tests are not resource soak.
- Audio interruptions/headphone disconnect/Bluetooth and 16 KiB device coverage.
- Review the separate support/media notification presentation; only AudioService
  must remain the control authority.
- SDK built-in Kotlin migration warnings and richer device diagnostics as needed.
- Native shared-player resource lifetime and dormant legacy-service runtime
  behavior are not certified by this phase.

No unresolved original automated regression is hidden. Remaining release blockers
are runtime/distribution gates, not grounds to replace the chosen engines.

macOS conclusions remain unchanged: tested 1080p functional workload PASS; sampled
whole-app peak about 707 MiB in a Debug host, deduplicated charged footprint rather
than RSS; physical 8 GB support unverified; long-term stability unproven;
measurement overhead INCONCLUSIVE; legacy RSS acceptance FAIL; numeric budgets
UNSET; no Release-mode PPPlayer memory certification.

## I. Smallest Phase 3 proposal and platform acceptance

### Android first

1. Attach a physical ARM64 device and record model/API/WebView/build mode plus
   candidate source/lock hashes. Use existing Android host/integration probes;
   add readiness/state capture only where evidence is missing.
2. Run audible YouTube Home/screen-off/return, notification pause/play, long pause,
   PiP races, queue advance, source replacement, browser recovery and teardown.
   Correlate owner/generation with service, MediaSession and PiP state. Include
   local audio and network streams; keep logs sanitized.
3. Exercise recreation/restart/task removal and check for surviving browser/service
   ownership. No autoplay after process restore. Test headset/Bluetooth where
   hardware exists; mark unavailable hardware honestly.
4. Validate real signing and install the final selected-platform APK/AAB, repeat
   short smoke acceptance, align metadata/download links and prepare publication
   only after all selected Android gates pass.

### Windows — Chromium/CEF remains default

Gate on clean build/MSIX install, writable persistent profile/cache, actual live
YouTube controls/seek/queue/source switches, native local/network playback, browser
process crash/recovery, disposal/process exit and OS media controls. Previous
profile/cache warnings require runtime confirmation. Current status: NOT TESTED
in Phase 2; release BLOCKED pending these gates.

### macOS — Chromium/CEF remains default

Gate on current target/architecture claims, CEF helper embedding/signing,
hardened-runtime/notarization/fresh install, live playback/lifecycle/crash cleanup,
and Release-mode PPPlayer whole-application memory evidence. Repeat the frozen
preflight on eligible physical 8 GB hardware, resolve overhead/integrity uncertainty,
and obtain independently justified approved budgets. Do not redefine RSS FAIL.
Current status: NOT TESTED in Phase 2; release BLOCKED.

### Linux — Chromium/CEF remains default

Gate on repaired clean build/package steps, runtime resources/sandbox/library
availability, install/run on intended distributions/display backends, live
YouTube and local/network controls, browser crash/disposal/process-exit testing,
and consistent AppImage/DEB/tarball artifacts/checksums. Current status: NOT TESTED
in Phase 2; release BLOCKED. No Linux packaging change was made here.

These are acceptance criteria, not completed cross-platform work. Platforms can
qualify independently; an unvalidated platform cannot ride another platform's
success. No publication or Phase 3 implementation was started.

## Reference constraints

Android mediaPlayback service types and permissions:
https://developer.android.com/develop/background-work/services/fgs/service-types

Foreground-service background-start restrictions:
https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start

The implementation uses normal service APIs and propagates startup failure; it
adds no boot launch or background-execution bypass. Platform-device validation
must still establish actual supported behavior.
