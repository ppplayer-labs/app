# PPPlayer release audit — October 15, 2026

**Verdict: NOT READY.** Documentation and candidate metadata preparation can
proceed; publication requires the unresolved acceptance gates and explicit human
approval. This is a source/history audit with automated checks, not certification
of all codecs, devices, receivers or store listings.

Follow-up engineering/Release evidence is in [current readiness matrix](validation/release-candidate-2026-10-15/REPORT.md). Historical findings below are retained where not superseded.

## 1. Published baseline and comparison

Read-only GitHub API inspection of `ppplayer-labs/app/releases` on October 15
identified **v3.0.2**, published **2026-10-03 19:05:35 UTC**, as the latest published
non-draft, non-prerelease release. Assets: Android APK/AAB, macOS DMG/ZIP,
Windows MSIX and checksums. There is no Linux or iOS artifact in that release.
The umbrella repository returned no published releases. Its latest local tag
v2.0.1 is therefore not the application release baseline.

The app's v3.0.3 tag exists without a corresponding published release. The
previous changelog also included a 3.1.0 entry even though metadata was 3.0.3+11.
Neither entry proves distribution. Existing 3.0.0/3.0.1 entries saying they do not
announce publication are historical notes: GitHub separately confirms those
versions were subsequently published. Do not infer store version parity from
GitHub assets; store state was not queried in this audit.

Comparison: `git -C app diff v3.0.2..ac266d5` spans **27 commits, 494 files,
61,702 insertions and 3,228 deletions**, including vendored sources, generated
localizations, scratch material and validation evidence. Those counts are not
494 independent product changes. [Commit inventory](validation/release-audit-2026-10-15/commits.txt)
and [every changed file](validation/release-audit-2026-10-15/changed-files.txt)
cover the exact pre-preparation source range. Website baseline in umbrella
v2.0.1 is 7235ae8; current website is cdd601a. This parent tag is historical
website context, not proof of deployed website revision.

| Area | Published tag 3.0.2 | Current candidate |
| --- | --- | --- |
| App/build metadata | 3.0.2+10 | Prepared 4.0.0+12; MSIX 4.0.0.0 |
| macOS deployment | 12.0 | 13.0; Apple Silicon candidate, Intel unqualified |
| iOS deployment | 15.0 | 15.0 unchanged; public availability unverified |
| Android ABIs | No app-level ABI filter | Explicit ARM64/x86_64 filter, 32-bit ARM excluded |
| Online playback | Prior embedded-player architecture | Vendored Chromium routes on Android/macOS/Windows/Linux; iOS WebKit |
| Queue | Prior queue/player UI | Panel/sheet, independent navigation, resize and persistence |
| Local library | Schema 14 | Schema 14 unchanged; expanded queries/access/probing and retained-data regression |
| Network playlists | Earlier importer/player | Expanded formats, safety limits, IPTV browsing/error handling |
| Linux | No published artifact | Packaging scripts/workflow; target-host qualification pending |
| Validation | Published assets are historical | Expanded regressions; Android and macOS acceptance still blocked |

## 2. Implemented capability inventory

“Implemented” below means reachable source exists; it does not mean the current
binary is distributed, or every platform has passed runtime acceptance.

### Retained capabilities (do not advertise as all newly added)

| Capability | Source evidence | Limits |
| --- | --- | --- |
| Home, genres, recent history, artist/album/discography views, discovery, artist radio and related content | `lib/features/{home,artist,album,discover,radio}` | Catalog/network availability; Spotify metadata is not Spotify audio playback |
| Search, liked songs/albums, followed artists, local playlists and remote playlist views | `lib/features/{search,library}`, `lib/core/db` | Persistence and catalog credentials/services affect availability |
| Local music/video import, folders, artist/album/genre grouping, metadata/artwork | `lib/features/local_library`, `lib/core/local_library` | Codec support varies; missing original files cannot be recovered |
| Transport, seek, volume, shuffle/repeat/autoplay, playback speed, queue export/navigation | `lib/core/player`, `lib/features/player`, queue/export tests | Capability/source-dependent; live source seek and duration may be unavailable |
| Video, subtitles, audio selection, fit controls, responsive/fullscreen layouts | player widgets and playback engine | Surface/codec/platform dependent; not universal subtitle/codec support |
| Network streams, saved stream playlists, Play On routing | `lib/core/{network_streams,network_outputs}` | Rights/server/receiver compatibility and network permissions required |
| Settings, API credentials, language selection, about/licenses | `lib/features/settings`, `lib/l10n` | 38 app catalogs; coverage checks are not linguistic review |
| System controls, background recovery and platform integrations | media handler and native platform bridges | Intent/lifecycle behavior requires device acceptance; Android failure below |

### Additions, improvements and fixes after 3.0.2

