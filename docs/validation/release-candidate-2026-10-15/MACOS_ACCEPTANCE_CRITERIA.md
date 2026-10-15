# macOS 4.0.0 runtime acceptance protocol

These are prospective engineering criteria, defined before the required full
runs. They are not a retroactive budget pass for old samples or approved product
RAM requirements. Candidate remains macOS 13+ arm64; 8 GB/Intel support needs
separate physical qualification. The current host is Apple Silicon / 16 GB.

## Identity and scope

Use the same versioned Release bundle, lockfile and CEF source hashes for three
repeat runs. Retain hardware/OS/toolchain, resolution/DPR, selected quality,
source/fixture identity and process identities. Use a dedicated test dataset;
never remove or reset the user's library. Record other active apps and builds;
competing builds invalidate CPU/pressure comparisons. The October 15 samples
were collected alongside development/emulator/Docker work and do not qualify as
controlled runs.

Use the retained whole-application collector. The candidate root and all owned
CEF descendants, including reparented known process identities, form one group.
Keep independently deduplicated whole-app and CEF-only footprints separate;
never sum or subtract them. RSS is secondary and not interchangeable with
charged physical footprint. Record process churn and descriptor counts.

## Required workload, each run

1. Cold launch with paused local selection: pre-CEF baseline, 60 seconds idle.
2. Local audio, local 1080p video and direct network stream, each two minutes;
   verify duration/progress, seek, pause/resume and visible output as applicable.
3. Actual YouTube audio/video, fixed 720p then 1080p when available: two minutes
   each, confirm decoded motion rather than artwork or a playing boolean.
4. Ten local→YouTube→local cycles, including player open/close, queue panel,
   resize, fullscreen and one long explicit pause. Capture each cycle after a
   30-second settling interval. Continue a ten-minute settled playback run.
5. Three minimize/restore cycles; OS media keys; network loss/recovery while
   playing and while deliberately paused. Paused recovery must never autoplay.
6. Normal app-menu or Command-Q quit, then repeat a cold launch and Quit with
   zero browsers. Check every tracked root/helper identity within ten seconds.
   A signal/force quit does not count as graceful acceptance.

## Numeric gates (all required, provisional engineering targets)

| Metric | Threshold / measurement |
| --- | --- |
| Whole-app charged footprint | Settled ≤768 MiB; sampled peak ≤1024 MiB at stated 1080p/DPR workload |
| Boundedness | Median cycles 8–10 minus median cycles 2–4 ≤32 MiB; no monotonic growth in both resource counters and charged footprint |
| Owned resources | One intended live online browser; after local transition, zero live online browser proxies/textures after acknowledgement; persistent host cache may remain but must plateau |
| Descriptors/helpers | Post-cycle-10 settled count no more than cycle-2 +10 descriptors; no accumulation of browser/renderer generations |
| CPU | Ten-second samples; idle/explicitly paused median ≤5% of one core, steady 1080p median ≤100% of one core; report GPU separately if available |
| Pressure and swap | No yellow/red memory-pressure interval; swap-used increase ≤128 MiB across a controlled run |
| Playback | At least 90% of wall-clock progress in each steady 30-second interval; no unexplained stall >5 seconds, excluding documented source buffering/network-loss phases |
| Pause | Position drift <0.5 seconds after settled pause, held 30 seconds; no automatic resume |
| Disposal/Quit | All tracked owned processes gone within ten seconds; no forced GC or signal substitute |
| Collector overhead | Paired measurement/control runs; median collector child CPU ≤0.1 core-seconds per sample and ≤5% change in steady CPU/footprint; otherwise measurements inconclusive |

If targets prove inappropriate, document the workload and reasoning and obtain
acceptance of revised criteria before calling the release qualified. Do not
adjust thresholds solely to turn an existing failed sample green. A single
valid snapshot cannot establish peak, plateau, CPU, collector overhead or leaks.

## Current evidence

Historical October 13 Release snapshots were 888.64 and 866.70 MiB whole-app,
with unapproved memory acceptance. October 15 records contain a clean pre-CEF
baseline and separate exploratory playback/idle snapshots. They show a smaller
sampled footprint in a different workload, not a causal improvement or a pass.
Normal Quit originally reproduced a Flutter/CEF retry-handshake defect; a source
fix, native regression and actual Release Quit now pass with zero tracked
survivors. Repeated cycles, long-run/performance and controlled comparisons are
still NOT TESTED.
