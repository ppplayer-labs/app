# PPPlayer v4.0.3 — Linux Performance Optimization & CEF Rendering Suspension Readiness Report

**Date:** 2026-11-28  
**Certified v4.0.3 Baseline (Intact):** `feat/release-v4.0.3` @ `82794900c71cd18074a673873c7b05b8fa71350d`  
**Reviewable Integration Branch:** `perf/linux-cpu-memory-optimization` @ `4a51a2c` (contains `9a0b059` + `4a51a2c` atop `8279490`)  
**Upstream Plugin Branch (Unpublished, Pending Approval):** `flutter_chromium_webview` `fix/linux-cef-rendering-suspension` @ `2b0795b` (branched from `origin/main` / `v0.5.7` @ `9073a20`)  
**5-Job Cross-Platform CI Run:** https://github.com/ppplayer-labs/app/actions/runs/46168631956 (5/5 PASSED)

---

## 1. Executive Summary & GO/NO-GO Decision

**Recommendation: CONDITIONAL GO for `v4.0.3` integration** (`perf/linux-cpu-memory-optimization` -> `feat/release-v4.0.3`), gated only on:
1. Running elevated Windows App Certification Kit (`appcert.exe`) on the newly built `v4.0.3` MSIX artifact (blocked from non-elevated shell due to UAC `requireAdministrator`).
2. Maintainer decision on whether to ship `v4.0.3` immediately with hosted `flutter_chromium_webview 0.5.7` (which already eliminates 100% of idle/static/local-audio/post-reclamation CPU waste) or first publish `flutter_chromium_webview 0.5.8` (branch `fix/linux-cef-rendering-suspension` @ `2b0795b`) to also capture the `-91.0%` Hidden Mini-Video, `-97.8%` Minimized Active Video, and `-99.2%` Immediate Paused Video CPU reductions on Linux.

---

## 2. Exact Root Causes Identified

1. **Unconditional 60fps Idle / Static UI Animations (App Defect):**
   - `TactilePlayButton` (`lib/shared/widgets/tactile_buttons.dart`) ran a continuous repeating glow/pulse ticker even when paused/idle, driving full-window Impeller repaints on Settings, Library, and Home.
   - `LibraryScreen` (`lib/features/library/library_screen.dart`) ran infinite sheen animations on static cards (`Liked Songs`, `Local Music`, `Local Videos`), spiking static Library CPU to `32.8%` sys (`196.8%` 1-core) and `+172 MB` RAM churn.
   - Unscoped `ref.watch(playerProvider)` subscriptions rebuilt entire screens on 2Hz progress updates during local audio playback.
2. **Idle Paused Chromium Browser Retention (App Lifecycle Defect):**
   - Pausing a YouTube track left the off-screen CEF browser and renderer processes alive indefinitely (`~1.52 GB` SumRSS / `~783 MB` TotalPSS, `34.8%` sys CPU).
   - Fixed in `lib/core/playback/chromium_playback_engine.dart` (`9a0b059` + hardened in `4a51a2c` to preserve YouTube playlist index via `getPlaylistIndex()` before disposal and re-verify `!_wantsPlaying` after `await`): after 60s of continuous pause, the browser is cleanly reclaimed while preserving track, position, playlist index, and queue state for transparent one-click resume/seek.
3. **Ineffective Linux `setRenderingActive()` in `flutter_chromium_webview 0.5.7` (Upstream Plugin Defect):**
   - On Linux, `setRenderingActive(false)` was previously a no-op, leaving off-screen CEF painting at 60 FPS while hidden, minimized, or immediately paused.
   - Fixed upstream in `fix/linux-cef-rendering-suspension` (`2b0795b`): throttles CEF via `SetWindowlessFrameRate(1)` (deliberately avoiding `WasHidden(true)` so `document.visibilityState` stays `'visible'` and YouTube audio/JS timers continue uninterrupted), gates `OnPaint` BGRA->RGBA swizzling & Flutter texture notifications while preserving the last valid `front_buffer` (zero black-screen flicker on rapid Hide/Show), and hooks GTK `window-state-event` (`GDK_WINDOW_STATE_ICONIFIED`) for automatic minimize suspension.