| Change group | Implementation evidence | Qualification |
| --- | --- | --- |
| Chromium online playback, persistent hybrid ownership, platform routing, source transitions | `playback_selection.dart`, `playback_providers.dart`, Chromium/hybrid engines, `third_party/chromium` | Android/macOS/Windows/Linux route to Chromium; iOS remains WebKit. Android uses its native WebView integration; do not call every platform desktop CEF. Source/tests do not qualify all targets. |
| Queue redesign, now-playing/upcoming grouping, desktop panel/mobile sheet; separate queue and fullscreen navigation | `queue_page.dart`, `queue_presentation.dart`, `scaffold_with_nav.dart`, router | Widget/navigation regressions exist; thumbnail opens player without forcing fullscreen. |
| Desktop drag resize, clamped 260–640 width, 360 default, 300 ms debounced Hive persistence | `queue_presentation.dart`, queue resize tests | Storage failure is tolerated; last rapid drag may not persist before disposal. |
| M3U/PLS/XSPF/ASX parsing, HLS classification, BOM/CRLF, relative URLs, alternative locations, duplicate channels, IPTV metadata/headers | `playlist_parser.dart`, parser tests | Parser coverage does not establish every provider/codec/DRM source works. |
| Network fetch timeouts/size limits, cancellation, direct media detection and pipe-header parsing | parser and `network_stream_service.dart`, matching tests | Reachability/authentication/content remain external constraints. |
| Stream playlist group/search/browsing and error/loading handling | `stream_playlist_detail_screen.dart`, stream dialog, player provider | Requires a valid accessible source; no promise of licensed subscription/DRM playback. |
| Local file access, probing, relinking and retained-data compatibility | local library services/resolver, unchanged released schema 14, DB tests | Upgrade acceptance needs real retained user data, not only clean install. |
| Apple metadata/native access and macOS file-picker entitlements | local-library native adapters, Runner entitlement files | Post-fix final Release import check remains a gate in earlier evidence. |
| Playback recovery, explicit pause intent, engine ownership/cleanup, local/online transitions | player/hybrid/media handlers, playback-engine suites | Android screen-off failure remains; no blanket background fix claim. |
| macOS video surface resizing and native IPC/texture regressions | vendored host/texture bridge, phase 3 evidence | Visible blank-video fix observed; memory/performance/disposal not approved. |
| Windows video behind controls and Windows/Linux CMake/provider setup | platform runner/CMake and playback views | No current target-host final install/playback pass. |
| Linux AppImage/.deb/tar packaging, desktop ID, stop-on-build-failure guard | `packaging/linux/scripts/build_linux.sh`, release workflow, packaging tests | Packaging implementation, not a released Linux support guarantee. |
| Localization expansion, generated catalogs and store-listing builder | `lib/l10n`, store-listing tool, localization scripts | Human translation and store editorial review pending. |
| Android visibility propagation, missing Cupertino font, CI formatting and frozen-source guards | Android WebView plugin, pubspec, workflow, hash manifest | Visibility patch insufficient for screen-off; font/format/source checks are narrower successes. |
| Portable lifecycle runner and production engine fixture | `scripts/test_chromium_android.py`, integration tests | October 14 foreground passes do not clear lifecycle acceptance. |

Existing iOS durable imports, AirPlay active-route display, macOS system output
shortcut, local artwork correction, security-scoped serving leases and system
pause bridges were documented before 3.0.2. They remain important inventory
items but should not be represented wholesale as new post-3.0.2 features.
Physical iPhone-to-Mac AirPlay checks are historical, not current all-device
qualification. Cast/DLNA have source/fake-receiver coverage; real receivers,
format compatibility and iOS multicast approval remain pending. No transcoding
or YouTube Cast/DLNA URL handoff is promised.

## 3. Documentation and public-content discrepancies

| Priority | Finding | Preparation action / remaining work |
| --- | --- | --- |
| P0 | README Linux “distributed/tested Ubuntu 26.04” exceeded evidence | Replaced with experimental candidate packaging and explicit pending acceptance |
| P0 | System requirements claimed macOS 10.15/universal, iOS 13, ARM32 and old sizes as confirmed | Replaced with configuration/evidence matrix; removed unsupported RAM/size promises |
| P0 | Website localized requirements said Catalina/universal, iOS 14 and Android ARM32 | Candidate requirements aligned across catalogs; published downloads remain separately identified |
| P0 | Changelog 3.1.0 “all platforms Chromium” contradicted iOS WebKit and unpublished metadata | Consolidated unpublished scope, corrected platform exception and publication status |
| P0 | Workflow could publish on main push/version change or manual build | Publication now requires explicit manual boolean opt-in; no trigger run in this audit |
| P1 | Website changelog stopped at 2.0.1; “1.0 available” badge stale | Published history link and candidate status guide added; 1.0 badge removed |
| P1 | Upcoming local/AirPlay copy omitted newer queue/stream work and blockers | Added release-status guide linked from homepage/changelog/download area and machine-readable summary |
| P1 | `llms.txt` claimed public iOS TestFlight availability despite no verified URL | Removed claim and linked published/candidate status |
| P1 | Android guide described expected background behavior without leading with reproduced failure | Playback guide now explicitly labels failure |
| P1 | Parent workflow referenced old `ppplayermusic/app` organization | Corrected source to `ppplayer-labs/app` |
| P1 | Historical architecture, old release notes, blog install instructions and store copy can be mistaken for current support | Historical records retained; current audit/requirements/status guide takes precedence. Review archived guides and all store listings before submission. |
| P2 | Website package version 2.0.1 can be mistaken for app version | Documented as independent website package metadata; not a public release source |
| P2 | Translation parity may conceal inaccurate/unreviewed prose | Structural/numeric updates do not certify linguistic accuracy; native-language editorial review remains |

