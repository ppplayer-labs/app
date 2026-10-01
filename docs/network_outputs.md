# Network Outputs

PPPlayer can route playback to network devices — DLNA/UPnP media renderers today, with Google Cast (Android) planned.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  UI layer                                            │
│  ┌────────────────┐  ┌──────────────────────────┐    │
│  │ OutputPicker   │  │ MiniPlayerBar / Overlays  │    │
│  │ (bottom sheet) │  │ cast icon + "Playing on…" │    │
│  └───────┬────────┘  └──────────┬───────────────┘    │
│          │ reads/calls          │ reads               │
│          ▼                      ▼                     │
│  networkOutputControllerProvider (Riverpod)           │
│  networkOutputSnapshotProvider   (Riverpod)           │
│          │                                            │
│          ▼                                            │
│  NetworkOutputController                              │
│  ┌──────────────────────────────────────────────┐     │
│  │  localController (HybridPlaybackEngine /      │     │
│  │                   MediaKitPlaybackEngine)      │     │
│  │  backends: [DlnaOutputBackend, …]             │     │
│  │  mediaFactory: DefaultNetworkMediaFactory     │     │
│  └───────────────────────┬──────────────────────┘     │
└──────────────────────────┼───────────────────────────┘
                           │
             ┌─────────────┴────────────┐
             ▼                          ▼
   DlnaOutputBackend          (future) CastOutputBackend
   ┌───────────────────┐
   │ DlnaDiscovery     │  SSDP multicast → discovers MediaRenderers
   │ DlnaSoapClient    │  HTTP/SOAP AVTransport + RenderingControl
   │ LocalMediaServer  │  HTTP server, serves local files to renderers
   └───────────────────┘
```

## Providers

| Provider | Type | Purpose |
|---|---|---|
| `localMediaServerProvider` | `Provider<LocalMediaServer>` | Shared HTTP file server for LAN access |
| `dlnaOutputBackendProvider` | `Provider<DlnaOutputBackend>` | DLNA protocol backend |
| `networkOutputControllerProvider` | `Provider<NetworkOutputController>` | Central orchestrator |
| `networkOutputStateProvider` | `StreamProvider<NetworkOutputState>` | Live output state stream |
| `networkOutputSnapshotProvider` | `Provider<NetworkOutputState>` | Synchronous snapshot |

## DLNA Playback Flow

1. User taps the **Cast** icon (player overlay or mini-player).
2. `showOutputPicker()` opens and calls `NetworkOutputController.startDiscovery()`.
3. `DlnaDiscovery` sends SSDP M-SEARCH and listens for announcements; found devices appear in the picker.
4. User selects a renderer → `NetworkOutputController.selectOutput(output)`.
5. Controller calls `DefaultNetworkMediaFactory.createItem(track)` to generate a LAN-accessible URL:
   - **Local files** → `LocalMediaServer` serves them transiently on the LAN.
   - **Network streams** → proxied or passed through directly.
   - **YouTube** → not supported on DLNA (online-source block).
6. `DlnaOutputBackend.connect()` pings the renderer with `GetTransportInfo`.
7. `DlnaOutputBackend.load()` sends `SetAVTransportURI` + `Play`.
8. Polling (1 s during playback, 5 s otherwise) keeps position and state in sync via `GetTransportInfo` + `GetPositionInfo`.
9. User returns local → `NetworkOutputController.returnToLocal()` calls `disconnect()` (with `stopPlayback: true`) and resumes local engine.

## Session / Generation Guards

- Every connect/load call increments an internal `_generation` counter.
- All async continuations call `_guardGeneration()` before writing state.
- All public command methods call `_guardSession()` / `_guardSessionAndItem()` and throw `NetworkOutputException(code: 'stale_session')` if the session no longer matches — callers should catch and discard this.

## LocalMediaServer

- Listens on a random available port at startup.
- Issues short-lived (10-minute TTL) access tokens per file.
- Does **not** transcode; renderers must support the source format.
- Disposed automatically with the provider.

## Capability Checking

`OutputCapabilityResolver.sourceSupport(track, output)` returns `OutputSupportResult`:
- `.supported = false` for YouTube/online sources on DLNA (renderer can't authenticate).
- Checks `output.capabilities.audio` / `.video` against `track.isVideo`.
- The picker greys out unsupported tiles and prevents selection.

## Capability Matrix

| Platform | DLNA | Google Cast | AirPlay | Local Output |
|---|---|---|---|---|
| **Android** | ✅ Implemented | ✅ Implemented | ❌ Unsupported | ✅ Implemented |
| **iOS** | ✅ Implemented | ✅ Implemented | ✅ System | ✅ Implemented |
| **macOS** | ✅ Implemented | ❌ Unsupported by official native Sender SDK | ✅ System | ✅ Implemented |
| **Windows** | ✅ Implemented | ❌ Unsupported by official native Sender SDK | ❌ Unsupported | ✅ Implemented |
| **Linux** | ✅ Implemented | ❌ Unsupported by official native Sender SDK | ❌ Unsupported | ✅ Implemented |

*(Note: Real-device compilation and release verification completed successfully for Android, iOS, macOS, Windows, and Linux)*

| Protocol | YouTube Support | Requirements |
|---|---|---|
| **DLNA** | ❌ Unsupported | Requires LAN reachable media, renderer must support format natively |
| **Google Cast** | ❌ Unsupported | Official Google Cast Sender SDK |
| **AirPlay** | ✅ Supported | System AVRoutePickerView (iOS/macOS only) |
| **Local** | ✅ Supported | Default audio engine |

## Adding a New Backend

1. Implement `NetworkOutputBackend` (in `lib/core/network_outputs/network_output_backend.dart`).
2. Create a Riverpod `Provider<YourBackend>` in `network_output_providers.dart`.
3. Add it to the `backends:` list in `networkOutputControllerProvider`.
4. Extend `OutputCapabilityResolver.sourceSupport()` if needed.
