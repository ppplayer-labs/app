# PPPlayer Android Setup Guide

This guide will help you run the PPPlayer application on an Android emulator using Flutter and ADB.

## Prerequisites

1.  **Flutter SDK** installed and added to your PATH.
2.  **Android Studio** installed (to provide the Android SDK and emulators).
3.  **ADB (Android Debug Bridge)** available in your PATH.

## Running the App

Run the commands below from the `app` directory. Use the device ID returned by
`flutter devices`; the configured local emulator is `Medium_Phone_API_36.1`.

## Manual Launch (ADB & Flutter CLI)

If you prefer to run things manually or need more control over the process, you can use the standard Flutter and ADB commands.

### 1. List Available Emulators
Find out which emulators you have configured on your machine:
```bash
flutter emulators
```

### 2. Launch an Emulator
Launch an emulator from the list by its ID:
```bash
flutter emulators --launch <emulator_id>
```
*Example: `flutter emulators --launch Medium_Phone_API_36.1`*

### 3. Run the App
Once the emulator is running (you can verify with `flutter devices`), run the app:
```bash
flutter run
```
If you have multiple devices connected (e.g., an iOS simulator and an Android emulator), specify the Android device:
```bash
flutter run -d emulator-5554
```

## Playback acceptance before release

The Android candidate supports ARM64 and x64. YouTube uses a single Android
Chromium WebView; local files and direct streams use MediaKit. AudioService
owns system media controls. The Chromium support service does not create a
second player. Minimizing or locking the screen should preserve playback;
explicit pause must stay paused until the user requests play.

Run live playback, Home, screen-off, system pause/play and three local-video /
YouTube source-switch cycles with Python 3:

```bash
python3 scripts/test_chromium_android.py --device emulator-5554
```

The existing PowerShell equivalent is `scripts/test_chromium_android.ps1`.
These tests install a test host under the normal app ID, so use an emulator or
test device. Reinstall the regular app afterward with `flutter run`.
When switching from integration tests to a release build, use
`flutter build apk --release --target-platform android-arm64,android-x64`
with plugin regeneration enabled (omit `--no-pub`). The local Flutter SDK can
otherwise leave the integration-only plugin in the release Java registry.
Logs default to `build/validation/chromium-android-live.log`; `--log` chooses
another path. The runner fails on a missing lifecycle phase and restores the
activity after background testing. Secure test devices require a manual unlock
after the screen-on phase. Emulator success does not establish audible
output, OEM battery behavior, headset/Bluetooth handling or physical ARM64
acceptance. See the [current validation report](docs/validation/pre-release-2026-10-14/REPORT.md).

## Troubleshooting

### "Activity class does not exist" Error
If you ever manually install the APK and try to run it via `adb shell am start`, you must use the fully qualified class name for the MainActivity since we explicitly defined it in the `AndroidManifest.xml` to prevent intent resolution errors:

```bash
# Correct way to manually start the app via ADB
adb -s emulator-5554 shell am start -n com.ppplayer.app/com.ppplayer.app.MainActivity
```

### Stuck on "Installing build/app/outputs/flutter-apk/app-debug.apk..."
Sometimes Flutter gets stuck waiting for the emulator to respond. If this happens:
1. Press `Ctrl + C` to stop the current `flutter run` process.
2. Force stop the app on the emulator:
   ```bash
   adb shell am force-stop com.ppplayer.app
   ```
3. Run `flutter run` again.

### Clearing App Data
If the app gets into a bad state or a database migration fails, you can clear the app's data:
```bash
adb shell pm clear com.ppplayer.app
```