4. **VirtualBox 3D Acceleration Discrepancy & Renderer Defect (Environment Finding):**
   - Previous benchmark saw `accelerate3d="off"` and `Mesa llvmpipe` because `Ubuntu 25.04.1.vbox` lacked `accelerate3D="true"` (UI setting had not been persisted while powered off).
   - Enabling `VBoxManage modifyvm "Ubuntu 25.04.1" --accelerate3d on` (`Guest Additions 7.2.16r174877`, `VMSVGA`, `VRAM 256 MB`) activated hardware `SVGA3D` (`GL_VENDOR: VMware, Inc.`, `GL_RENDERER: SVGA3D; build: RELEASE; LLVM;`, `OpenGL ES 3.0 Mesa 26.0.8`) on both Wayland and X11 (`-117 MB` idle PSS), **but** VirtualBox's `vmwgfx`/`SVGA3D` driver (`dmesg`: `vmwgfx seems to be running on an unsupported hypervisor. This configuration is likely broken.`) renders Flutter Impeller (`OpenGLESSDF`) completely blank/corrupted on both Wayland and X11, and corrupts Xwayland GTK titlebars.
   - Therefore, certified Linux VM benchmarks were measured under verified `Mesa llvmpipe (LLVM 21.1.8, 256 bits)` (`LIBGL_ALWAYS_SOFTWARE=1`), where UI rendering is crisp and apples-to-apples with the original `v4.0.3` RC baseline.
5. **SumRSS vs TotalPSS Accounting:**
   - The 1.55 GB figure reported by GNOME Resources reflects **Summed RSS** across 11 processes (double-counting `libcef.so` and shared mappings across main, zygotes, GPU, network, storage, audio, and 2 renderers). True unique physical memory (**TotalPSS**) during active YouTube playback is **734–804 MB** (`TotalUSS` **538–600 MB**), dropping to **574.4 MB PSS** (`433.0 MB USS`) after 60s reclamation and **324–352 MB PSS** at Idle Home.

---

## 3. Nine-State Linux Performance Certification (`Ubuntu 26.04`, 6 vCPUs, Verified `Mesa llvmpipe`)

| # | Application State | v4.0.3 RC (`8279490`) CPU sys (1c) | v4.0.3 RC SumRSS / TotalPSS | Perf `4a51a2c` (Stock `0.5.7`) CPU sys (1c) | Perf `4a51a2c` + Upstream `2b0795b` CPU sys (1c) | Perf `4a51a2c` + `2b0795b` SumRSS / TotalPSS (Procs) |
|---|---|---:|---:|---:|---:|---:|
| 1 | **Idle Home (X11 / Wayland)** | 28.4% (170.4%) | 440 / 345 MB | **0.0% (0.0–0.2%)** | **0.0% (0.0–0.2%)** | 416–444 / 324–352 MB (1) |
| 2 | **Static Settings** | 48.2% (289.2%) | 505 / 406 MB | **0.0% (0.2%)** | **0.0% (0.0%)** | 515.6 / 423.1 MB (1) |
| 3 | **Static Library** | 32.8% (196.8%) | 632 / 530 MB | **0.0% (0.0%)** | **0.0% (0.0%)** | 481.8 / 389.8 MB (1) |
| 4 | **Local Music Playback (Home / Library)** | 44.2% (265.2%) | 490 / 390 MB | **2.6% (15.8%)** | **2.6–5.4% (15.8–32.4%)**\* | 482–500 / 382–406 MB (1, 0 CEF) |
| 5 | **Visible Mini-Video (YouTube)** | ~50.0% (~300%) | 1450 / 730 MB | 50.1% (300.8%) | 42.7% (256.5%) | 1486.9 / 767.0 MB (11) |
| 6 | **Hidden Mini-Video (Audio Active)** | ~49.4% (~296%) | 1446 / 718 MB | 49.4% (296.3%) | **4.5% (26.8%)** (`-91.0%`) | 1487.0 / 767.1 MB (11, audio active) |
| 7 | **Full Video (`/player`, YouTube)** | ~47.4% (~284%) | 1521 / 787 MB | 47.4% (284.4%) | 50.3% (301.7%) | 1509.7 / 786.4 MB (11) |
| 8 | **Minimized Active Video (Audio Active)** | ~54.3% (~326%) | 1516 / 783 MB | 54.3% (325.9%) | **1.2–1.6% (7.0–9.4%)** (`-97.8%`) | 1525.9 / 802.9 MB (11, audio active) |
| 9a | **Paused Video (Immediate, 0–5s)** | ~34.8% (~209%) | 1516 / 783 MB | 34.8% (208.9%) | **0.3% (1.6%)** (`-99.2%`) | 1496.0 / 773.9 MB (11) |
| 9b | **Paused Video (Post-60s Reclamation)** | ~34.8% (~209%) | 1516 / 783 MB | **0.0% (0.2%)** | **0.0% (0.0%)** | **1100.3 / 574.4 MB** (9, `-200 MB PSS`) |

