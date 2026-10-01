# Physical iPhone import persistence diagnosis

No implementation changes made during this investigation. Network Outputs testing is paused.

## Confirmed from device logs

The playback engine reports `No such file or directory` for imported media under `/private/var/mobile/Containers/Data/Application/<container>/tmp/`. Nine distinct missing paths occur across several container IDs. The library/queue records survive, but the temporary media copies they refer to are absent. This is a filesystem-not-found failure before any Cast handoff. The logs do not identify the exact cleanup/reinstall event that removed each file.

Sanitized evidence is in `missing-files.log`; credentials and unrelated network logs are excluded.

## Confirmed from code

- Installed file_picker_darwin 1.2.0 uses a document picker with `asCopy: true` for files and contains copying into `NSTemporaryDirectory()`. Returned file paths are temporary picker copies, not durable library ownership.
- `local_library_service.dart:49`: only Android cache imports are copied into `Documents/local_music`. iOS instead bookmarks the picker path, or persists the raw temporary absolute path on bookmark failure. Bookmarking a temporary copy does not preserve its contents.
- `app_database.dart:390`: the saved locator is returned as `Track.localFilePath`.
- `playback_providers.dart:92`: that locator becomes `PlaybackTrack.localMediaUri` unchanged.
- `player_provider.dart:695`: local playback passes that track directly to the controller; the local engine receives the raw locator without local_library resolution. Bookmark resolution exists at the Network Outputs acquisition boundary, but local playback/restore does not use it.
- `local_library_service.dart:596`: metadata extraction also receives the opaque bookmark as a filesystem path after successful bookmark creation; video probing has the same problem.

## Required correction before resuming Cast testing

1. Copy temporary iOS picker files into durable app-owned storage before persisting them, with collision-safe names and locators that survive sandbox path changes.
2. Resolve persisted local-library source mechanisms at local playback/restore and metadata/probe boundaries; retain and release external security-scoped access correctly.
3. Treat missing legacy temporary copies as missing and allow reselect/reimport; deleted contents cannot be recovered merely by resolving an old bookmark.
4. Add import -> close/reopen -> playback regression coverage. The prior Network Outputs test mocked local playback and did not verify this persistence path.

## Fix implemented

- iOS single-file imports now copy media into `Documents/local_music/<uuid>/...` before saving the library entry. The `pp-local:` relative locator survives sandbox directory changes and prevents same-name imports from overwriting each other.
- Metadata and video probing operate on the resolved real file path.
- Apple local playback/restore uses `LocalFilePlaybackController` to acquire a real file URI. Status keeps the durable source locator for queue persistence and Network Outputs; security-scoped bookmark access stays active through pause and releases after stop/dispose closes the reader.
- The Apple Network Outputs acquisition boundary also accepts the managed relative locator.
- Availability checks release their temporary bookmark access.
- Four regressions cover import -> source deletion -> database/queue reopen -> playback with relocated Documents; filename collisions; traversal rejection; and bookmark reader/access lifetime.

Validation: `flutter analyze` has no issues; all 278 Flutter unit/widget tests pass. The native physical-device persistence integration test built but was canceled after the device installer stalled before launch; no native integration result is claimed. The updated normal app subsequently built, installed, and launched on the physical iPhone with Fake Cast enabled (20.8 s Xcode build, 24.2 s install/launch).

Legacy imports whose temporary contents were already deleted must be reimported. This fix preserves new imports; it cannot recreate deleted media.
