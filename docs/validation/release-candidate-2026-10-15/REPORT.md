# PPPlayer 4.0.0 release-readiness matrix — October 15, 2026

**NOT READY.** Candidate remains **4.0.0+12**, MSIX **4.0.0.0**.
No tag, publish, deploy or store upload was performed. This record supersedes
individual gates only where new evidence is explicitly recorded.

Latest Android-only evidence and release-scope proposal: [focused P0 investigation](../android-p0-2026-10-15/REPORT.md). No Android blocker is cleared by that continuation.

## Engineering and distribution

| Gate | Status | Evidence and remaining scope |
| --- | --- | --- |
| Android live Home / screen-off YouTube | FAIL — ACCEPTED LIMITATION (maintainer decision, Oct 15; no code change, not fixed) | `android-extended.log`: Home stalls at 13.309321s, buffering while JS progresses; 90-second screen-off check not reached. Earlier short screen-off interval passed, insufficient for acceptance. |
| Android offline audio lifecycle control | PASS | `android-offline-control.log`: 15s Home and 20s screen-off progress with same WebView/service. Emulator only, no physical audible claim. |
| Android offline video control | PASS | `android-offline-video-retry.log`: confirmed foreground start, Home and 20s screen-off progress with looping inline MP4; initial invalid lifecycle run retained. No general video-pipeline suspension reproduced. Emulator only. |
| Android underlying causal diagnosis | BLOCKED | Narrowed to live media path, not universal timer/process suspension. Need valid local-video/network controls and iframe/native decoder/network traces; no production workaround applied. See ANDROID_INVESTIGATION.md. |
| macOS actual Release build | PASS | Built 422.5 MB, version 4.0.0/build12, arm64/macOS 13. Both original and Quit-fix rebuild succeeded. |
| macOS native file/folder picker imports | PASS | Actual Release native pickers imported Unicode MP3 and nested FLAC folder; resulting rows visible. One-minute WAV imported and selected for local playback. Not a full codec/audio qualification. |
| macOS normal Quit regression | PASS | Reproduced Flutter exit handshake cancellation after CEF shutdown; subsequent terminate request swallowed. Fixed wrapper to forward retries to AppKit. Actual rebuilt Release Command-Q exits; `memory/quit-survivors.json` shows zero tracked survivors. Native production-method regression passes. |
| macOS memory/performance/disposal | BLOCKED | Exploratory whole-app pre-CEF 378.53 MiB; YouTube 764.51 MiB, CEF-only 351.43 MiB. Earlier instance local 500.41 MiB; idle 616.86 MiB. Different workloads/concurrent development prevent trend or peak acceptance. See MACOS_ACCEPTANCE_CRITERIA.md for prospective measurable gates. Ten-cycle/long-run CPU, pressure and overhead remain NOT TESTED. |
| macOS distribution signing | FAIL | Actual bundle Apple Development, no hardened-runtime flag; strict deep signature passes, staple exit65, Gatekeeper exit3. Developer ID identity available locally, not used to sign/upload here. |
| Signing configuration presence | PASS | Required CI secret names exist; local macOS required fields nonempty. Values not exposed, altered or validated. Local Android key.properties absent; release-mode fallback would be debug signing. Presence alone is not usable-credential acceptance. |
| Final signed APK/AAB/macOS install-update | NOT TESTED | Production signing identity, continuity and final artifacts not qualified. No notarization/upload attempted. |
| Physical Android / iOS / Cast-DLNA | NOT TESTED | Hardware-specific audible output, interruptions, OEM/PiP, long pause and receivers remain required. |
| Windows/Linux target-host acceptance | BLOCKED | Current host is macOS; native runtime/install/playback/cleanup must run on target hosts. |

## Compatibility, regressions and website

