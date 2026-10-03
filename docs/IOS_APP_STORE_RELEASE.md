# iOS App Store archive checks

Build a new archive after modifying icons; previously created archives retain their original asset catalog.

```bash
flutter build ipa --release --export-method app-store
```

The archive is created at `build/ios/archive/Runner.xcarchive` and the exported IPA at `build/ios/ipa/`. An export failure is separate from a successful archive build: check the signing and provisioning diagnostics before uploading.

## Icon transparency

The `flutter_launcher_icons` configuration in `pubspec.yaml` sets `remove_alpha_ios: true` and `background_color_ios: "#0A0A0A"`. Preserve these settings when regenerating icons. All iOS icon sizes must be opaque; even an otherwise opaque image encoded with an alpha channel can be rejected.

Check the marketing icon before archiving:

```bash
sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
```

Expected: `hasAlpha: no`. Upload the newly created archive, not an older Organizer entry.

## Prebuilt media-framework symbols

`media_kit_libs_ios_video` currently downloads the `media-kit/libmpv-darwin-build` v0.6.0 video-default XCFramework bundle. Its 18 physical-iOS framework slices ship without dSYMs. The supplier's `debug.zip` contains build logs, not DWARF symbol files. The Mpv binary UUID `80555C75-73AD-3589-95F6-777ADA0D8FD4` matches the reported upload warning.

Setting the app's Debug Information Format to DWARF with dSYM does not recreate debug information for these already-built libraries. The binaries reference object files on the supplier's build machine that are absent from the downloaded package. Do not generate empty placeholder dSYMs or substitute symbols from a different build.

To resolve the media symbol warnings completely, obtain the original matching dSYMs from the supplier, or adopt a library build that distributes both its binaries and genuine dSYMs. A rebuilt library has new UUIDs and must be used together with its own matching symbols in a new app archive. Preserve full playback and device validation when replacing the native media libraries.

Before copying supplied dSYMs into an archive, verify the architecture and UUID against each embedded framework:

```bash
xcrun dwarfdump --uuid build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/Mpv.framework/Mpv
xcrun dwarfdump --uuid /path/to/Mpv.framework.dSYM
```

The arm64 UUIDs must match exactly. Keep application/Flutter dSYMs and genuine third-party symbols with the release artifacts so crash reports can be symbolicated. Missing vendor symbols remain a separate limitation even after the icon validation is corrected; a local archive/export success does not prove App Store upload acceptance.

References: [Apple app icons](https://developer.apple.com/design/human-interface-guidelines/app-icons), [Apple debugging information](https://developer.apple.com/documentation/xcode/building-your-app-to-include-debugging-information), [supplier release](https://github.com/media-kit/libmpv-darwin-build/releases/tag/v0.6.0).
