# Pre-release validation — October 14, 2026

**Verdict: NOT READY. Android screen-off playback still stalls in live runtime acceptance; the earlier visibility patch is insufficient.**

Scope: current working tree, including existing uncommitted candidate changes.
No version bump, commit, publication, signing submission or store upload was
performed. `pubspec.yaml` remains 3.0.3+11 and MSIX remains 3.0.3.0; upcoming
notes are in the Unreleased changelog section. Select the release version only
when the candidate is qualified. Historical changelog entries are not evidence
that this working tree was distributed.

## Automated checks

| Check | Result | Evidence |
| --- | --- | --- |
| Android regular release-mode APK (ARM64 + x64) | PASS, 94.9 MB, debug-signed | android-release-build.log, android-apk-signature.txt |
| Android native library integrity | PASS, both ABIs | android-native-binaries.log |
| Final Flutter analysis | PASS, no issues | flutter-analyze-final.log |
| Final app, engine and two Chromium package suites | PASS, 604 tests | flutter-test-final.log |
| Android live foreground controls and three source switches | PASS, 1 integration test | android-foreground.log |
| Packaging/configuration guards | PASS, 4 tests | packaging-tests.log |
| Chromium snapshot identity | PASS, 149 source hashes | scripts/verify_chromium_snapshot.py |
| CI formatting (app and nested engine) | PASS, no changes required after corrections | ci-format-check.log, engine-format-check.log |
| Localization consistency | PASS, 38 catalogs, 354 messages, required placeholders | localization-check.log |

Translation checks establish message/placeholder coverage, not linguistic review.
The current local SDK is Flutter 3.44.8 / Dart 3.12.2. CI's requested Flutter
3.47.4 has not been executed by this local pass. The app/engine/Chromium suites
run against the resolved candidate graph, including vendored source patches.

## Fixes and findings

- Android native WebView now preserves visible-window state for autoplay media
  when the Activity minimizes. Normal browsing visibility remains unchanged.
  The source manifest records the prior hash and reviewed candidate patch.
- Frozen source verification initially failed because the new Android patch's
  hash had not been recorded. The manifest was updated with patch provenance;
  the integrity check now passes.
- Linux packaging had disabled both Flutter dependency resolution and release
  compilation. Restored both steps. A regression uses a failing stub Flutter
  build and an existing stale bundle, asserting that packaging cannot continue.
  This test does not certify an actual Linux artifact.
- Two tracked network-output tests failed the CI formatting scope. Applied the
  established Dart 3.8 formatter to those files only.
- Live Android fixture used PiP-enabled default settings and an obsolete engine
  nesting. Home entered PiP, so the first test failed to observe Activity stop.
  The corrected fixture explicitly disables PiP for minimize acceptance and
  uses the production persistent hybrid / Chromium / MediaKit topology. Explicit
  pause acceptance now waits ten seconds. Initial failure evidence is retained
  in android-live-initial.log and android-driver-initial.log.
- Added a Python lifecycle driver equivalent to the existing PowerShell runner.
  Cleanup does not mask the test failure if Flutter uninstalls the host first.
- The release build found a missing Cupertino icon font. Added the cached
  cupertino_icons 1.0.9 dependency and updated the lockfile; the following build
  tree-shook and included CupertinoIcons.ttf without the missing-font warning.
- The first release build used --no-pub after integration testing, retaining an
  integration-only Java plugin registry entry while Gradle excluded dev plugins.
  Pub get alone regenerates debug tooling. Flutter SDK source confirms that a
  normal release build (without --no-pub) regenerates the release-specific plugin
  registry; retry uses that supported path. This is a validation-command issue,
  not a production source workaround. Setup docs and the Python integration
  runner now retain platform-tooling regeneration.
- Release CI now includes both vendored Chromium suites, source verification
  and Python packaging guards.

## Android runtime acceptance

