# Adaptive queue presentation — 2026-10-06

This replaces the earlier `/queue` navigation with a queue presentation that
preserves the current page. Windows, macOS and Linux windows at least 900 logical
pixels wide toggle a 360px right-hand panel. Mobile and narrower windows use a
modal bottom sheet with a drag handle, swipe dismissal and an explicit close
button. Both reuse the Now playing / Up next list and its reorder/export actions.

Fullscreen temporarily hides the desktop panel. Opening the queue from the
fullscreen player exits fullscreen first. The floating video thumbnail remains
the independent entry point for fullscreen video and moves left when the desktop
queue is open, keeping it outside the panel.

Validation: all 38 player and desktop UI tests pass. Tests exercise desktop panel
state without route changes, sheet opening/dismissal at narrow widths, unchanged
video preferences, and the existing queue selection/reorder behavior. The shared
presentation still needs runtime acceptance on Android, Linux, macOS and iOS.

Logs: `build/queue-panel-checks.log`, `build/queue-panel-final-analysis.log`,
and `build/queue-panel-run.log`.
