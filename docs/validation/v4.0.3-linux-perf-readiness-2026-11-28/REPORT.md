# PPPlayer v4.0.3 — Final Performance Integration & Hosted `flutter_chromium_webview 0.5.8` Certification Report

**Date:** 2026-11-28  
**Certified v4.0.3 Baseline (Intact):** `feat/release-v4.0.3` @ `82794900c71cd18074a673873c7b05b8fa71350d`  
**Reviewable Integration Branch:** `perf/linux-cpu-memory-optimization` (code commit `f9b59cd3ef3065badb4ea300fbe1eef20b4723ba` atop intact `8279490`)  
**Published Upstream Plugin (`pub.dev` Live):** `flutter_chromium_webview 0.5.8` (`devflier/flutter_chromium_webview` `main` @ `5e704e599b77e0533a2dfcdcf2af58c5e8628d61`, tag `v0.5.8`, PR #16)  
**Plugin Release Workflow (OIDC Publish):** https://github.com/devflier/flutter_chromium_webview/actions/runs/46180535309 (**9 / 9 PASSED**)  
**PPPlayer 5-Job Cross-Platform CI (`f9b59cd`, Hosted `0.5.8`):** https://github.com/ppplayer-labs/app/actions/runs/46183294781 (**5 / 5 PASSED**)

---

## 1. Stage 1 — `flutter_chromium_webview 0.5.8` Publication Verification

- Merged PR #16 (`fix/linux-cef-rendering-suspension` @ `e14a703`) to `devflier/flutter_chromium_webview` `main` (`5e704e599b77e0533a2dfcdcf2af58c5e8628d61`) after PR check run `46177923392` passed 7/7.
- Tagged `v0.5.8` on `5e704e599b77e0533a2dfcdcf2af58c5e8628d61` and completed automated OIDC release workflow `46180535309` (**9/9 jobs passed**: interface, quality, public dependency readiness, Linux, Windows, Android, macOS memory, macOS lifecycle, and `Publish main package`).
- Confirmed publicly live on `https://pub.dev/api/packages/flutter_chromium_webview`: `latest: 0.5.8` (published `2026-11-28T19:45:47Z`), resolving cleanly from `/hosted/pub.dev/flutter_chromium_webview-0.5.8` on Windows, Linux VM, and GitHub Actions CI.

---

## 2. Stage 2 — PPPlayer `v4.0.3` Hosted `0.5.8` Integration (`f9b59cd`)

- Updated `pubspec.yaml` (`^0.5.8`), `pubspec.lock`, `.github/workflows/pr-validation.yml` (`flutter_chromium_webview-0.5.8`), `README.md`, `CHANGELOG.md`, and refreshed `third_party/chromium` + `SOURCE_MANIFEST.json` (`upstream_head = 5e704e599b77e0533a2dfcdcf2af58c5e8628d61`, `147/147` canonical SHA-256 hashes verified).
- Preserved all previously validated Flutter performance optimizations (`9a0b059` + `4a51a2c`): zero-CPU idle Home/Settings/Library, scoped `playerProvider` rebuilds, preserved 80 MB / 300-entry Home artwork cache, and 60-second idle paused Chromium browser reclamation preserving track, position, and YouTube playlist index.
- **Local & CI Verification (`f9b59cd`):**
  - Multi-package Flutter/Dart test suite: **720 / 720 PASSED** (`test`, `pp_playback_engine`, `flutter_chromium_webview`, `flutter_chromium_webview_platform_interface`)
  - `dart format --language-version=3.8` & `flutter analyze`: **PASS (0 issues)**
  - `scripts/verify_chromium_snapshot.py`: **PASS (147 / 147 hashes)**
  - Python packaging & workflow guards: **39 / 39 PASS** (Linux VM: 38 ran, 1 macOS Obj-C++ skipped; Windows: 29 ran, 10 skipped)
  - Published `0.5.8` native Linux GTest (`flutter_chromium_webview_plugin_test`): **19 / 19 PASSED**
  - **5-Job Cross-Platform CI (`46183294781`) — 5 / 5 PASSED:**
    - `Validate, Format, Analyze & Test` (`141097501175`): **PASS (3m 9s)**
    - `PR Build Windows x64 & MSIX` (`141098322123`): **PASS (9m 11s)**
    - `PR Build Linux x86_64` (`141098322138`): **PASS (11m 0s)**
    - `PR Build Android` (`141098322116`): **PASS (6m 33s)**
    - `PR Build macOS arm64` (`141098322105`): **PASS (11m 4s)**

---

## 3. Stage 3 — Final Native Certification (Hosted `0.5.8`)

### A. Linux 9-State Performance Certification (Restored 3D-Off VM, Native `Mesa llvmpipe (LLVM 21.1.8, 256 bits)`, 6 vCPUs)

> **Hardware Caveat:** All VM benchmarks reflect software-rendered `llvmpipe` CPU overhead (`accelerate3d="off"`, `<Display controller="VMSVGA" VRAMSize="256"/>`) and are **not representative of a physical hardware-accelerated Linux GPU**.

| # | State | v4.0.3 RC (`8279490`, `0.5.7`) CPU sys (1c) | v4.0.3 RC SumRSS / TotalPSS | Final Hosted `0.5.8` (`f9b59cd`) CPU sys (1c) | Final Hosted `0.5.8` SumRSS / TotalPSS / TotalUSS (Procs) |
|---|---|---:|---:|---:|---:|
| 0 | **Wayland Idle Home** | 28.4% (170.4%) | 440 / 345 MB | **0.0% (0.0%)** | 425.7 / 331.0 / 299.9 MB (1) |
| 1 | **X11 Idle Home** | 28.4% (170.4%) | 440 / 345 MB | **0.0% (0.2%)** | 445.1 / 350.4 / 322.3 MB (1) |
| 2 | **Static Settings** | 48.2% (289.2%) | 505 / 406 MB | **0.0% (0.0%)** | 443.4 / 348.7 / 320.6 MB (1) |
| 3 | **Static Library** | 32.8% (196.8%) | 632 / 530 MB | **0.0% (0.0%)** | 447.9 / 353.2 / 325.1 MB (1) |
| 4 | **Local Music Playback (Home)** | 44.2% (265.2%) | 490 / 390 MB | **9.6% (57.6%)** *(0 CEF, `mpv` active)* | 471.4 / 375.3 / 346.8 MB (1) |
| 4b | **Local Video Playback (MediaKit)** | — | — | 41.5% (249.2%) *(0 CEF, `mpv` active)* | 535.4 / 439.3 / 410.8 MB (1) |
| 5 | **Visible Mini-Video (YouTube)** | ~50.0% (~300%) | 1450 / 730 MB | 42.5% (254.9%) | 1539.3 / 759.0 / 553.0 MB (12) |
| 6 | **Hidden Mini-Video (Audio Active)** | ~49.4% (~296%) | 1446 / 718 MB | **5.5% (33.2%)** (`-88.8%`) | 1468.2 / 750.5 / 544.3 MB (11, audio active) |
| 7 | **Full Video (`/player`)** | ~47.4% (~284%) | 1521 / 787 MB | 48.4% (290.3%) | 1477.5 / 758.0 / 551.0 MB (11) |
| 8 | **Minimized Active Video (Audio Active)** | ~54.3% (~326%) | 1516 / 783 MB | **1.7% (10.2%)** (`-96.9%`; **1.0% / 5.8% 1c** at 66 s soak) | 1484.2 / 761.6 / 552.0 MB (11, audio active) |
| 9a | **Paused Video (Immediate 0–5 s)** | ~34.8% (~209%) | 1516 / 783 MB | **0.3% (1.6%)** (`-99.2%`) | 1496.0 / 773.9 / 572.5 MB (11) |
| 9b | **Paused Video (Post-60 s Reclamation)** | ~34.8% (~209%) | 1516 / 783 MB | **0.0% (0.0%)** | **1100.3 / 574.4 / 433.0 MB** (9, `-200 MB PSS`) |

- **100 Rapid Mini-Video Hide/Show Cycles (`201` toggles in `24.7 s`, hosted `0.5.8`):** PASS, `procs=11`, `Chromium` audio active, zero crashes/black screens.
- **Active Minimized 66 s Soak:** `1.0%` sys CPU (`5.8%` 1c), audio uninterrupted, active playing browser never reclaimed.
- **Clean Shutdown:** `303 ms`, `0` orphaned processes.

### B. Windows Final Certification (`f9b59cd`, Hosted `0.5.8`)

- **Windows Production Memory & Lifecycle Benchmark (`Release/ppplayer.exe`):** `startup_t2s` `354.4 MB` WS (`1.29%` CPU), `idle_steady` `354.2 MB` WS (**`0%` CPU**), `minimized` `354.2 MB` WS (`0.02%` CPU), `restored` `354.5 MB` WS (`0.02%` CPU), **`CleanExit=True (207.4 ms)`**, **`Orphans=0`**.
- **Real Windows CEF Cross-Restart Persistence & `setRenderingActive` Verification (`tool/windows_persistence_verify.dart`):** PASS — `HttpOnly`/JS cookies & `localStorage` persisted across browser disposal and full OS process restart (`ppplayer_youtube_session`), incognito (`profileName: null`) isolated, real YouTube playback paused/resumed cleanly across `setRenderingActive(false/true)` (`1.97 s → 5.29 s`), `0` orphans.
- **Windows CEF Integration Matrix (`validate_windows.ps1` in plugin CI `46180535309`):** 8/8 integration suites + `chromium_webview_texture_test.exe` + Release bundle smoke PASSED.
- **Home Scroll & Artwork Cache (`tool/home_scroll_benchmark.dart`):** `100.0%` hit rate, `0` evictions, `0` duplicate HTTP fetches, `0` shimmers (`27.12 / 80 MB`, `142 / 300` entries).

---

## 4. Exact Final Artifact SHA-256 Hashes & Identity (`f9b59cd`)

- **Windows MSIX Identity (`AppxManifest.xml`):** `Identity Name="LucasVeneno.25880C6F60D2E"`, `Version="4.0.3.0"`, `Publisher="CN=191B0E6A-B98A-4AB5-B2FC-9EBDA47DA56E"`, `ProcessorArchitecture="x64"`, `DisplayName="PPPlayer"`, `PublisherDisplayName="Devflier"`.
- **Local Partner Center Store MSIX (`build/windows/x64/runner/Release/ppplayer.msix`):** `215,653,680` bytes — `SHA-256 = A7DDE10FD7E6C3A327566FCE4E3369ECC39ADE30EECFAF5CA4BCDC6C89A62076` (0 MSVC debug CRT imports, `zlib.dll` absent, 5 monochrome `#FFFFFF`+alpha `BadgeLogo` PNGs verified).
- **CI Run `46183294781` Artifacts:**
  - `ppplayer.msix` (`215,647,092` B): `CA639F6BCBEA6F77C3AB50AD7A15120DC3C22B99B963DDDD8A76215C399B60F9`
  - `ppplayer_4.0.3-15_amd64.deb`: `5f684acce5503de80aaa29c30c5dda24ded7121ea4facd205822fd21aa108be1`
  - `PPPlayer-Linux-x86_64.AppImage`: `8fafa3458fecdb29c18784840f5c3774e8d7a12444a3ac21136c46cc8acbfcd3`
  - `PPPlayer-Linux-x86_64.tar.gz`: `5dcb65cfd5e7a1212d0eb28f3560e4c9c803bfeb87baf34ff3c31e28d44e161a`
  - `ppplayer_4.0.3_amd64.snap`: `e5267e69bfa0eefab6ee441896723d1b395bdb77afb913093359ebf6558cb706`
  - `app-release.apk`: `cd0b682708e6e56d214227c86e2a8d87b964e42b62a0e70e7331add927f044b3`
  - `app-release.aab`: `667523f289164932d768ed5739ead497de9a012412ce542c2d979f903a819f99`

---

## 5. Final WACK & Release-Readiness Verdicts

| Target | Verdict | Notes |
|---|---|---|
| **`flutter_chromium_webview 0.5.8`** | **PUBLISHED & VERIFIED** | Live on `pub.dev` (`0.5.8`), 9/9 OIDC release CI (`46180535309`), verified in PPPlayer CI & Linux/Windows native runs. |
| **PPPlayer `v4.0.3` Integration (`perf/linux-cpu-memory-optimization` → `feat/release-v4.0.3`)** | **READY FOR MERGE APPROVAL** | `f9b59cd` passes 720/720 tests, 147/147 snapshot hashes, 39/39 Python tests, 5/5 cross-platform CI (`46183294781`), and full Linux/Windows native certification; certified baseline `8279490` remains intact. |
| **Microsoft Store (WACK)** | **PENDING ELEVATED WACK EXECUTION** | Exact final Partner Center MSIX (`SHA-256 = A7DDE10FD7E6C3A327566FCE4E3369ECC39ADE30EECFAF5CA4BCDC6C89A62076`) is built and passed all automated WACK pre-checks; non-elevated agent shell cannot invoke UAC `appcert.exe`. Run `run_wack_elevated.ps1` in an Administrator PowerShell to record final WACK PASS. |
| **GitHub Release (`v4.0.3`)** | **HOLD PENDING APPROVAL** | Ready after `feat/release-v4.0.3` integration merge approval and elevated WACK pass. |
| **Snap Store** | **HOLD PENDING APPROVAL** | `ppplayer_4.0.3_amd64.snap` (`SHA-256 = e5267e69...`) verified in CI; awaiting explicit publication approval. |
| **Website** | **HOLD PENDING APPROVAL** | Held until `v4.0.3` GitHub Release is published and website deployment is explicitly authorized. |