Environment: Medium_Phone_API_36.1, sdk_gphone64_arm64, Android API 36,
arm64-v8a, System WebView 153.0.8010.36. This is an emulator, not a physical
ARM64 phone. The integration host installs under the normal app ID. Catalog
resolution uses a fixture; actual YouTube media and the real player screen are
used for controls and lifecycle. This is separate from a production-app smoke.

- Debug Android integration host compilation and installation: PASS.
- Initial foreground live YouTube playback, pause/resume, seek and volume: PASS
  before the background phase, based on test progression.
- Home with PiP disabled: Activity stop observed; initial measured progress was
  11.8678 → 13.3285 seconds, but sustained playback then stalled.
- Screen-off: FAIL. Heartbeats stayed at 13.3285 seconds in buffering state for
  approximately twenty seconds while the document reported visible. The same
  symptom reproduced in the preceding run at 13.3534 seconds. Adding a consistent
  getWindowVisibility provider query did not resolve this. Do not advertise the
  minimize issue as fully fixed or approve release based on the short Home check.
- Cleanup failed to restore the Activity behind the emulator's secure keyguard;
  the original test finally block masked the assertion. The fixture now records
  the original failure and preserves it during cleanup. The driver now detects
  a locked secure device before starting. No lock credentials were accessed or
  security settings changed.
- Background system pause/play: NOT REACHED because the background gate failed.
- Separate foreground controls and source switches: PASS after the user unlocked
  the emulator. The live player test completed play/pause/resume, seek, volume
  and all three local-video → YouTube cycles, with old browser disposal and
  support-service ownership assertions. Evidence: android-foreground.log,
  PPPLAYER_LIVE_UI_PASS and three CHROMIUM_SOURCE_SWITCH_PASS markers.
- The first foreground attempt was stopped behind the secure lock screen;
  android-foreground-locked.log retains that interruption without calling it a
  product regression. The successful retry is recorded separately.
- Latest background evidence: android-live.log / android-driver.log. Previous
  failed screen-off evidence: android-live-screen-off-failure.log and its driver
  log. Initial PiP-fixture failure is retained separately.

The user unlocked the emulator after the secure-keyguard interruption. The
foreground retry passed; build and foreground success do not clear the
background runtime blocker. The Home regression now waits ten seconds and
requires more than five seconds of progress so a short decoder buffer cannot
produce a false pass.
Local Android signing configuration is absent, so Gradle uses the debug signing
fallback even for this release-mode build. apksigner confirms Android Debug as
the signer. It is not a distribution-signed APK. aapt confirms com.ppplayer.app,
version 3.0.3, build 11, and only arm64-v8a / x86_64 native ABIs. Native-library
hash verification passes for libmpv and its Android helper on both architectures.
The final successful build includes the missing Cupertino icon font.

## Documentation

Updated README, Android setup, playback/native-media guides, integration-test
instructions, script instructions, frozen-snapshot patch notes and Unreleased
changelog. Removed the reference to nonexistent run_android.sh and corrected
claims that this candidate resolves hosted Chromium or uses Chromium on iOS.

## Remaining release gates

- Physical Android ARM64: audible output, Home/screen lock, notification controls,
  long pause, PiP, battery/OEM restrictions, audio interruptions, headset/Bluetooth,
  task removal/recreation/restart and no unintended autoplay.
- Final release signing identity, AAB/APK install/update and store acceptance.
- macOS: the prior phase's memory/performance acceptance, lifecycle/cleanup,
  hardened signing, notarization and fresh-install gates remain unresolved.
  Current candidate is macOS 13+ / Apple Silicon; Intel and low-memory support
  claims require their own evidence.
- Windows and Linux: actual target-host build/install/playback/disposal and
  packaging verification. Linux's script correction alone is not certification.
- iOS: final device/store qualification; earlier iPhone checks remain historical.
- Physical Cast/DLNA receivers and unavailable hardware scenarios remain pending.

A green automated pass alone does not make every platform ready to release.