| Gate | Status | Evidence and limits |
| --- | --- | --- |
| Published 3.0.2 schema compatibility | PASS | Generated Drift schema byte-identical; both versions already schema 14. Frozen SQL fixture, retained rows, candidate write/reopen, playlist duplicates/order, favorites, local paths and streams pass. No new schema migration is implied. |
| Installed-app retained user data | NOT TESTED | Candidate visibly restored existing library/history/settings, installed app identified as 3.0.2+10. No controlled before/after snapshot or signed installed upgrade; do not promote observation to full upgrade qualification. |
| App/engine/Chromium automated suites | PASS | 623 tests passed, including added retained-data regression. Full stdout captured in local validation log; scoped evidence retained with this report. |
| Native Quit / Python guards | PASS | Five Python tests, including Objective-C++ harness executing production terminate methods. macOS CI runs native handshake regression; Linux skips native Cocoa test. |
| Frozen Chromium integrity | PASS | 149 source hashes, reviewed patch provenance retained. |
| Flutter analysis | PASS | Final retry after test-only deprecated API correction; see retained log. |
| Queue/playlists/subtitles/network/local regressions | PASS | Covered by automated suites; full real-device and actual media/source matrix remains NOT TESTED. |
| Version metadata / Windows publisher | PASS | Flutter 4.0.0+12, MSIX 4.0.0.0, publisher display Devflier, app name PPPlayer, identity unchanged. Website package 2.0.1 is independent package metadata. External store build-history check pending. |
| Website default production build | PASS | `npm run build` now explicitly selects Webpack; build succeeds. Original Turbopack failed host worker binding; no claimed Turbopack pass. |
| Website production Docker build | PASS | Actual Dockerfile build, local image ppplayer-website:release-check-4.0.0; no image pushed. |
| Standalone / container startup and content | PASS | Standalone six routes plus static CSS; Docker English/pt-BR guide, downloads, llms-full and revision marker HTTP200. Local container stopped after checks. |
| CI exact Flutter 3.47.4 / all-platform artifacts | NOT TESTED | Local evidence uses installed SDK; workflow execution and final artifacts remain separate. |

## Implemented changes in this follow-up

- Corrected native Chromium application Quit retry handshake, with source-level
  provenance, production-method native regression and actual Release check.
- Strengthened Android lifecycle acceptance to nine screen-off progress intervals
  and sustained system resume; separate cleanup markers cannot count as success.
- Added offline audio/video control fixture and runner with read-only lock preflight.
- Added buffered-fraction/duration diagnostics; no repeated-play/seek stall masking.
- Added released-schema retained-data regression and documented unchanged schema 14.
- Selected Webpack explicitly for the website default production build; verified
  actual Docker/standalone packaging.
- Defined prospective measurable macOS acceptance protocol; no retroactive budget pass.

## Unresolved issues, in priority order

1. **P0 Android (scope decision recorded):** hidden YouTube playback ships as a documented, unfixed limitation by maintainer decision; root cause undetermined. Remaining: physical ARM64 qualification of foreground, local/direct media and explicit-pause behavior; docs must not claim background YouTube.
2. **P0 macOS:** three controlled Release runs against documented memory/CPU,
   playback and ten-cycle disposal criteria. Current snapshots cannot clear this.
3. **P0 distribution:** production signing and hardened runtime, notarization and
   Gatekeeper/install-update acceptance against final hashes; approval before uploads.
4. **P1 upgrades:** controlled installed 3.0.2→4.0.0 retained-data upgrade, including
   Hive queue/settings, bookmarks, originals and missing files; DB fixture is narrower.
5. **P1 platform/device matrix:** real subtitles, playlists, network sources,
   OS controls, source transitions, Windows/Linux/iOS and physical receivers.
6. **P1 final CI/editorial:** exact toolchain checks, store build-history and
   metadata review, final source/artifact hashes and explicit release approval.

Historical failures and interrupted/inconclusive attempts are retained. Automatic
review rejected stopping an unrelated installed app; it was left untouched.
It also rejected adding automatic keyguard dismissal to the control runner;
only read-only lock preflight was added. Controlled testing requires normal unlock.
