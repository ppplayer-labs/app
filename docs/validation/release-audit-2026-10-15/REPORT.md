# Release preparation validation — October 15, 2026

**NOT READY FOR RELEASE.** Source/content preparation is complete for this pass;
Android/macOS engineering gates and final platform/distribution qualification
remain unresolved. No tag, commit, push, release, deployment or store upload was
performed. No fresh final-version platform binary was built in this audit.

## Candidate identity

- App source audited: ac266d5e697b1ca3f8141b50d278bef8c9e1b313 plus the release-preparation changes in this working tree.
- Website source audited: cdd601a75d7d4e80003fef9c4d19a2b880374c61 plus content changes in this working tree.
- Latest published app release from read-only GitHub API: v3.0.2, October 3, 2026, 19:05:35 UTC. App v3.0.3 tag is unpublished; umbrella repository returned no published releases.
- Candidate metadata: 4.0.0+12, MSIX 4.0.0.0. Windows publisher display name Devflier; app display name PPPlayer; package identity and certificate subject unchanged.
- Local Flutter analysis uses the installed SDK (earlier checkpoint identifies Flutter 3.44.8 / Dart 3.12.2). CI requests 3.47.4; a fresh run under that exact CI SDK is still required.

## Fresh checks

| Check | Result | Evidence / scope |
| --- | --- | --- |
| Flutter analysis | PASS, no issues | flutter-analyze.log |
| App + nested playback engine + both vendored Chromium packages | PASS, 622 tests | flutter-tests-summary.log; full stdout captured locally during execution |
| Python packaging/configuration/order regressions | PASS, 4 tests | python-tests.log |
| Frozen Chromium integrity | PASS, 149 hashes | `python3 scripts/verify_chromium_snapshot.py` |
| Website ESLint | PASS | website-lint.log |
| Website TypeScript | PASS | `npx tsc --noEmit`; no diagnostics |
| Website IndexNow suite | PASS, 33 tests | website-tests.log; no live IndexNow submission |
| Website production Webpack build | PASS, page generation and build completed | website-build-webpack.log |
| Local built website HTTP content | PASS, 5 routes | English and pt-BR release guide; Arabic guide English fallback; English downloads and changelog, each HTTP 200 with expected candidate content |
| Website catalogs | PASS, all 38 cover English message keys and placeholders | Candidate macOS/iOS/Android requirements checked; RAM recommendations removed |
| App catalogs | PASS, 38 catalogs / 354 messages / required placeholders | ICU plural category differences preserved; no claim of linguistic review |
| YAML and metadata | PASS | Ruby YAML parser, both workflows; matching app/MSIX versions, Devflier publisher display name, unchanged identity and default-false manual publication opt-in |
| Diff whitespace | PASS | Parent/app/website `git diff --check` |

Test command:

```sh
flutter test --no-pub test \
  lib/core/playback/packages/pp_playback_engine/test \
  third_party/chromium/packages/flutter_chromium_webview/test \
  third_party/chromium/packages/flutter_chromium_webview_platform_interface/test
```

Analysis and tests ran sequentially against the existing resolved candidate
graph. Version/publisher metadata updates do not qualify final installed
artifacts. No resolved dependency upgrades were introduced by this preparation.

## Failed attempts and warnings

- Sandboxed Flutter initially could not write its SDK cache. Retried with approved SDK access; analysis and suites passed.
- Default `npm run build` (Turbopack) did not pass on this host: one attempt failed Google Fonts fetches; the network-enabled retry failed while binding a worker port (Operation not permitted). `npx next build --webpack` subsequently passed. This is not a claimed successful default/Turbopack build; validate the Docker/default build in its deployment environment before deployment. No framework/config migration was made to hide this limitation.
- Successful Webpack build retains middleware deprecation and edge-runtime dependency warnings. These are not compile failures; inspect the build log and validate actual standalone/Docker startup before deployment.
- Initial strict website parity assertion rejected existing extra unused `featureGallery.videoPlaybackTitle/Desc` keys in 19 catalogs. All English keys and placeholders are present. Extra historical keys were retained.
- Initial naive app placeholder matching rejected Arabic plural syntax because it treated plural category text as an argument. Required metadata-based placeholder checks passed; no translations were changed to flatten valid ICU plurals.
- Local HTTP check used the built site's `next start`, not the final Docker/standalone packaging. It does not replace standalone deployment acceptance.

## Remaining qualification

Reproduced Android screen-off failure and macOS unapproved memory/lifecycle
acceptance remain in the historical October 13/14 records. No fresh device run
supersedes those failures. Physical Android ARM64, final signed install/update,
macOS notarization/Gatekeeper, Windows/Linux target-host runtime, iOS final
qualification, real receiver testing and store metadata verification remain open.

See the [audit and ordered plan](../../RELEASE_AUDIT_2026-10-15.md). Publication
requires successful final acceptance and explicit approval for exact artifact
hashes; manual publication opt-in is not itself evidence of acceptance.
