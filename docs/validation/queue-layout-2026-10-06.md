# Queue page layout — 2026-10-06

The standalone queue now uses one page heading, a Now playing section, and an
Up next list instead of a centered column of bordered cards. Upcoming tracks
use flat rows with subtle hover feedback, numbered positions, artwork, artist
and duration. Wide screens additionally show album details. The app's existing
colors and persistent playback bar stay in use.

Earlier tracks remain in the playback model but are not displayed in Up next.
Track selection and context menus preserve original queue indices. Upcoming
tracks remain draggable; the final drop index is converted to the insertion
index expected by PlaybackQueue. The current and earlier tracks stay in place.
Autoplay and playlist export remain in the page toolbar.

The two new section labels use the localization system. Languages without
translations for these labels currently fall back to English.

Validation: 30 player UI tests pass. New tests cover 320px/1200px layouts,
current/upcoming separation, original-index track selection, and reordering
both upward and downward without moving the playing track. Flutter analysis
reports no issues. The Windows debug application is rebuilt for visual review;
the shared layout still needs visual checks on other platforms.

Logs: `build/queue-redesign-tests.log`, `build/queue-redesign-analysis.log`,
and `build/queue-redesign-final-run.log`.