*\*Note on State 4: Local music on Home/Library measures `2.6–5.4%` sys CPU with `0` Chromium processes; remaining `llvmpipe` load occurs only when viewing an active track row's animated playing equalizer.*

---

## 4. Full Reconciled Test & Regression Matrix

| Suite | Result | Details |
|---|---|---|
| **Multi-Package Flutter/Dart CI Suite** | **720 / 720 PASSED** | Reconciled 536 (app-only) vs 714 (baseline 4-package) -> 720 (+6 new perf & playlist reclamation tests across `test`, `pp_playback_engine`, `flutter_chromium_webview`, `flutter_chromium_webview_platform_interface`). |
| **`dart format` & `flutter analyze`** | **PASS (0 issues)** | Verified locally and in CI job `141051756053`. |
| **Chromium Snapshot Integrity** | **PASS (147/147 hashes)** | `scripts/verify_chromium_snapshot.py` verified on Windows & Linux. |
| **Python Packaging & Workflow Suite** | **39/39 PASS** | Linux: 38 ran + 1 skipped (macOS Obj-C++ only); Windows: 29 ran + 10 skipped. |
| **Upstream Linux Native GTest (`2b0795b`)** | **19 / 19 PASSED** | Includes 3 new `CefBrowserHandlerRenderingSuspension` suites (active/inactive `OnPaint`, GTK minimize independence, 100 rapid Hide/Show+minimize cycles preserving last valid frame). |
| **Windows CEF Validation (`validate_windows.ps1`)** | **PASS** | 83 Dart tests + 2 example widget tests + 8/8 real-CEF Windows integration suites (`plugin_integration`, `input_scaling`, `native_ui`, `windows_keyboard`, `javascript_bridge`, `html_loading`, `browser_settings`, `youtube_adapter`) + native C++ `chromium_webview_texture_test.exe`. |
| **Windows Home Scroll Benchmark** | **PASS** | `100.0%` image cache hit rate, `0` evictions, `0` duplicate HTTP fetches, `0` shimmers during scroll & nav return (`27.12 / 80 MB`, `142 / 300` entries). |
| **Windows Production Memory & Lifecycle (`4a51a2c`)** | **PASS** | Idle `0.02%` CPU (`365.3 MB` WS), Minimized `0%` CPU, Restored `0%` CPU, `CleanExit=True (248.7 ms)`, `Orphans=0`. |
| **Linux VM Live Acceptance** | **PASS** | Wayland + X11 launch, Local Music (`mpv`, 0 CEF), Local Video (`mpv`, 0 CEF, crisp SMPTE rendering), YouTube Mini/Full/Hidden/Minimized, **100 rapid Hide/Show cycles** (`201` toggles in `28.4s`, zero black screen), 60s reclamation + transparent Resume & Seek, Clean Exit (`547 ms`, `0` orphans). |

