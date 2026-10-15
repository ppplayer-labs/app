# Native media integration

Updated for the development candidate: 2026-10-14.

`flutter_media_kit` supplies the Android libmpv and JNI helper binaries. The Dart
playback API still comes from `media_kit` and `media_kit_video`; their imports and
player classes stay in use. No Dart import of `flutter_media_kit` is required:
Flutter registers its Android plugin from the dependency graph.

## Where the native libraries are used

| Entry point | Role |
| --- | --- |
| [main.dart](../lib/main.dart) | Initializes MediaKit before players are created |
| [Playback providers](../lib/core/playback/playback_providers.dart) | Selects native playback beneath the Chromium wrapper; Android uses the hybrid engine |
| [Hybrid engine](../lib/core/playback/hybrid_playback_engine.dart) | Keeps the Android foreground Chromium wrapper as owner; MediaKit handles its native fallback |
| [MediaKit engine](../lib/core/playback/packages/pp_playback_engine/lib/src/engine/media_kit_playback_engine.dart) | Creates Player/VideoController for local media and native fallback streams |
| [Video probing](../lib/core/local_library/video_probe_service.dart) | Opens media with a native player to inspect video parameters |
| [Thumbnail generation](../lib/features/library/video_thumbnail_generator.dart) | Opens native media, seeks and captures a frame |

YouTube's Chromium playback uses `flutter_chromium_webview` and a browser renderer.
The Android `NativeServicePlaybackEngine` name refers to a headless WebView
service, not libmpv. Those paths do not become MediaKit playback merely because
the native-library provider changed.

## Dependencies and architectures

| Platform | Native provider | Locked version |
| --- | --- | --- |
| Android | flutter_media_kit | 1.3.8+ppplayer.egl1 |
| Windows | media_kit_libs_windows_video | 1.0.11 |
| Linux | media_kit_libs_linux | 1.2.1 |
| macOS | media_kit_libs_macos_video | 1.1.4 |
| iOS | media_kit_libs_ios_video | 1.1.4 |

The old `media_kit_libs_android_video` path override and the
`media_kit_libs_video` umbrella were removed. The umbrella would bring back the
original Android provider, producing duplicate Java/native definitions alongside
`flutter_media_kit`. Other native providers retain their existing versions.

Android `ndk.abiFilters` now permits ARM64 and x64 only. The package does not
include 32-bit Android libraries. Flutter's default ABI filtering is disabled
so it cannot overwrite these filters, and packaging excludes stray 32-bit
libraries from other dependencies. Build both supported APK targets with:

```sh
flutter build apk --debug --target-platform android-arm64,android-x64
```

The main app uses a patched, repository-relative Chromium 0.5.2 source snapshot
and platform interface 0.1.5 under `third_party/chromium`. It does not resolve the
unmodified hosted release. `SOURCE_MANIFEST.json` records source hashes and
candidate patches; verify it with `python3 scripts/verify_chromium_snapshot.py`.
Local packages under `lib/core/playback/packages/` remain versioned app patches.

The candidate's Dart floor is 3.12; local validation uses Flutter 3.44.8 / Dart
3.12.2. CI requests Flutter 3.47.4; local results do not certify that separate SDK.
CI explicitly retains Dart 3.8 formatting for app files and 3.7 for the nested
engine, avoiding an unrelated repository-wide formatting migration.

The separate `ppplayer_chromium_preview` checkout resolves hosted
`flutter_media_kit` too, while keeping its local Chromium development dependency.
Its existing uncommitted playback experiments remain separate from this app.

## Android background ownership

Android uses `PlaybackOwnershipPolicy.persistentForeground`. Activity stop,
PiP changes and screen-off retain the same Chromium player instead of handing
audio to the legacy service WebView. `CustomWebViewService` supplies a foreground
service lease without creating a competing WebView; AudioService remains the
media-control authority. Explicit pause cancels playback intent.

Autoplay WebViews preserve Chromium's visible-window state on Activity minimize
so the embedded media is not suspended by that transition. Ordinary browsing
WebViews retain normal Android visibility handling. This native patch is tracked
in the snapshot manifest. See [Android acceptance](../README_ANDROID.md) and
the [current validation report](validation/pre-release-2026-10-14/REPORT.md).

## Remaining acceptance and maintenance

The preview retirement review is in
`validation/preview-retirement-review-2026-10-06.md`. Its native session cleanup,
local precise seeking, Android cache directory, and awaited system media-command
changes have now been brought into the main app with regression tests. The
startup watchdog also tracks subsequent seek targets, preventing a backward
seek from being mistaken for stalled playback. Validation tools now live in
`integration_test/`, `scripts/`, and `tool/`; the release probe verifies the
resolved published native package. Runtime acceptance remains platform-specific.

The Android build also reports upcoming Flutter compatibility changes for AGP
9.0.0, Kotlin 2.2.20 and plugins using the Kotlin Gradle Plugin. Handle that
toolchain migration separately from replacing the native provider.

Package resolution, unit tests and APK binary hashes do not establish physical
ARM64 playback or audible output. Windows/Linux/macOS/iOS runtime checks also
remain distinct from retaining their dependency versions. See
[the integration validation record](validation/native-media-2026-10-06.md).
