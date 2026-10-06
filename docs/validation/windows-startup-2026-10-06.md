# Windows startup check — 2026-10-06

Host: Windows x64, Flutter 3.47.4 / Dart 3.13.3. Debug build of the main app.

An earlier ppplayer process tree held WebView2Loader.dll open and blocked the
first build. Only processes from this app's exact debug executable path were
stopped before retrying. The Windows build then succeeded and opened PPPlayer.

Initial logs confirmed MediaKit initialization, database and audio-handler
startup, and successful CEF initialization. Two application integration errors
were found and corrected:

- Native Cast events subscribed to a mobile-only platform channel on Windows.
  Desktop clients now expose an empty native event stream; the separate macOS
  desktop client and mobile native channel behavior stay intact.
- PlaybackView passed a Chromium Widget renderer to MediaKit's VideoController
  parameter. Widget renderers now render directly, with the loading overlay.
- PlayerOverlays and VideoControlsOverlay also accessed `renderer.player`
  unconditionally. They now expose native track/subtitle controls only when the
  renderer is a MediaKit VideoController.

Seven focused tests pass, including the new browser-renderer and desktop channel
regressions plus the existing provider and iOS background-view tests.
All 28 player UI tests also pass, and final Flutter analysis reports no issues.

The existing uncommitted `chromium_webview_enable_sandbox` CMake change was
preserved and included in the local build; it was not authored by this audit.

Initial CEF logs also reported that the named YouTube profile could not be
created under the default profile path. Session persistence and actual local/
YouTube playback still need acceptance checks. A responsive application window
and successful startup do not establish audible playback or correct seeking.

Local logs: `build/windows-startup-check.log`,
`build/windows-startup-recheck.log`, `build/windows-startup-regressions.log`,
`build/windows-startup-final.log`, `build/windows-player-ui-tests.log`,
and `build/windows-startup-analysis.log`.
