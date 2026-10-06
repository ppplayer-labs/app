# Windows video behind controls — 2026-10-06

Chromium's Flutter Widget renderer now uses the full player video slot on
Windows, behind the existing playback controls and their gradients. Previously,
the legacy floating WebView2 workaround also affected Chromium online playback
because both report `isIFrameMode`, reserving 72px above and 230px below the video.
Those insets now apply only to the legacy renderer that cannot paint under Flutter.

Validation: 38 player and desktop UI tests pass, static analysis reports no
issues, and the Windows debug build launches with a responsive PPPlayer window.
Visual acceptance during video playback remains a manual check.

Logs: `build/video-overlay-tests.log`, `build/video-overlay-analysis.log`, and
`build/video-overlay-run.log`.
