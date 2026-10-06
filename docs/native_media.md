# Native media integration

Audit and dependency migration: 2026-10-06.

`flutter_media_kit` supplies the Android libmpv and JNI helper binaries. The Dart
playback API still comes from `media_kit` and `media_kit_video`; their imports and
player classes stay in use. No Dart import of `flutter_media_kit` is required:
Flutter registers its Android plugin from the dependency graph.

## Where the native libraries are used

| Entry point | Role |
| --- | --- |
| [main.dart](../lib/main.dart) | Initializes MediaKit before players are created |
| [Playback providers](../lib/core/playback/playback_providers.dart) | Selects native playback beneath the Chromium wrapper; Android uses the hybrid engine |
| [Hybrid engine](../lib/core/playback/hybrid_playback_engine.dart) | Creates the foreground MediaKit engine |
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

The main app also uses the hosted `flutter_chromium_webview` 0.3.1 package,
allowing a fresh checkout and CI to resolve dependencies without a sibling
Chromium checkout. Local packages under `lib/core/playback/packages/` remain
versioned app patches.

The hosted Chromium release requires Dart 3.13.3 and Flutter 3.47.0 or later.
The app declares the matching Dart minimum and CI uses the tested Flutter 3.47.4.
CI explicitly retains Dart 3.8 formatting for app files and 3.7 for the nested
engine, avoiding an unrelated repository-wide formatting migration.

The separate `ppplayer_chromium_preview` checkout resolves hosted
`flutter_media_kit` too, while keeping its local Chromium development dependency.
Its existing uncommitted playback experiments remain separate from this app.

## Remaining acceptance and maintenance

The main adapter still disables precise seeking for every source and does not
configure an Android demuxer disk-cache directory. The preview contains local
precise-seek and Android cache-directory corrections. Promoting those corrections
requires a separate review of the engine behavior and actual local-file/network
playback acceptance; this dependency migration does not merge the preview's
uncommitted engine and lifecycle changes.

The Android build also reports upcoming Flutter compatibility changes for AGP
9.0.0, Kotlin 2.2.20 and plugins using the Kotlin Gradle Plugin. Handle that
toolchain migration separately from replacing the native provider.

Package resolution, unit tests and APK binary hashes do not establish physical
ARM64 playback or audible output. Windows/Linux/macOS/iOS runtime checks also
remain distinct from retaining their dependency versions. See
[the integration validation record](validation/native-media-2026-10-06.md).
