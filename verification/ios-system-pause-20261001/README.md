# iPhone system pause resumes unexpectedly

User reported iPhone lock-screen/Control Center pause restarting the song. Native ios_media_controls handled only activateAudioSession, and Dart had no inbound system command handler. WebView pauses therefore retained playing intent and triggered automatic pause recovery.

AppDelegate now retains its own MPRemoteCommandCenter targets and forwards play/pause/toggle/next/previous/seek through the existing ios_media_controls channel. PpPlayerAudioHandler routes these commands through PlayerNotifier, establishing explicit pause intent before recovery can resume. Targets are removed individually on deinit; existing WebKit targets are retained. Cast architecture is unchanged.

Regression sends encoded platform pause into the real PpPlayerAudioHandler, uses the production engine with a fake YouTube bridge, checks late paused/playing events cannot replay, and checks explicit play/toggle/navigation/seek mapping. Regression passed; full app suite 294 passed; analyze clean; physical iOS build succeeded. Updated app installed and running on the physical iPhone. Actual lock-screen testing remains pending user verification.

## Follow-up: Control Center still bypassed the bridge

The user reproduced the failure. Device log `/tmp/ppplayer-ios-pause-commands-device.log` contains repeated confirmed-pause recovery between 18:45:55 and 18:46:02, with no inbound MediaControls command or ENGINE pause. The initial command-only change did not establish an app Now Playing publication. AudioService.init is bypassed on iOS, so its normal metadata/state publisher was absent too.

The existing native channel now also accepts updateNowPlaying. PpPlayerAudioHandler sends metadata and playback state after either changes, activates the audio session for playback, and snapshots the latest state after activation completes. Native code publishes MPNowPlayingInfoCenter title/artist/album/duration, cached artwork, position and playback rate (zero while paused). Artwork is loaded only when its cached path changes. Native diagnostic logs identify publication state transitions and forwarded commands.

The regression additionally checks that metadata and playing/paused state actually cross the platform channel. Updated targeted regression passed; full suite 294 passed; analysis clean; native device build succeeded. Device retest is necessary to verify that iOS delivers the physical Control Center command. New runtime log: `/tmp/ppplayer-ios-nowplaying-device.log`.

## WebKit system command bridge

The next live run still contained recovery-driven replay at 19:08:18, 19:08:20, 19:08:48 and 19:08:50, without an inbound native pause. Inspection found that AppDelegate's existing visibility patch explicitly cleared navigator.mediaSession play/pause handlers. MPRemoteCommandCenter alone did not capture the system controls for the active WebKit video session.

That injected patch now routes mediaSession play/pause/seek/next/previous through a WKScriptMessageHandler and the existing Flutter command channel. Later YouTube handler registration or clearing keeps the bridge installed. Recovery continues to handle involuntary background pauses; deliberate system actions go through PlayerNotifier.pause and invalidate recovery intent. Cast is unchanged.

Document-start injection applies to all frames. The current parent frame is patched immediately, and any already-created YouTube child frame is navigated once to install the script across its origin without discarding the wrapper or its Flutter JavaScript channels. Future child navigation receives the user script automatically. Native command payloads are allowlisted and seek values validated. Dart logs identify WebKit-sourced system commands.

`node verification/ios-system-pause-20261001/webkit-media-session.test.cjs` executes the actual injected script and checks action forwarding, later handler replacement/clearing, invalid seek rejection and idempotence. It passed. Flutter analysis is clean and all 294 app tests pass, including system pause followed by late renderer events with no replay. Runtime log: `/tmp/ppplayer-ios-webkit-controls-device.log`. Physical Control Center verification remains necessary.

## Physical iPhone result

User confirmed the fix appears to work. Device logs now show `remote command=pause source=webKit` at 19:22:17, followed by ENGINE pause(caller=user) and a paused state with intended=paused. No recovery replay follows this pause. Playback resumes only after `remote command=play source=webKit` at 19:22:19. The observed pause interval is about two seconds, ending with an explicit system play command. Earlier background transitions at 19:22:08 and 19:22:12 still recover playback as intended. Filtered device evidence is saved in webkit-device-evidence.log.
