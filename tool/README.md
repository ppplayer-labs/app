# Native release playback probe

`native_release_probe.dart` is a separate validation entry point. It uses the
production `MediaKitPlayerAdapter` and a real Flutter `Video` surface, with a local
five-second video fixture. The regular app entry point is unchanged.

The probe requires release mode and uses explicit exceptions instead of Dart
assertions, which are disabled in release. Three rounds require decoded video
dimensions, position progress, a stable paused interval, a successful seek,
progress after resume, stop and surface unmount/remount. Native errors and
cleanup failures fail the run. The host runner additionally rejects the Android
disk-cache failure and captures a paused video frame.

From the main app on Windows, with Flutter and Android platform-tools on PATH:

```powershell
.\scripts\test_native_android_release.ps1 -Device emulator-5554
```

Use `-Device <phone-serial>` for an attached phone with USB debugging enabled.
Use `-NoBuild` to reuse `build/validation/native-release-probe.apk` on another
device. The script verifies both native architectures against the resolved
published `flutter_media_kit` package using Ubuntu WSL before installing. The
verifier is included in `tool/verify_native_apk.py`, so no sibling package
checkout is required. The script preserves any prior
locally built app APK in `build/validation/`, deploys the probe under the normal
app ID, collects logs and stops the test app afterward. It does not reinstall
the regular app automatically. Reinstall the saved APK or rebuild the regular
app after testing. Prefer an emulator for this probe.

`-Log <absolute-path>` selects the main runtime log. Adjacent files retain build,
artifact, install and launch evidence, plus the video screenshot. The APK under
test is the standalone probe; it does not establish release-mode catalog,
Chromium playback or full app navigation. Audible output requires a listening
check on a physical device.
