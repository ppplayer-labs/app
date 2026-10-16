# Changelog

All notable changes to PPPlayer will be documented in this file.

## [4.0.1] - 2026-10-16

Release metadata: **4.0.1+13**, Windows MSIX **4.0.1.0**.
Publisher: Devflier.

### Fixed

- macOS duplicate media controls: suppressed Chromium's separate system media session via `CEF_SYSTEM_MEDIA_CONTROLS=0` before CEF initializes, ensuring PPPlayer's native Now Playing controls remain the single authoritative media session.
- Fixed CMake lookup from Homebrew and `/Applications/CMake.app` when building the native CEF framework from Xcode's restricted PATH environment.
- Upgraded `flutter_chromium_webview` to hosted release `0.5.5` from pub.dev.

## [4.0.0] - 2026-10-15

Latest published app release: **4.0.0 (October 15, 2026)**.
Release metadata: **4.0.0+12**, Windows MSIX **4.0.0.0**.
Publisher: Devflier.

### Compatibility changes

- macOS minimum rises from 12 to 13; current candidate validation covers Apple Silicon only. Intel/universal support is not qualified.
- Android builds now package ARM64 and x86_64, without 32-bit ARM.
- iOS deployment target remains 15.0; earlier website 14.0 claims were inaccurate.

### Added and improved since 3.0.2

- Chromium YouTube routing on Android/macOS/Windows/Linux with vendored native sources; iOS retains WebKit. Direct/local media stays on MediaKit.
- Queue redesign with desktop panel/mobile sheet, independent fullscreen navigation, resizable desktop width and debounced persistence.
- Network playlists: M3U/PLS/XSPF/ASX parsing, HLS classification, relative URLs, IPTV headers/groups, deduplication, bounded HTTP reads and timeouts; improved stream error handling and browsing.
- Local-library schema 14 retained-data handling, file access/relinking, metadata and video probing improvements.
- Playback ownership, recovery, source-switching and native control regressions; macOS Chromium video resizing correction and import entitlements.
- Linux packaging scripts for AppImage, Debian and portable archives; artifacts require Linux validation.
- Expanded localization, store-listing tooling, native integration probes and release regression checks.

Full implementation evidence, retained capabilities and unresolved acceptance:
[October 15 audit](docs/RELEASE_AUDIT_2026-10-15.md).


### Changed

- Windows MSIX publisher display name is Devflier; application display name remains PPPlayer.

### Fixed

- macOS normal Quit now forwards Flutter-approved termination retries after Chromium shutdown; validated in an actual Release build with no tracked helper survivors.

- Corrected Android autoplay WebView visibility propagation during Activity minimize. Live screen-off playback still stalls; this correction is not yet a verified background-playback fix.
- Linux packaging builds a fresh release bundle and stops on Flutter build failure, preventing missing or stale artifacts in clean CI.
- Corrected two network-output test files that failed the release formatting check.
- Included the Cupertino icon font required by reachable Flutter controls, eliminating the missing-font release-build warning.

### Validation and documentation

- Added a Python Android acceptance runner for macOS/Linux/Windows covering Home, screen-off, system pause/play and repeated local-video/YouTube transitions.
- Corrected the live Android test to disable PiP for the minimize check, use production persistent-player ownership and verify a ten-second explicit pause.
- Release CI now runs the vendored Chromium package tests, checks frozen source hashes and runs packaging regression guards.
- Updated Android setup, playback architecture, candidate dependency/SDK guidance and platform support documentation. Current results and remaining device/distribution gates are in `docs/validation/pre-release-2026-10-14/REPORT.md`.
- Local static analysis and 604 app/engine/Chromium tests passed at the October 14 checkpoint; this does not announce a published release or certify untested platforms.

### Candidate scope carried forward from unpublished entries

The former 3.0.3 and 3.1.0 headings described candidate work, not published
GitHub releases. Their changes are included in the 4.0.0 draft above. The app
has a v3.0.3 tag but no corresponding published release as of October 15.

## [3.0.2] - 2026-10-06

### Added
- Added lofty v0.22.4 metadata library for audio playback package.

