# Desktop responsiveness — October 2, 2026

The reported narrow-window layout used a 240-pixel sidebar and full playback
controls at widths as low as 600 pixels, crowding the header and overflowing the
playback bar. Windows below 1000 pixels now use a 72-pixel navigation rail,
compact transport controls, Play On, and a labeled Queue button. Secondary
controls remain accessible in More playback controls. Queue opens its view
directly. The home greeting uses actual content constraints and can wrap.
Playlist artwork fits the height available above its labels.

Validation:

- Actual playback-bar widget at 600, 610, 800, 999, 1000 and 1200 pixels: no
  layout overflow; Play On and Queue remain inside the window.
- Secondary-menu shuffle action, scrollable navigation in a 300-pixel-tall
  window, Favorites destination, and direct Queue navigation are tested.
- Live macOS app resized to approximately 610 pixels: compact navigation,
  complete home greeting, visible Queue/Play On and accessible volume menu.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: all 320 tests pass; 8 new responsiveness tests.
- `flutter build macos --debug --no-pub`: succeeds. Existing plugin Swift Package
  Manager adoption warnings remain.

Files: scaffold_with_nav.dart, compact_desktop_navigation.dart,
home_screen.dart, library_screen.dart, desktop_responsiveness_test.dart,
playback documentation and changelog. Logs here contain test/build evidence,
without live application HTTP headers or account tokens.
