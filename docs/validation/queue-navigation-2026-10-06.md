# Separate queue and video navigation — 2026-10-06

Queue actions now push `/queue`, a dedicated QueueScreen using the existing
queue list, reorder controls, autoplay and export actions. The desktop queue
button and mobile player-bar background open this page without changing video
preferences or starting/stopping playback. Opening the queue from fullscreen
first exits fullscreen.

The floating video thumbnail has a click/tap target which selects video mode
and opens `/player?fullscreen=true`. PlayerScreen enters fullscreen after its
first frame. Its existing fullscreen exit and collapse controls remain in use.
The shell keeps the playback surface mounted but moves it out of the visible
content while the queue route is open. Previous saved queue-view choices are
normalized when opening PlayerScreen.

Validation: Flutter analysis passes. The 28 player UI tests pass, including
queue-only navigation on wide and narrow windows and returning to the mounted
video page. All 8 desktop responsiveness/navigation tests pass, including the
queue button leaving the video preference unchanged. The Windows debug app
builds and launches; runtime logs show a 1920x1080 fullscreen video surface.

The behavior is shared across platforms; native fullscreen and browser input
still need runtime acceptance on Android, Linux, macOS and iOS. The previously
observed Chromium named-profile warning is separate and remains unresolved.

Logs: `build/queue-navigation-analysis.log`, `build/queue-navigation-tests.log`,
`build/queue-desktop-tests.log`, and `build/queue-navigation-run.log`.