### Changed
- Updated iOS app icons, release documentation, and encryption declaration.
- Hardcoded macOS deployment target to 12.0 to resolve CI build failure.

### Fixed
- Resolved undefined variable error in user authentication module.

## [3.0.1] - 2026-10-02

### Fixed

- The iOS native playback surface no longer automatically pauses imported music when the app enters the background or resumes deliberately paused music on foreground return.
- iOS audio-session activation retries failed attempts and reactivates native playback after pause, while leaving WebKit renderer session activation to WebKit to avoid repeated interruptions.

### Validation

- 417 app and playback-engine tests passed with clean analysis, including background lifecycle, audio-session ownership and explicit system-pause regressions.
- Physical-device background acceptance remains pending. This version entry does not announce a published release.

## [3.0.0] - 2026-10-02

### Added

- macOS Play On shortcut to system Sound settings, with live default-output name and selection from Core Audio.
- macOS Chromecast sender with native Bonjour discovery, Default Media Receiver launch, playback controls and local-file HTTP handoff. Physical receiver validation remains pending.
- Compact desktop navigation and playback controls for narrow windows, a labeled Queue button that opens the queue directly, and adaptive home headings. Fixed playlist-card artwork overflowing its available height.
- Play On access to the iOS system AirPlay picker, with receiver name and active-route selection.
- A dedicated Queue button and responsive video controls, with secondary actions grouped in an options menu.
- Apple-aware file acquisition for network outputs, resolving managed locators and security-scoped bookmarks through local_library.

### Fixed

- iOS imported music now uses durable managed copies instead of temporary file-picker paths.
- Security-scoped file access stays active during local playback and accepted HTTP reads; release waits for readers to finish.
- Fake Cast receiver callbacks are asynchronous and validate endpoint, session and item identity without weakening controller guards.
- iPhone Control Center and lock-screen commands reach playback intent through native and WebKit media-session bridges; explicit pause cancels automatic recovery.
- Background pause reporting reflects renderer state until play is acknowledged.
- AirPlay selection no longer incorrectly leaves This device selected while a receiver is active.
- Local songs no longer inherit a previous video's thumbnail; direct image-provider consumers use PPImage.

### Documentation and validation

- Added current playback and network-output guides, protocol availability and resource-lifetime documentation.
- Physical iPhone checks confirmed local music over AirPlay to a MacBook and system pause/play command delivery. Physical Chromecast and DLNA testing remain pending.
- App checks passed with 294 tests and clean Flutter analysis at the October 1 checkpoint. These changes are not a public-release announcement.

## [2.0.1] - 2026-09-21

### Added
- Added support for Dutch, Romanian, Thai, Ukrainian, Urdu, and Vietnamese localizations.
- Added direct top tracks playback on artist cards in the artist and home screens.
- Added direct playlist and album playback to the AlbumCard hover overlay.
- Added Instagram, Facebook, and LinkedIn links to the about dialog.

### Changed
- Redesigned genre and search category cards with dynamic hash-based colors and icons.
- Updated action buttons in the about dialog.
- Routine maintenance and removal of temporary debugging and development scripts from the repository to reduce clutter.

## [2.0.0] - 2026-09-20

### Added
- Complete local video library and playback support with video controls and thumbnail generation.
- Comprehensive subtitle support with customization, delay adjustment, and selection UI.
- Network stream support with M3U playlist parsing and direct URL resolution.
- Added playback speed controls and an autoplay toggle to the queue view.
- Added Turkish and Guarani localizations.
- Added local genres support.
- Updated app icons, favicon, and theme colors.

### Changed
- Overhauled core architecture and playback engine for improved stability, timeout handling, and session protection.

### Fixed
- Fixed UI inconsistencies with tactile buttons and avatar colors.
- Improved database migration reliability.


## [1.3.5] - 2026-09-16

### Fixed
- Fixed responsiveness issues on the Library screen cards ("Liked Songs" and "Local Music") where text would wrap awkwardly on smaller window widths.

## [1.3.4] - 2026-09-16

### Added
- Added automated MSIX packaging for Windows releases, including Microsoft Store publishing support.

### Fixed
- Fixed splash screen flashing white on startup when dark mode is enabled on some platforms.
- Fixed problems with Picture-in-Picture (PiP) mode.

