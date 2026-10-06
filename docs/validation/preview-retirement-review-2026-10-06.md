# Preview retirement review — 2026-10-06

Follow-up: the retained changes have been migrated and the startup seek issue
fixed. See `preview-migration-2026-10-06.md` for the backup and validation results.

Compared `C:/Users/User/Projects/ppplayer_chromium_preview` (including uncommitted
and untracked source files) with this main app checkout. The main app does not
resolve dependencies through the preview. The preview is no longer required to
run PPPlayer, but it contains unique work worth preserving before deletion.

## Findings

1. **Keep the native session cleanup fix and its regression tests.** The main
   engine schedules `doInvalidate()` and then calls it again directly. It also
   returns immediately if the session has already been detached, without waiting
   for pending cleanup. The preview instead awaits the queued cleanup once and
   waits for a previously detached session before opening its replacement. This
   matters because production adapters share the same native player: stale stop
   operations can interrupt a newly opened track. Promote this independently of
   the other native adapter changes.
2. **Fix the preview startup watchdog before promoting it.** It confirms progress
   only when position exceeds the immutable initial `startPosition`. Reproduced:
   start a local track at 30 seconds, seek immediately to 5 seconds, emit progress
   at 6 seconds, then advance the startup timeout. The engine incorrectly enters
   the error state. Account for subsequent seeks without treating a seek-position
   acknowledgement alone as proof of playback. Existing tests cover initial seek
   and normal progress, but omit this backward-seek case.
3. **Keep and validate local precise seeking and Android cache configuration.**
   The preview enables precise seeking for local/file/content/asset sources and
   configures an Android temporary demuxer cache directory, with memory-cache
   fallback for filesystem failures. The main adapter still disables precise
   seeking globally. These changes need actual local-file seek and Android cache
   acceptance; mock engine tests do not exercise native mpv property application.
4. **Keep awaited system media commands and skip local-track prewarming.** The
   preview propagates completion of pause/resume/seek to the audio handler. Its
   hybrid engine avoids preparing a local URI in the inactive YouTube service;
   local tracks already skip background handoff. Migrate with the related tests.
5. **Preserve the unique validation tools, updating paths and documentation.**
   These include Chromium unit tests, lazy-service tests, two Chromium integration
   tests, Android background/media-button/source-switch orchestration, and the
   native release probe. The release script assumes a sibling native-media repo
   and verifies local artifacts by default. From the main app its sibling path
   points into `ppplayermusic`, not `Projects`; update it and verify the published
   package using the verifier's `--package` option. The script installs a probe
   under the normal app ID and does not automatically reinstall the saved app
   APK. Integration documentation also still describes the old private native
   dependency instead of the published package.
6. **Review Windows first-build dependencies and preserve LF shell attributes.**
   The preview orders mpv/ANGLE extraction and WebView2 download before compiling
   their consumers, a useful clean-build safeguard absent from the main app.
   Validate against the current plugin target names on a clean build. Preserve
   `*.sh text eol=lf` from its `.gitattributes` for Linux/macOS checkouts.

## Already included or superseded

The Chromium engine and service implementation, Android native service hooks,
lazy native fallback implementation, Flutter Widget playback rendering, desktop
Cast stream guard, native Windows runner/sandbox setup, and generated Chromium
plugin registrations are already present in the main app.

Do not overwrite the main app's current player layout, queue presentation,
published dependency constraints, Dart minimum, or iOS Chromium selection with
older preview versions. Most Android build differences are equivalent grouping;
generated registrants and lockfiles should be regenerated, not copied wholesale.

## Verification and retirement order

Preview tests: 13 Chromium/service/iOS media-command tests and 55 native-engine
tests pass. A temporary backward-seek regression probe fails as described above;
the temporary source file was removed after the check. Logs are in the preview's
`build/preview-review-tests.log`, `build/preview-review-native-tests.log`, and
`build/preview-review-seek-probe.log`. No emulator, WSL, macOS, iOS, or live native
playback acceptance was rerun during this source review.

First preserve the preview's uncommitted and untracked source work in a backup.
Then migrate the independent fixes and tests into the main app, repair the
watchdog, adapt the validation helpers to published dependencies, and run the
relevant runtime checks. Retire the preview after those steps. This review does
not merge or delete either checkout.
