# PPPlayer

PPPlayer is a Flutter media player for music discovery, local music and video libraries, network streams, and playlists. Spotify supplies catalog metadata; YouTube playback uses an embedded player. Local media uses the native playback engine.

## Current development features

- Local music/video playback, subtitles, network streams, queue management and artist discovery.
- Durable iOS music imports that remain usable after reopening the app.
- **Play On** with Cast/DLNA backends where available, an iOS system AirPlay picker, and macOS Sound settings access with a live default-output display.
- A responsive video player with a dedicated **Queue** button and secondary playback options.
- iPhone lock-screen and Control Center play/pause commands that respect explicit playback intent.
- Correct local-audio artwork without stale video thumbnails; file and network images go through `PPImage`.
- Chromium YouTube playback on Android, macOS, Windows and Linux; iOS retains WebKit. Local files and direct streams use MediaKit.
- Redesigned queue interface with desktop panel and mobile sheet integration, and a refined fullscreen player layout.

These describe the development tree, not availability in every published binary. iOS is not yet publicly available. Local AirPlay and system commands have been checked on a physical iPhone; physical Chromecast and DLNA receiver testing remain pending.

## Documentation

- [Playback and local files](docs/playback.md): user flows, import persistence, queue, system controls and troubleshooting.
- [Play On architecture and protocol support](docs/network_outputs.md): capabilities, file leases, serving lifetime and validation status.
- [Changelog](CHANGELOG.md): upcoming and released changes.
- [Pre-release validation](docs/validation/pre-release-2026-10-14/REPORT.md): current test evidence, fixes and remaining release gates.
- [Next release notes](docs/RELEASE_NOTES_NEXT.md): draft notes to promote after platform acceptance.
- [Android setup](README_ANDROID.md), [macOS release guide](MACOS_RELEASE_GUIDE.md), [Windows Store release guide](docs/WINDOWS_STORE_RELEASE.md).
- [Historical architecture discovery](PPPLAYER_CONTEXT.md): September 2026 snapshot; use the current guides above for playback behavior.

## Linux Installation

PPPlayer is distributed in multiple formats for Linux (x86_64). Tested on Ubuntu 26.04 and Debian-based systems.

**AppImage**
```bash
chmod +x PPPlayer-Linux-x86_64.AppImage
./PPPlayer-Linux-x86_64.AppImage
```

**Debian/Ubuntu (.deb)**
```bash
sudo apt install ./ppplayer_<version>_amd64.deb
```

**Portable archive (tar.gz)**
```bash
tar -xzf PPPlayer-Linux-x86_64.tar.gz
cd PPPlayer
./ppplayer
```

## Development

Install Flutter compatible with the Dart constraint in `pubspec.yaml`, along with the target platform's native toolchain. Supply the local `.env` configuration expected by `lib/main.dart`; never commit credentials.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

The candidate vendors patched Chromium sources under `third_party/chromium`.
Use the checked-in `pubspec.lock` and avoid developer path overrides during
release validation. Verify the snapshot and run all package suites:

```bash
python3 scripts/verify_chromium_snapshot.py
python3 -m unittest discover -s scripts -p 'test_*.py'
flutter test --no-pub test lib/core/playback/packages/pp_playback_engine/test third_party/chromium/packages/flutter_chromium_webview/test third_party/chromium/packages/flutter_chromium_webview_platform_interface/test
```

Run Flutter builds and device tests sequentially in the same checkout.
The current macOS candidate targets macOS 13+ on Apple Silicon; Intel and
low-memory hardware support require separate validation.

For the debug-only simulated Cast receiver:

```bash
flutter run --dart-define=PP_FAKE_CAST_DEVICE=true
```

This exercises the acquisition/server/handoff path and does not replace physical receiver testing. iOS network-device use also depends on local-network permission; DLNA discovery additionally needs the approved multicast capability and build configuration.

## Verification

Targeted device notes and sanitized evidence are under `verification/`. The October 1 system-pause check recorded a WebKit system pause changing intended state to paused, followed by explicit system play to resume. Automated checks passed with 294 app tests and clean Flutter analysis at that checkpoint.
