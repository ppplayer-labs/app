# Phase 1 — Reproducible playback candidate

Date: 2026-10-13. Scope: dependency reproducibility, source selection and focused
regressions. No release, commit, version change, workflow change, Android native
lifecycle repair, or memory certification was performed.

**Outcome: dependency portability PASS; focused selection regressions PASS;
static analysis PASS; broader regression gate FAIL. Android can proceed to
focused lifecycle diagnosis and implementation, but this is not a release-ready
or fully green baseline. Native build reproducibility remains NOT TESTED.**

## A. Baseline inventory

Exact original branches, revisions and every modified/untracked entry are in
[baseline.json](baseline.json). No staged changes existed.

| Repository | Branch | HEAD | Initial state |
|---|---|---|---|
| Parent | main | 877ea45 (full revision in baseline.json) | Modified app submodule |
| App | main | 8dc725f9c4e6c456b81c586f06880739bce815f2 | 50 tracked modifications, 7 untracked entries |
| Chromium | fix/android-startup-diagnostics | 0dff55e50b7e4820369b2188a1f2dd2536ab414e | 4 tracked modifications, 19 untracked entries |
| Website | main | cdd601a75d7d4e80003fef9c4d19a2b880374c61 | Clean |

App version remains **3.0.3+11**, MSIX 3.0.3.0. Local SDK metadata:
Flutter 3.44.8, Dart 3.12.2. App floor: Dart >=3.12.0 <4.0.0; nested engine
0.1.0: Dart ^3.7.0. Existing CI requests Flutter 3.47.4; that SDK was not run.

The initial pubspec requested Chromium ^0.5.0 with absolute path overrides for
both packages. Its untracked lockfile reported Chromium 0.5.0 while the local
source manifest reported 0.5.2. Upstream v0.5.2 resolves to Git revision
944e04e71c65f3fc13a5d84ffaf31ba7d213d817 and requires Dart >=3.13.0; the existing
local manifest patch lowers that floor to 3.12. A plain upstream tag switch
would therefore be incompatible with the available SDK and discard patches.

Existing experiments include disabled activity handoffs, null Chromium service
callbacks, Chromium initialization retries/playlist support, macOS target 13.0,
CEF embedding and signing/entitlement edits, input/JavaScript IPC tests and
verification output. Generated localizations, scripts, crash evidence and other
untracked work were preserved. The external Chromium repository was not edited.

## B. Changes made

- `pubspec.yaml`: replace absolute Chromium resolution with repository-relative
  frozen sources; retain the local platform-interface override.
- `pubspec.lock`: regenerate against those sources; Chromium is now 0.5.2 and
  platform interface 0.1.5. No unrelated resolved dependency changed in pub get.
- `third_party/chromium`: preserve 149 upstream-tracked package source files,
  including the existing working-tree patches, licenses and native build scripts.
  Examples, generated caches, binary distributions and unrelated root tools are
  omitted. SOURCE_MANIFEST.json records upstream HEAD and SHA-256 hashes.
- `scripts/verify_chromium_snapshot.py`: verify snapshot content without pub get.
- `.gitignore`: ignore developer-only root pubspec_overrides.yaml.
- `playback_selection.dart`: explicit platform/source capability matrix.
- `playback_providers.dart`: use that platform contract; flag-off Android/desktop
  retains a guarded native facade that explicitly rejects YouTube. iOS keeps
  WebKit and Apple local-file acquisition. Reject malformed online source IDs
  before selection, accepting video IDs and supported playlist prefixes.
- `chromium_playback_engine.dart`: add an optional, default-true youtubeEnabled
  guard; preserve native source delegation; serialize source-opening operations;
  cancel failed-attempt subscriptions; dispose failed browser state before
  reporting initialization failure. No online retry through MediaKit is invented.
- Focused selection and Chromium tests: matrix, native delegation, unavailable
  initialization, unsupported YouTube, pause during initialization/retry,
  replacement serialization and stale-generation behavior.