## [1.3.2] - 2026-09-15

### Fixed
- Fixed an issue where adding a song that was already in a playlist would cause a database error.
- Fixed a severe UI freeze and crash on Windows when navigating to the Playlists view, caused by a system cursor conflict with periodic audio playback sync.

## [1.3.1] - 2026-09-14

### Added
- Implemented the Library screen with filtering, sorting, and search capabilities.
- Added MediaSyncService to synchronize playback status with system OS media controls.
- Implemented local Drift database for persisting playlists and playback history.

## [1.3.0] - 2026-09-13

### Added
- Added localizations for Nigerian Pidgin, Filipino, Latvian, Bengali, Croatian, Malay, Persian, and Estonian languages.


## [1.1.2] - 2026-09-12

### Added
- Added Arabic and Chinese (Simplified & Traditional) localizations.

### Fixed
- Fixed an issue on macOS where the YouTube video player would shift off-center when resizing the application window.

## [1.1.1] - 2026-09-12

### Fixed
- Fixed an issue where the seek bar would instantly snap back to the start position when sliding it immediately after launching the app.
- Fixed the seek bar showing a duration of 0:00 when the app is first launched.

## [1.1.0] - 2026-09-11

### Added
- Comprehensive internationalization and localization across the entire app and website.
- Added full support for 11 global languages: Spanish, French, German, Portuguese, Italian, Japanese, Korean, Chinese, Hindi, Russian, and Arabic.
- Added an in-app language picker in the Preferences menu that applies translations instantly without restarting the app.
- Native OS-level language integrations on Android 13+ and iOS to sync the app's language automatically with system-level per-app language settings.
- Replaced all hardcoded text strings in the app and website with responsive localization keys.

## [1.0.6] - 2026-09-11

### Fixed
- Fixed a critical bug causing the app to crash on a blank screen on fresh installations due to a missing environment configuration file.

## [1.0.5] - 2026-09-11

### Fixed
- Fixed an issue on macOS where background playback would pause between songs when the app was minimized due to App Nap.

## [1.0.4] - 2026-09-11

### Added
- Automated release workflow via GitHub Actions for consistent builds and code signing.
- Official signed and notarized macOS releases now available directly on the website.
- Added MIT License to the repository.

### Fixed
- Fixed submodule checkout configuration in CI workflows.

## [1.0.3] - 2026-09-10

### Added
- Hybrid playback engine providing robust background processing and lock-screen playback capabilities.
- Deduplication and generation IDs to prevent overlapping and stale media commands across WebView bridge.

### Fixed
- Fixed an issue where the song queue would sometimes not automatically advance to the next track.
- Fixed a bug where a paused track would unexpectedly resume when handing off from foreground to PiP or background.
- Accurate millisecond precision reporting for current track position and playback duration.
- Eliminated several IDE linter errors and cleaned up redundant files.

## [1.0.2] - 2026-09-09

### Improved
- Context-aware Autoplay prioritizes original artist before falling back to related artists.
- Tiered Recommendation Engine accurately pulls exact artist tracks without mismatched searches.
- Autoplay uses explicit playback context instead of only relying on majority queue items.

## [1.0.1] - 2026-09-09

### Added
- Autoplay recommendations when the playback queue is ending.
- Custom Spotify and YouTube API credentials.
- Discover section with personalized recommendations.
- Additional language support.
- Added dynamic tooltip that follows the mouse cursor on the seekbar.

### Changed
- Improved playback queue persistence.
- Improved macOS media control integration.
- Updated player animations using Material 3 Expressive-inspired motion.

### Fixed
- Fixed duplicate macOS Now Playing controls caused by WebKit.
- Fixed station tracks not being highlighted correctly.
- Fixed playback state restoration after restarting the app.
- Fixed playback pausing/stopping unexpectedly when dragging the seekbar.
- Fixed bottom player bar rendering fully transparent and unreadable on macOS when playing music.

---

## [1.0.0] - 2026-09-XX

### Added
- Initial public release of PPPlayer.
- Spotify-powered music metadata.
- YouTube-powered audio playback.
- Playlists, favorites and listening history.
- macOS, Windows and Linux support.
