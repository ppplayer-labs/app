# Play On and network outputs

This document describes the development tree as of October 2, 2026. Implementation and automated coverage do not imply a published release or validation with every physical receiver.

## User-facing behavior

Open **Play On** from the player to choose an output. Cast and DLNA devices appear when their backend is available and discovery succeeds. Unsupported source/device combinations cannot be selected.

On iOS, **AirPlay** opens Apple's `AVRoutePickerView`. AirPlay stays on the local playback engine and follows `AVAudioSession` routing; it does not create a Cast session or a LocalMediaServer URL. Native route-change events supply the selected receiver name and check mark. **This device** is not selected while an AirPlay receiver is active. Selecting it opens a system picker so the user can choose the iPhone.

If Cast/DLNA is active, return playback to the local engine before choosing AirPlay. macOS audio routing uses system controls; the new in-app AirPlay picker is iOS-only.

## Platform availability

| Platform | DLNA/UPnP | Google Cast | AirPlay | Local playback |
|---|---|---|---|---|
| Android | Backend available | Native sender backend available | No in-app picker | Supported |
| iOS | Gated on approved multicast capability and build configuration | Native sender backend available | In-app system picker | Supported |
| macOS | Backend available | No official native sender backend | System routing | Supported |
| Windows / Linux | Backend available | No official native sender backend | No in-app picker | Supported |

`NetworkOutputsCapabilities.resolve()` controls backend registration. On iOS it reads native capabilities rather than assuming discovery is usable. The multicast build capability must be approved and enabled for DLNA discovery.

| Source | Cast / DLNA | AirPlay on iPhone |
|---|---|---|
| Local file | Served as tokenized LAN HTTP media; receiver must support format | Local playback routed by Apple |
| Compatible HTTP(S) stream | Direct or proxied HTTP media | Local playback routed by Apple |
| YouTube / online source | Unsupported by the media-URL handoff | Remains on embedded local player with system routing; receiver behavior needs validation |

PPPlayer does not transcode. Reachability, receiver codecs, network permissions, and source accessibility still apply.

## Architecture and providers

`OutputPicker` → `NetworkOutputController` → `CastOutputBackend` / `DlnaOutputBackend`.

The controller owns output/session transitions and wraps the local playback controller. `DefaultNetworkMediaFactory` creates receiver-readable media and resource leases. `LocalMediaServer` serves local files or proxies explicit HTTP(S) media. AirPlay is observed independently of these backends.

| Provider | Purpose |
|---|---|
| `localMediaServerProvider` | Shared LAN media server |
| `networkOutputCapabilitiesProvider` | Platform capability resolution |
| `castOutputBackendProvider` | Cast backend; optional debug fake client |
| `dlnaOutputBackendProvider` | DLNA discovery and transport |
| `networkOutputControllerProvider` | Output orchestration |
| `networkOutputStateProvider` / `networkOutputSnapshotProvider` | Stream / synchronous state |
| `airPlayRouteProvider` | Native iOS route state |

## Apple local-file acquisition boundary

`PlaybackTrack.localMediaUri` is a persisted locator, not necessarily a URL. On iOS it may contain a base64 security-scoped bookmark. Never interpret that bookmark as a file URI or resolve it inside the Cast backend.

`DefaultNetworkMediaFactory` receives `acquireAppleOutputFileLease` on iOS/macOS. It accepts:

- `file://` URIs and absolute paths directly;
- durable `pp-local:` locators through `ManagedLocalFileStore`;
- bookmark strings through local_library's public `Future<String?> resolveSecurityScopedBookmark(String bookmark)`.

The public resolver delegates to the existing local-library MethodChannel logic. A successful resolution starts native security-scoped access. Acquisition checks the resolved file and returns an `AuthorizedFileLease`; invalid or missing files fail cleanly, balancing any access already opened.

```text
bookmark resolution starts security scope
    → AuthorizedFileLease holds access
    → LocalMediaServer accepts and serves HTTP reads
    → token expires / item is revoked / output is disposed
    → no new reads accepted
    → existing reads drain and close
    → lease releases security scope exactly once
```

The server uses the resolved path for MIME detection. The default token lifetime is **12 hours**, configurable through `tokenLifetime`; it is not a guarantee that a remote session lasts that long. Item/session teardown can revoke it earlier. Expiry and revocation defer release while accepted requests still hold the resource.

Apple local playback uses `LocalFilePlaybackController` to acquire a lease at engine-open time, preserving the original locator in status and persisted queues. Pausing retains access; stopping/disposal stops the reader before releasing access. The same bookmark can be held by multiple readers; native access is reference-counted.

New iOS music imports are managed copies in the app's Documents/local_music directory, addressed with `pp-local:` locators. Temporary file-picker paths are not persisted. Old imports whose source files have disappeared need reimporting; this fix cannot recover deleted files.

## Session safety and fake Cast

Connection and load continuations are guarded by generation, endpoint ID, session ID, and item ID. Stale callbacks cannot replace an active session. This protection remains in `NetworkOutputController`.

With `--dart-define=PP_FAKE_CAST_DEVICE=true` in a debug build, `FakeCastPlatformClient` makes receiver callbacks asynchronous: connecting precedes connected, and callbacks arrive after the pending session exists. Load/playback callbacks validate endpoint/session/item identity. The fake verifies media acquisition, HTTP URLs and controller handoff; it does not prove compatibility with a physical Chromecast.

## Validation status

- Physical iPhone → MacBook AirPlay with local music: user verified audible playback.
- Physical iPhone Control Center / lock-screen commands: WebKit pause reaches Flutter intent; no recovery replay; explicit system play resumes.
- iOS bookmark → lease → HTTP URL → fake Cast: automated coverage, including invalid bookmarks, direct file URIs, scope lifetime and serving.
- Physical Chromecast: intentionally deferred; not yet verified in this session.
- Physical DLNA receiver: not yet verified in this session; iOS multicast capability remains a prerequisite.

See [playback guide](playback.md) and the evidence under `verification/`.

## Checks

From `app/`:

```bash
flutter analyze
flutter test
flutter test test/core/network_outputs/ios_file_lease_test.dart
flutter test test/core/network_outputs/local_media_server_test.dart
flutter test test/core/playback/ios_media_commands_test.dart
node verification/ios-system-pause-20261001/webkit-media-session.test.cjs
```

## Adding a backend

Implement `NetworkOutputBackend`, add its provider, and register it only when platform capabilities permit. Extend source capability checks where necessary. Preserve endpoint/session/item and generation validation. Resolve file access at the media acquisition boundary, not inside a protocol backend.