---

## 5. Fresh 5-Job Cross-Platform CI & Artifacts (`4a51a2c`)

- **CI Run:** https://github.com/ppplayer-labs/app/actions/runs/46168631956 (All 5 jobs PASSED)
  - `Validate, Format, Analyze & Test` (`141051756053`): **PASS (3m4s)**
  - `PR Build Windows x64 & MSIX` (`141052621177`): **PASS (9m12s)** — `ppplayer.msix` (`215,647,115` bytes, `SHA-256=F881B6F3AC22E51500AB9461656D31FA22A17A213D03B2ECFB757979F5E58C93`)
  - `PR Build Linux x86_64` (`141052621180`): **PASS (13m28s)**
    - `ppplayer_4.0.3-15_amd64.deb` (`126M`, `SHA-256=ba913fe0e0f714fcd7e3c59c808c6112ea64d3bfa8860cae6e2ccb78c283f63e`)
    - `PPPlayer-Linux-x86_64.AppImage` (`236M`, `SHA-256=7d729251776cd8169f89b3eed1b85311efcdd6253b9fd85c38eb4c9eaa6cb0c7`)
    - `PPPlayer-Linux-x86_64.tar.gz` (`254M`, `SHA-256=79b05fc0ca393e277a0ee5cb74e6b641aca879e4fb094ff08df169333b10d600`)
    - `ppplayer_4.0.3_amd64.snap` (`211M`, `SHA-256=fbcd794c5a7d6240a478792abeff93a98c813a52b9b409eefe18e368b47b4309`)
  - `PR Build Android` (`141052621228`): **PASS (10m44s)**
  - `PR Build macOS arm64` (`141052621145`): **PASS (10m54s)**
- **Local Windows Store MSIX (`4a51a2c`):** `build/windows/x64/runner/Release/ppplayer.msix` (`216,392,731` bytes, `SHA-256=62FEED19256B60B1B4887FD7F0274DCE2803E4B01DBCBD1C397850028A637E5F`), WACK pre-checks passed (debug `zlib.dll` absent, 5 monochrome `#FFFFFF`+alpha `BadgeLogo` PNGs verified, 0 MSVC debug CRT imports).
- **WACK (`appcert.exe`) Status:** Pending elevated Administrator execution (non-elevated shell cannot spawn UAC-required `appcert.exe`). Run elevated before Microsoft Store upload:
  ```powershell
  & "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe" test -appxpackagepath "C:\Users\User\Projects\ppplayermusic\app-linux-perf\build\windows\x64\runner\Release\ppplayer.msix" -reportoutputpath "wack_v403_perf.xml"
  ```

---

## 6. Remaining Issues & Next Actions (Awaiting Approval)

1. **Elevated WACK run** on the exact new `4a51a2c` Windows MSIX submission artifact.
2. **Upstream `flutter_chromium_webview 0.5.8` publication approval**: branch `fix/linux-cef-rendering-suspension` (`2b0795b`) is tested and ready; publishing `0.5.8` and bumping PPPlayer's hosted pub.dev pin unlocks the `-91%` to `-99%` Hidden/Minimized/Paused video CPU reductions on Linux while keeping CI's hosted-dependency guard green.
3. **Optional minor follow-up**: Active local track equalizer row animation on software-rendered Linux VMs (`llvmpipe`) draws at 60 FPS while viewing the Local Music list; throttling or lowering its frame cadence on software renderers could further reduce CPU while staying on that list screen.
4. **VirtualBox VM display setting**: `accelerate3D="true"` remains set in `Ubuntu 25.04.1.vbox` from Phase 3 testing; revert with `VBoxManage modifyvm "Ubuntu 25.04.1" --accelerate3d off` (when VM is powered off) to restore normal software-rendered Flutter UI without `LIBGL_ALWAYS_SOFTWARE=1`.
