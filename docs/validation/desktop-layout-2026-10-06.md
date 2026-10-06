# Desktop player layout — 2026-10-06

Windows and macOS use the shared PlayerScreen layout. This update keeps the
existing edge-to-edge video surface and changes the surrounding desktop UI:

- Queue items use 40px artwork, 10px padding, smaller corners and quieter text.
  The current item retains its accent border without the large shadow.
- The desktop queue header includes a close button.
- Fullscreen temporarily hides the queue while preserving its open state.
  Returning from fullscreen restores the panel and keeps the video slot mounted.
- Controls stay visible in normal desktop windows; fullscreen video retains
  the existing idle-hide behavior. Header and bottom-control padding are tighter.
- Mobile queue styling and the existing desktop/narrow breakpoint stay in use.

Validation on Windows: 28 player UI tests pass, including queue dismissal,
breakpoint changes, full-width fullscreen video slot and queue restoration.
Flutter analysis reports no issues. The updated debug app builds and launches.

macOS shares these changes but has not been visually checked on a Mac. The
previous Chromium profile warning remains a separate playback integration issue.

Local logs: `build/desktop-layout-tests.log`, `build/desktop-layout-analysis.log`
and `build/desktop-layout-run.log`.
