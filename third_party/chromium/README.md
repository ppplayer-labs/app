# Frozen PPPlayer Chromium candidate

This repository-relative source snapshot contains 149 upstream-tracked package
files from flutter_chromium_webview HEAD
`0dff55e50b7e4820369b2188a1f2dd2536ab414e`, including the working-tree changes
recorded in `docs/validation/phase1-2026-10-13/baseline.json`.
Example applications, generated output, runtime binaries and unrelated tools
are excluded. LICENSE files are retained. SOURCE_MANIFEST.json hashes every
included source file; run `python3 scripts/verify_chromium_snapshot.py`.

Package version: 0.5.2; platform interface: 0.1.5. This is a patched source
snapshot, **not** the unmodified upstream v0.5.2 release. The retained local Dart
floor is 3.12 (upstream v0.5.2 requires 3.13). The candidate resolves on Flutter
3.44.8 / Dart 3.12.2; CI's Flutter 3.47.4 is not executed in Phase 1.
Local YouTube quality diagnostics and macOS resource-lifetime patches are
preserved. This snapshot does not certify macOS memory or native distribution.
macOS CEF preparation pins version 149.0.4 and archive SHA-256 values; runtime
binaries still require download/build and are not vendored.

## Local package development

Create an untracked `pubspec_overrides.yaml` in the app root:

```yaml
dependency_overrides:
  flutter_chromium_webview:
    path: /your/checkout/packages/flutter_chromium_webview
  flutter_chromium_webview_platform_interface:
    path: /your/checkout/packages/flutter_chromium_webview_platform_interface
```

Run pub get for development. Remove the override before candidate validation,
then run `flutter pub get --offline --enforce-lockfile` against the candidate
lockfile. Keep development lockfile changes separate and review them; do not
publish a graph resolved through an override. The application lockfile must be
included when this candidate is eventually committed. No commit is made here.
To update the frozen snapshot, explicitly review the upstream diff and patches,
replace source files and regenerate hashes; package version alone is not its
identity.

## Phase 2 Android patch

The snapshot now includes optional host-coordinated crash recovery in both Dart
controllers and its regression test. Android opts out of independent native/page
recreation so PPPlayer owns generations and cleanup. Other platforms keep the
previous default automatic recovery behavior. `candidate_patches` in the source
manifest records previous hashes; this remains a patched snapshot, not a newly
published package. Chromium is the intended default desktop engine; memory and
platform certification remain separate gates.

## Phase 3 macOS resize patch

The host now releases cached destination Metal textures whenever it replaces
its IOSurface ring. The cache previously retained the old surfaces after resize,
so accelerated paints could succeed while Flutter displayed empty new surfaces.
The source manifest records the previous host hash. This fix requires runtime
verification across player expansion, collapse and window resizing; it does not
change macOS memory budgets or certify distribution.

## October 14 Android background patch

Autoplay WebViews retain Chromium's visible-window state when their Activity is
minimized, preventing that window transition from suspending embedded playback.
Ordinary browsing WebViews keep Android's visibility behavior. The manifest
records the previous source hash and the patch; the existing foreground service
and single-player ownership remain in use. Runtime acceptance and physical
device coverage are recorded in `docs/validation/pre-release-2026-10-14/REPORT.md`.
