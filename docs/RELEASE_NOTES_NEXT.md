# PPPlayer 4.0.1 — draft release notes

Candidate: 4.0.1+13; MSIX 4.0.1.0.
Latest published app release: 4.0.0 (October 15, 2026).

## Compatibility changes

- macOS now requires 13 or later. This candidate is qualified only as far as the
  recorded Apple Silicon checks; Intel/universal and low-memory support remain unqualified.
- Android packages contain ARM64 and x86_64, without 32-bit ARM.
- iOS targets 15 or later and remains unavailable publicly.

## Changes since 3.0.2

- Chromium-based YouTube playback on Android/macOS/Windows/Linux, retaining
  WebKit on iOS and MediaKit for local/direct media. Availability is subject to
  the platform acceptance gates below.
- Redesigned queue with desktop panel/mobile sheet, independent fullscreen
  navigation, draggable desktop width and saved width preference.
- Improved network-playlist parsing (M3U, PLS, XSPF, ASX), HLS detection, IPTV
  groups/headers, relative links, deduplication, bounded downloads and timeouts.
- Local-library query, file-access/relinking, metadata and video probing
  improvements; macOS import entitlement and video-resizing corrections.
- Playback recovery and source-switching regressions, localization and
  native integration coverage, Linux packaging and store-listing tooling.
- Linux packaging now stops on build failure rather than packaging stale output;
  release controls include frozen-source, package tests and explicit publication opt-in.

- Windows MSIX publisher display name is Devflier; application display name remains PPPlayer.

- Fixed macOS normal Quit being swallowed after Chromium cleanup; native regression and actual Release quit passed.

Latest [readiness matrix](validation/release-candidate-2026-10-15/REPORT.md) records new evidence and remaining gates.

## Known limitations / release gates

**Accepted known limitation (maintainer decision, unfixed):** Android YouTube
playback stalls after Home/screen-off in emulator acceptance; the root cause is
undetermined, and YouTube developer policy III.I.9 also disallows hidden
iframe playback. Do not rely on or advertise YouTube background playback on
Android; local/direct media is tested separately. Physical Android audio/lifecycle/PiP, signed install/update,
macOS memory/performance/disposal and notarization, Windows/Linux target-host
acceptance, iOS device/store qualification, and physical Cast/DLNA remain pending.
The Android release-mode artifact at the October 14 checkpoint was debug-signed.
Do not distribute it as a production-signed build.

[Audit and prioritized plan](RELEASE_AUDIT_2026-10-15.md).
[Historical device evidence](validation/pre-release-2026-10-14/REPORT.md).
Build and validate final versioned artifacts before approval; this draft is
not a statement that every platform or listed protocol has passed acceptance.