Public website deployment and store content were not changed remotely. Old
published changelog entries and old downloadable binaries are historical assets;
do not silently label them 4.0.0. No production listing verification, privacy
policy legal review, or exhaustive dependency-license audit was performed here.
Before submission, reconcile analytics/advertising descriptions against native
SDK configuration and actual data handling; a package's presence alone does
not prove collection is enabled.

The Windows MSIX publisher display name is prepared as **Devflier**, per the
release-preparation request. Application display name remains PPPlayer and
package identity/certificate subject are unchanged. Partner Center and generated
manifest verification remain Windows distribution gates.

## 4. Version recommendation

Recommend **4.0.0**, build **12**, MSIX **4.0.0.0**. A minor bump would cover
queue/playlist additions, but this candidate also raises macOS 12→13 and removes
32-bit Android packaging while replacing core online playback. Treating these
compatibility reductions as a major release is the conservative choice.
The pre-existing v3.0.3 tag must not be moved/reused. Metadata is staged now;
release date stays unassigned. Build 12 exceeds repo build 11; confirm external
store build history before upload and increment again if it has already been used.
If older macOS/Android compatibility is restored and independently qualified,
reassess a minor version before publishing; that restoration is outside this audit.

## 5. Bugs, limitations and release blockers

- **P0 Android:** reproducible screen-off YouTube stall around 13 seconds in
  API 36 emulator evidence; background system pause/play was not reached.
  Physical ARM64 audible/lifecycle/PiP/OEM testing is pending. Foreground and
  short buffered progress must not be counted as background acceptance.
- **P0 macOS:** phase 3 explicitly records failed/unapproved memory acceptance.
  Controlled whole-app memory, CPU, pressure and repeated disposal runs remain;
  no low-memory or Intel support claim. Native import correction needs final
  rebuilt-artifact verification.
- **P0 distribution:** prior Android release-mode artifact is debug-signed;
  production keys, final AAB/APK install/update and store acceptance unresolved.
  macOS hardened signing/notarization/Gatekeeper and fresh install unresolved.
- **P1 Windows/Linux:** current architecture-matched native runtime, actual
  playback, controls, cleanup and signed/packaged install/update require target
  hosts; CMake/scripts/unit tests do not establish runtime support.
- **P1 iOS:** deployment 15+, no verified public listing; final physical device,
  interruptions/background/long pause and App Store qualification pending.
- **P1 receivers:** physical Cast/DLNA and unavailable-device/network scenarios
  pending; source formats, local network authorization and iOS multicast matter.
- **P1 upgrades:** verify schema 14 against user libraries from the released
  app, missing originals, imported media, saved playlists and restart behavior.
- **P2 coverage:** catalog/service availability, translation quality, final
  codec/subtitle matrix, accessibility and approved performance criteria remain
  broader acceptance work, not inferred passes from automated suite counts.

## 6. Prioritized preparation plan

1. **P0 — hold publication.** Keep candidate notes unreleased; use manual
   publication opt-in only after validation and explicit approval. Confirm store
   build/version history and attach exact candidate SHA/lockfile/toolchain identity.
2. **P0 — fix or explicitly remove unsupported release scope.** Resolve Android
   screen-off and macOS memory/lifecycle failures with targeted regressions and
   live Release acceptance. Do not mask failures with optimistic feature copy.
   Platform exclusion requires packaging/workflow/content agreement.
3. **P1 — qualify code and upgrades.** Run app/engine/vendored suites, analysis,
   hash integrity, Python guards and localization checks. Exercise real upgrades
   from 3.0.2 with retained data and repeated source-switch/disposal cycles.
4. **P1 — final platform builds.** Use release CI's exact SDK on target hosts;
   verify merged OS/ABI constraints, signed identities, assets, hashes, fresh
   install/update, audible playback, controls, Home/lock/PiP, network recovery and
   long explicit pause. Include macOS hardened signing/notarization and Windows
   MSIX. Keep iOS and Linux experimental until their gates pass.
5. **P1 — editorial alignment.** Review current README, changelog, requirements,
   native/playback/network guides, website status and all 38 catalogs; update
   screenshots and store listings with the actual qualified platform scope.
   Keep privacy, codec, receiver and offline claims evidence-based.
6. **P1 — distribution review.** Confirm runtime/native licenses and notices,
   store policy declarations, signing secrets and version consistency; build
   checksums over all final artifacts and verify release asset links.
7. **Final gate — approval.** Record artifact hashes, checks, residual issues
   and explicit approval against that exact candidate. Only then assign the
   date, promote notes, tag/publish/upload/deploy. None of these publication
   actions were authorized or executed during this audit.

Fresh automated results for this preparation are recorded in
[validation report](validation/release-audit-2026-10-15/REPORT.md). Older
October 13/14 records remain historical evidence and retain their failures.
