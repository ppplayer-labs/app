# Playback, local files, and system controls

For playback-library wiring, source usage and platform providers, see
[native media integration](native_media.md).

These instructions describe the development tree as of October 2, 2026. The new iOS functionality has physical-device checks, but iOS is not yet publicly available and this document does not announce a release.

## Import and reopen local music

Import a song through Local Music. New iOS music imports are copied into the app's managed local storage and persisted with a `pp-local:` locator. Close and reopen the app, then select the imported song again.

File-picker temporary paths can disappear after the importing session. New imports no longer rely on those paths. If an older library entry references a file that has already been deleted, import the original again. Removing the app and its data removes managed copies too; retain your original files separately.

Apple security-scoped bookmarks are resolved only when file access is acquired. Their base64 strings are not file URLs. Local engine access remains leased while paused and is released after its reader stops. Remote HTTP access remains leased until accepted reads drain. See [network outputs](network_outputs.md) for the acquisition boundary and lifecycle.

## Play On and active devices

Open **Play On** from the player. Cast and DLNA devices require discovery, network reachability, a supported source and a compatible receiver.

Desktop windows below 1000 pixels use compact navigation and playback controls.
Previous/play/next, Play On and a labeled Queue button stay visible; shuffle,
repeat, video and volume adjustment are available in More playback controls.
Queue opens the queue view directly. The home heading sizes to the available
content width and can wrap; wider windows retain the full sidebar and controls.

macOS now discovers Chromecast receivers through native Bonjour and controls the
Default Media Receiver over CASTV2. Start with imported local music or a supported
HTTP stream; select the receiver in Play On. The Mac must stay running while it
serves a local file. YouTube sources cannot use this media-URL handoff. Physical
Chromecast playback still needs receiver validation.

On iOS, use the **AirPlay** button to open Apple's route picker. The selected receiver name appears in the AirPlay row, and **This device** loses its selected state while AirPlay is active. To return to the iPhone, tap **This device** and choose the iPhone in the system picker.

When Cast/DLNA is active, return to the local engine before using AirPlay. AirPlay routes that engine's audio; it does not load an HTTP item or create a Cast session.

On macOS, **Play On → AirPlay & audio output** opens Sound settings. Choose an output there and return to the app. The row shows the system's current output name; AirPlay, Bluetooth and USB outputs deselect **This device**. Returning to built-in audio selects This device again. Clicking This device while an external route is active opens Sound settings rather than silently disconnecting it. If a remote session is active, the system-routing row returns playback to the Mac before opening settings; it is disabled during connection. This follows the system default output, so changing it affects other apps using that output too.

If an AirPlay receiver is selected but silent, check source playback, volume on both devices and receiver availability. Local music from a physical iPhone to a MacBook has been verified. Physical Cast and DLNA playback remain pending; the simulated Cast receiver is a development tool.

## Video page and queue

The primary controls are previous, play/pause and next. **Queue** has a dedicated labeled button. Opening the queue keeps the video surface mounted instead of rebuilding playback.

Secondary actions are grouped in an options menu: shuffle, repeat, autoplay, subtitles, audio selection and fit controls where the current media supports them. The layout adapts to narrow portrait, compact landscape, desktop and larger text settings. Fit controls remain capability-gated.

## Local audio artwork

Local audio uses the track's artwork or audio fallback. It must not inherit `activeVideoId` or a video surface from an earlier YouTube track. Local audio is not classified as video solely because embedded artwork has image dimensions.

Image consumers use `PPImage` / `PPImageProvider`. Network image loading receives only valid HTTP(S) image URLs. File images use decoded file paths. Bookmarks are file-access locators, not image URLs, and do not receive special handling inside `CachedNetworkImageProvider`.

## iPhone lock screen, Control Center, and background playback

`PpPlayerAudioHandler` forwards iOS system commands to `PlayerNotifier`, the same playback intent path used by the app UI. `AppDelegate` owns the `ios_media_controls` channel, native `MPRemoteCommandCenter` targets and `MPNowPlayingInfoCenter` metadata/state publication.

The active WebKit video session can receive system controls directly. The document-start user script installs `navigator.mediaSession` action handlers in all frames and forwards them through `WKScriptMessageHandler`. Later YouTube registration or clearing of play/pause handlers retains that bridge. Already-created YouTube child frames are navigated once to receive the script; the parent wrapper and Flutter JavaScript channels are retained.

An explicit pause changes intended state to paused and invalidates recovery. Late renderer playing/paused events cannot grant permission to replay. Background recovery remains available for involuntary WebKit pauses while intended state is playing; it confirms live renderer state before issuing play and reports paused honestly until playback is acknowledged.

Expected device evidence:

```text
[MediaControls] iOS remote command=pause source=webKit
ENGINE pause() caller=user
STATE ... → PlaybackState.paused ... intended=PlaybackState.paused
```

No recovery-driven `playVideo` should follow that explicit pause. An explicit system play is logged separately and resumes playback. The physical iPhone check on October 1 observed this sequence, with about two seconds between pause and an explicit system play command. Longer paused intervals and receiver-specific behavior should still be included in release testing.

## Verification and remaining device checks

- App suite: 294 tests passed at the October 1 checkpoint; Flutter analysis clean.
- Apple bookmark/file acquisition: resolving, invalid bookmarks, direct file URIs, lease lifetime and HTTP serving covered by automated tests.
- Fake Cast: asynchronous connection/load, endpoint/session/item validation and local-file URL handoff covered automatically.
- Responsive player: portrait/landscape/desktop and large text cases covered; queue opening retains video surface.
- AirPlay active-route UI: selection reflects native route events.
- Physical iPhone: local music to MacBook AirPlay and system play/pause checked by the user with logs.
- Physical Chromecast / DLNA: pending. iOS DLNA discovery requires approved multicast capability.

Evidence is under `verification/ios-system-pause-20261001`, `verification/airplay-local-audit-20261001`, `verification/airplay-active-route-20261001`, `verification/network-outputs-acquisition-20261001`, `verification/ios-import-persistence-20261001` and `verification/video-layout-20261001`.

When collecting logs, keep only playback/route/lease diagnostics. HTTP debug output can contain credentials and must not be published unfiltered.
