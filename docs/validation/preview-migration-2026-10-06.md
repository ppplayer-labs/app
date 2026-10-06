# Preview fixes migrated to the main app — 2026-10-06

The preview's 38 changed/untracked source files were backed up to
`C:/Users/User/Projects/ppplayer-preview-backup-20261006`, along with its base
commit, status, tracked patch, and SHA-256 checksums. All saved checksums were
verified. The preview checkout remains intact.

## Changes retained

- Native session teardown runs once and finishes before a replacement opens.
- Native startup requires position progress, not just a playing acknowledgement.
  Subsequent seeks update its progress baseline. Backward seeking during startup
  works, while a seek acknowledgement alone cannot conceal stalled playback.
- Local files use precise seeks. Android configures a temporary disk-cache
  directory and falls back to memory caching if directory creation fails.
- System media commands await their playback operations; local tracks do not
  prewarm the background YouTube service.
- Windows plugin builds declare their native-header/download dependencies.
- Chromium/service tests, integration probes, Android host helpers, and a release
  native-video probe now live in the main app. APK verification uses the resolved
  published `flutter_media_kit` manifest and bundled binaries. Its Python verifier
  is included here, requiring no sibling native-media or preview checkout.
- Shell files retain LF line endings. Nested generated build output is ignored.

The main app's current queue/video layout, hosted dependencies, SDK constraint,
and iOS engine selection were preserved.

## Validation

The full app suite passed 373 tests. The subsequently added local-track
prewarming regression passed with all 19 hybrid-engine tests. All 64 nested
playback-engine tests pass, including the startup seek and teardown regressions.
Static analysis reports no issues.

Windows Chromium fixture controls, native local-video fallback, and precise
seeking to 1.25 seconds while paused passed against the real plugins. Android API
35 release playback passed three rounds of decode,
position progress, stable pause, seek, resume, stop, and video surface recreation.
The paused video screenshot was inspected and contains the expected fixture.
Both APK native architectures match the resolved published package checksums;
the runtime log confirms the Android demuxer cache directory was applied.
The self-contained Android host helper also passed with the same APK.

Logs are under `build/preview-migration-*`; Android runtime evidence includes
`preview-migration-android-release.log`, its adjacent screenshot and artifact
verification log, and `preview-migration-android-bundled-verifier.log`.
The Windows precise-seek runtime log is `preview-migration-windows-seek.log`.
The regular Android app was rebuilt in release mode and reinstalled after the
probe. Launch succeeded and opened the system permission prompt; navigation
beyond that prompt was not exercised. Build/install/launch evidence is under
`preview-migration-android-app-*`.
The regular Windows debug app was rebuilt and reopened with a responsive window.
Its startup log is `preview-migration-windows-app-run.log`; named CEF profile
creation and persistent-cache file-lock warnings remain outside this migration.

Linux, macOS, iOS, physical-device audio/battery behavior, and live Android
YouTube/background playback were not rerun in this migration. The migrated
integration tools provide those next checks. Keep the verified backup when
retiring the preview folder.