There is no breaking PlaybackController API change. The additive constructor
option defaults to previous enabled behavior. Existing Chromium default remains
true; changing desktop defaults is deliberately deferred until an acceptable
online experience is established. Native service/handoff code is unchanged.

An initial attempt to reject online IDs in the nested MediaKit engine disrupted
its existing test contract. That change was withdrawn; the nested engine file
is byte-identical to HEAD. Enforcement belongs to the app facade. No failing
tests were removed or skipped.

## C. Dependency reproducibility

**PASS:** main `flutter pub get --offline` changed only Chromium's resolved
version and source identity. Required patched iframe 5.2.2, metadata_god 1.1.0,
flutter_rust_bridge 2.11.1 and native MediaKit provider
flutter_media_kit 1.3.8+ppplayer.egl1 remain intact.

**PASS:** isolated `/private/tmp/ppplayer-phase1-clean` copy, with no app generated
package graph, resolved using:

```
flutter pub get --offline --enforce-lockfile
```

Its package graph contains neither the original Chromium checkout path nor the
original app path. Lockfiles match. See clean-resolution.json and
clean-resolution.log. This uses the existing hosted-package cache and installed
SDK; it is not a fresh network download or native platform build certification.
A fresh-cache/network resolution is **NOT TESTED**.

**PASS:** snapshot hash verification and 87 frozen package/interface unit tests.
The snapshot is approximately 1 MiB, not the 5+ GiB local checkout with CEF and
build caches. Its source identity is upstream HEAD plus the checked-in hashes,
not merely the package's 0.5.2 label. It is a patched snapshot, not unmodified
upstream v0.5.2. The retained lower SDK constraint is exercised by Dart 3.12.2
analysis and unit tests; native compatibility still requires device/build checks.

Native downloads remain external. macOS preparation pins CEF
149.0.4+g2f1bfd8+chromium-149.0.7827.156 with architecture-specific SHA-256 checks.
Windows/Linux native distribution downloads were not executed or certified.

Local-development instructions are in third_party/chromium/README.md. Developers
may use an ignored pubspec_overrides.yaml, then remove it and restore candidate
locked resolution before validation. The lockfile and all snapshot sources must
be included in a future commit; nothing was staged or committed in this phase.

## D. Engine-selection matrix

| Platform | YouTube music/video, Chromium enabled | Chromium disabled | Local audio/video | Network stream/live radio |
|---|---|---|---|---|
| Android | Chromium facade/system WebView inside existing Hybrid engine | Explicit unsupported error, never direct MediaKit YouTube | MediaKit via facade/Hybrid | MediaKit via facade/Hybrid |
| iOS | WebKit iframe; Chromium flag irrelevant | Same WebKit path | MediaKit with LocalFilePlaybackController lease | MediaKit fallback |
| macOS | Experimental CEF facade | Explicit unsupported error | MediaKit via facade | MediaKit via facade |
| Windows | Experimental CEF facade | Explicit unsupported error | MediaKit via facade | MediaKit via facade |
| Linux | Experimental CEF facade | Explicit unsupported error | MediaKit via facade | MediaKit via facade |

This matrix describes source selection, not device playback certification.
Live radio retains the existing nonseekable/live flags. No alternate Android or
desktop YouTube engine was verified safe to select; existing iframe support is
retained on iOS only. Fuchsia is not a Chromium-supported platform.

When Chromium initialization fails, the current generation reports an error
with the requested track/start position. Failed browser/subscription resources
are cleaned up. No native online fallback or automatic queue advance is added.
Retries preserve current pause intent and start position; a pause before
readiness cues instead of loading/autoplaying. Stale events cannot override the
newer generation. Serialized opens prevent overlapping replacement browsers;
this may make a new request wait for the old initialization timeout.

