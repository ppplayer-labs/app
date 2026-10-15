# Next release — draft notes

Status: unreleased candidate. Version and publication date are not assigned.
The current application metadata remains 3.0.3+11. Promote these notes and the
Unreleased changelog only after the selected platform's acceptance gates pass.

## User-facing changes

- Android background-playback visibility correction for the embedded YouTube
  player. Home and screen-lock behavior must pass the candidate's device checks
  before this is advertised as a verified fix.
- Existing candidate work improves local-file access, player/queue navigation,
  responsive layouts, playback recovery and macOS video-surface resizing.
  Those changes retain their separate platform acceptance requirements.

## Engineering changes

- Linux packaging once again builds a fresh release bundle before generating
  distribution artifacts; failed builds cannot fall through to stale packaging.
- Expanded CI coverage for vendored Chromium, frozen source integrity and
  packaging/configuration guards.
- Portable Android lifecycle acceptance runner and corrected production-engine
  test setup, including a ten-second explicit pause check.
- Refreshed setup, playback and dependency documentation.

## Release preparation

Use the [October 14 validation record](validation/pre-release-2026-10-14/REPORT.md)
for actual results and unresolved gates. Do not infer a platform pass from another
platform's tests. Include `pubspec.lock` and the vendored Chromium snapshot in the
candidate commit. Set the chosen version consistently in pubspec, MSIX and
release notes; build and smoke-test those final artifacts before publication.
The current workflow publishes all platform artifacts together and must not be
triggered as a substitute for platform acceptance.
