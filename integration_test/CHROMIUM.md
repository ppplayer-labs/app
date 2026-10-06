# Chromium playback validation

Run these checks from the main PPPlayer app. It uses hosted
`flutter_chromium_webview` and `flutter_media_kit` dependencies; no preview
checkout or local Chromium dependency is required.

`chromium_playback_test.dart` uses a local browser fixture to exercise facade
commands and native fallback. `chromium_live_ui_test.dart` uses live YouTube and
the real player screen to check pause/resume, seeking, volume, and optional
Android background and local-video/YouTube source-switch phases. Unit tests
provide catalog, database, and settings fixtures for the live UI check.

```powershell
flutter test integration_test/chromium_playback_test.dart -d windows
flutter test integration_test/chromium_live_ui_test.dart -d windows
./scripts/test_chromium_android.ps1 -Device emulator-5554
flutter build apk --release --target-platform android-arm64,android-x64
```

The Android helper coordinates Home, screen-off progress, media pause/play,
return to the activity, and three source-switch rounds using readiness markers.
It fails if a phase is missing. It restores the activity after a failure and
retains the main log and adjacent screen-off evidence.

```bash
# Run in a Linux checkout with Flutter and the native build tools installed.
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe GDK_BACKEND=x11
export CMAKE_BUILD_PARALLEL_LEVEL=2
flutter pub get
flutter test integration_test/chromium_playback_test.dart -d linux
flutter test integration_test/chromium_live_ui_test.dart -d linux
```

Run Flutter tests and builds sequentially within a checkout to avoid generated
plugin and native-asset races. Use a separate WSL filesystem checkout for Linux.
Shell entry points must use LF line endings, enforced by `.gitattributes`.

The native release video probe is documented in `../tool/README.md`. These
checks do not establish audible speaker output, physical-device battery
behavior, authenticated catalog navigation, or acceptance on untested devices.