Persistent queue behavior was not rewritten. Command/source-generation logic is
covered by mocks; audible playback, OS suspension and browser runtime crash
recovery remain device/native validation tasks. Package-internal crash reload
behavior is retained and requires explicit paused-crash acceptance in Phase 2.

### Candidate configurations

- **A: Chromium Android.** All source categories above; Android uses system
  WebView, not desktop CEF. Needs a verified foreground media service/ownership
  policy, Home/screen-off/return/PiP/media-button tests and physical acceptance.
  Null callbacks and disabled handoffs remain blockers.
- **B: Existing non-Chromium iOS.** WebKit YouTube plus native local/network
  playback; custom Now Playing/session bridge. Continuous background behavior
  and TestFlight distribution remain unverified. No equivalent Android/desktop
  fallback was established.
- **C: Experimental desktop Chromium.** CEF runtime/resources/helpers and native
  packaging/signing required. Windows profile/cache warnings, Linux packaging,
  macOS Release/8 GB/memory budgets and install acceptance remain separate gates.
  Availability is retained; certification/default promotion is not granted.

## E. Executed validation

| Check | Result | Evidence |
|---|---|---|
| Main offline dependency resolution | PASS | Tool output; consistent updated lockfile |
| Isolated enforced-lockfile resolution | PASS | clean-resolution.log/json |
| Snapshot source hashes | PASS, 149 files | verify_chromium_snapshot.py |
| Final focused selection/provider/Chromium suite | PASS, 34 tests | focused-tests-final.log |
| Frozen Chromium/interface suites | PASS, 87 tests | vendor-tests.log |
| Final app static analysis | PASS, no issues | analysis-final.log |
| Changed app/test formatting, language 3.8 | PASS | format.log |
| Existing nested formatting, language 3.7 | FAIL, 7 files differ | nested-format.log |
| Broader playback/player/nested suite | FAIL, 120 passed / 55 failed | relevant-tests-final.log |
| Isolated unchanged nested-engine suite | FAIL, 34 passed / 45 failed | isolated-nested-tests.log |
| git diff --check | PASS | Executed, exit 0 |
| Native builds/device audio/release signing | NOT TESTED | Outside Phase 1 |
| CI SDK 3.47.4 and fresh network resolution | NOT TESTED | Available SDK/cache only |

The broader suite ran before the final additional initialization-retry test;
that test passed in the final 34-test focused suite. Existing broader failures
were not concealed by its addition. Raw command output is retained as ignored
.log files under this directory, following the repository's existing log policy.

The initial analyzer run failed on vendored example apps' separately resolved
package imports. Those nondependency examples were removed from the snapshot;
production package source/tests remain and pass analysis/package tests.
Sandbox restrictions initially blocked Flutter SDK cache and Dart telemetry
writes; approved tool escalation allowed validation. No dependency upgrades were
performed to obtain success.

Failure inventory is retained in failure-inventory.txt. Nested failures reproduce
with unchanged native source/tests in the isolated copy: iframe recovery,
widget renderer expectations, native session tests and error handling. Hybrid
failures include Home-without-PiP handoff, track changes during handoff, pause
confirmation and containment. Media-sync/system-pause integration expectations
also fail. Missing Mpv.framework diagnostics occur in unit-test hosting;
assertion failures are still reported as FAIL, not dismissed as device evidence.

## F. Remaining Android blockers

1. Disabled ordinary activity handoffs coexist with active PiP-triggered handoffs.
2. Chromium service callbacks are null; foreground service protection is not
   established by source existence alone.
3. Existing lifecycle/player and nested regressions fail; seven nested files
   also fail the current formatting gate. Distinguish obsolete expectations from
   real regressions before changing either tests or behavior.
4. Actual Home, screen-off, return, media controls, process death, PiP and audible
   physical-device playback remain NOT TESTED for this candidate.
5. No alternate online engine exists in the selected contract. Chromium failure
   is explicit, not transparent recovery through MediaKit.
