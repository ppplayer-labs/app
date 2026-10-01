# iOS Notification Center playback trials — 2026-09-30

Physical device: iPhone, iOS 26.6.2. Profile builds of com.ppplayer.app, version 2.0.3+6.

## Result

The brief audible pause when dismissing Notification Center remains. The user confirmed background playback works in the final build and asked to accept the small pause if this last trial did not resolve it. No further experiments are planned for this issue.

## Trials

1. Confirm iOS renderer pauses before recovery, coalesce duplicate callbacks, and preserve user intent: user reported the brief pause remained.
2. Remove the secondary audio keepalive on iOS: background playback regressed when minimizing or locking. This experiment was fully reverted.
3. Restore the original keepalive and recognize numeric WKWebView player-state results such as `2.0`: user confirmed background playback recovered; the brief pause remained.
4. Retain the keepalive, suppress the unused iOS 100 ms VideoState messages, and serialize iOS position polls. Reuse matching duration metadata only for explicitly on-demand tracks; live/unknown tracks keep querying duration. User confirmed the brief pause remained and background playback worked.

## Final implementation

- iOS unexpected-pause recovery queries current renderer state before issuing play, skips stale callbacks, and cancels when intent or track changes. It avoids resetting volume for this recovery path.
- JavaScript player-state results are compared numerically.
- iOS polling avoids duplicate VideoState messages and overlapping position queries.
- The original audio keepalive remains. Existing audio-session category/options are preserved; native interruption and route diagnostics were added.

Lifecycle excerpts show return transitions without a corresponding paused renderer state or replay command. These logs do not measure audio buffers or prove an IPC or WebKit underrun cause.

## Validation

- Flutter analysis of playback and main: passed.
- iPhone profile build and install: passed.
- Targeted recovery/polling/non-iOS tests: 16 passed.
- Full playback-engine file: 44 passed; two older failures reproduced on the untouched original package at app HEAD `358d977b2a6fcb157d3882e7d601660f9688e482` (acknowledged-pause replay credit and pending-pause reconciliation).
- JavaScript harness: state messages and keepalive preserved on iOS/Android/macOS/web; only iOS VideoState timer suppressed.
- Diff whitespace check: passed.

The final device log also contains an unrelated metadata_god dynamic-library error during local video import. That path was outside this audio-transition change and was not modified.

Included logs contain lifecycle/recovery excerpts and filtered test results. Raw capture files are in `/tmp/ppplayer-ios-notification-center*.log`.
