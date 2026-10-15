# Input IPC verification — 2026-10-08

Step 4 is implemented in the local `flutter_chromium_webview` package used by
PPPlayer's absolute path overrides. Shared-memory frame transport is unchanged;
JS bridge IPC and IOSurface optimization remain subsequent milestones.

## Results

- Flutter package: 65 tests passed; platform interface: 18 tests passed.
- Native suite: real CEF page hover, all mouse buttons, double click, focus,
  text input, Shift/Control/Alt/Command, leave, scrolling, resize and DPR,
  concurrently created independent browser IDs, close acknowledgement.
- Native AppKit responder: hardware/virtual key encoding, CEF modifier flags,
  typed characters, IME composition/commit, focus ownership.
- Native IPC client: survives peer death during a burst of input, fails pending
  callbacks, suppresses SIGPIPE, completes partial/interrupted writes.
- Flutter integration: two real texture widgets click/type independently,
  resize reaches CEF, kill of its own host during queued input releases native
  browsers and Flutter continues rendering without an exception.
- App `flutter analyze`: no issues. Excludes archived `refactor_mk_original.dart`
  with obsolete relative imports; removed an unused test import.
- macOS Debug build: see `macos-build.log`.

Concurrent browser creation now binds each CEF browser to its exact IPC session,
preventing browser IDs and textures from swapping. Resize carries the correct
`deviceScaleFactor`, pointer coordinates remain logical, button events preserve
click count, focus loss propagates, and teardown callbacks avoid raw proxy lifetime
captures. Native modifier encoding now matches CEF.

The synthetic integration fixture waits for Chromium's initial compositor
hit-test surface after navigation/layout. A rapid burst also passes after that
surface settles. The tests use isolated HTTP pages and opt into
`CEF_INPUT_TEST_USE_MOCK_KEYCHAIN=1` to avoid requesting real Keychain credentials;
normal app behavior is unchanged.

## Reproduce

From `app`:

```sh
flutter analyze
CEF_INPUT_TEST_USE_MOCK_KEYCHAIN=1 flutter test integration_test/chromium_input_ipc_test.dart -d macos
flutter build macos --debug --no-pub
```

From the local Chromium package:

```sh
flutter test
bash macos/test/run_input_tests.sh
```

Build warnings remain for existing CocoaPods/CEF headers, the always-run CEF
embedding script, and plugins without Swift Package Manager support. Flutter's
test launcher reports foregrounding failure, but launches the app and all
integration assertions pass.
