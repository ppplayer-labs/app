# Native media integration validation — 2026-10-06

Host: Windows. Flutter 3.47.4 / Dart 3.13.3. App version: 3.0.2+10.

## Dependency resolution

- Main app resolves hosted `flutter_media_kit` 1.3.8+ppplayer.egl1 and hosted
  `flutter_chromium_webview` 0.3.1, with platform interface 0.1.5.
- Android's generated dependency graph contains one native MediaKit provider:
  `flutter_media_kit`. The original Android provider and umbrella are absent.
- Existing Windows, Linux, macOS and iOS native providers retain their versions.
- Preview dependency resolution also succeeds with the hosted native package;
  it retains the local Chromium dependency and existing uncommitted experiments.
  Preview was not rebuilt or runtime-tested during this audit.

## Checks

- Flutter analysis: no issues.
- CI formatting check: 238 app files and 15 nested-engine files pass. App
  formatting is pinned to Dart 3.8; nested engine formatting is pinned to 3.7.
- Playback/player/engine regression selection: 121 tests pass.
- Full CI test suite: all 417 tests pass on Windows.
- Two existing test fixtures assumed POSIX paths on Windows. The Android
  playlist fixture now explicitly uses Android-style separators; artwork uses
  a host-native temporary path. Both files pass all four tests after correction.
- Full app Android debug APK builds for ARM64 and x64. ZIP inspection confirms
  exactly `arm64-v8a` and `x86_64`, including libraries from other dependencies.
- `verify_apk.py` verifies all four libmpv/helper binaries against the downloaded
  pub.dev package; all match.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256: `b337653373cb04a581970a5b2ec26a71508f18054001489f067c385f856315a5`.

Local ignored check logs:

- `build/native-package-final-analysis.log`
- `build/native-package-ci-tests.log`
- `build/native-package-final-tests.log` (121 selected regressions)
- `build/native-package-windows-fixture-tests.log`
- `build/native-package-final-apk.log`

## Limits and follow-up

This audit does not establish emulator playback, physical ARM64 playback,
audible output, or Windows/Linux/macOS/iOS runtime behavior. It does not publish
an app release or change its version. The package itself supplies Android native
libraries; the other platforms continue using their separate existing providers.

Promote the preview's Android demuxer cache-directory and precise local seek fixes
through a focused review and playback acceptance tests. Review AGP/Kotlin migration
warnings separately. See [the usage audit](../native_media.md).