6. The existing all-platform release workflow, Linux build omission and signing
   prerequisites remain later distribution blockers; workflows are untouched.

macOS RSS acceptance remains FAIL, budgets UNSET, physical 8 GB support unverified,
long-term stability unproven and measurement overhead INCONCLUSIVE. No Release
PPPlayer memory certification is claimed.

## G. Phase 2 specification — Android ownership and lifecycle

### 1. Freeze and reproduce the Android lifecycle failure

Use the Phase 1 graph and capture exact device/WebView/build versions. Reproduce
Home, screen-off and return with current code. The comments label disabled
handoffs a “Phase B Experiment”; available source does not establish the author’s
full rationale or prove WebView can continue without handoff. Likewise, null
callbacks show disconnected service ownership, but their rationale is unproven.
Acceptance: logs correlate intended state, generation, engine owner, browser ID,
service mode and Activity/PiP state without guessing from timeline position alone.

### 2. Choose one measured ownership policy

Evaluate retaining the Flutter Chromium player with a service versus handing
online playback to the legacy native WebView. Do not blindly restore the old
calls. A service-only mode must not instantiate a second WebView. If a handoff
is necessary, confirm source silence before destination playback, transfer
position/volume/pause intent, and validate generation at each async boundary.
Local sources already avoid handoff/prewarming and must retain native playback.
Acceptance: exactly one audible owner; explicit pause survives every transition;
failed transfer has deterministic rollback or a truthful stopped/error state.

### 3. Implement service lifetime after policy selection

Review ChromiumMediaService, WebViewPlugin start/stopChromiumService and
CustomWebViewService's ownsWebView/chromiumPlayer modes. Wire callbacks only with
verified ownership and Android foreground-service startup timing. Preserve BUSY
protection against concurrent legacy service ownership. Define stop/dispose,
failed initialization, task removal and process-restart behavior explicitly.
Acceptance: no service left running after stop/dispose, no competing WebViews,
no autoplay on restart, and proper notifications/media buttons during playback.

### 4. Repair handoff failure handling and stale work

Hybrid _initiateHandoff currently converts timeout to an empty status before a
later catch meant for timeout cleanup; make failure observable. Retain track and
play-generation checks, but test owner rollback and overlapping requests. Review
uncaptured child subscriptions and pending prepare/stop operations during teardown.
Acceptance: delayed source/destination events cannot start or stop the new track;
pause timeout cannot authorize a second audible player.

### 5. Verify system controls and PiP ordering

MainActivity emits onStart/onStop and authoritative PiP callbacks; PipHandler
tracks pending requests and watchdog expiry. Test Home-before-PiP-confirmation,
failed/missing/late entry callbacks, dismissal while stopped and expansion while
visible. Route system pause/play through the same user-intent path, not merely
renderer state. Validate MediaSyncService/handler publication separately.
Acceptance: stable paused screen-off state, correct media-control metadata,
no duplicate completion/queue advance and safe video-to-audio navigation.

### 6. Restore a green regression gate and perform device acceptance

Triage failure-inventory.txt against current behavior. Fix defects; update an
obsolete test only with an explicit reviewed contract and meaningful coverage.
Run relevant app/nested tests and formatting. Then use the existing Android host
helper and physical ARM64 device for background/PiP/control/source-switch checks.
Acceptance: all intended phases present in logs, audible output confirmed,
no overlapping sessions, stable explicit pause, correct position restore and
clean stop. Unit tests alone cannot pass this gate.

## H. Prerelease assessment

Phase 1 implementation and its requested validations are complete, with failures
reported. **PASS to proceed with focused Android stabilization work; FAIL for a
release-ready baseline.** The dependency graph is portable under the verified
cached environment, source selection is explicit, and supported facade paths
have current passing mocks. Build success and real playback are NOT TESTED.

Do not publish, promote macOS Chromium, promise fallback, or expand features.
Phase 2 has not started.
