# Active AirPlay receiver selection

The menu previously inferred “This Device” from the local playback controller and never subscribed to system routing. AirPlay retains local playback while sending its audio elsewhere, so that check could not identify the active receiver.

The running phone was queried through the existing native getAirPlayRoute method during investigation: `connected=false`, `name=""` at that moment. This snapshot does not establish the route at the earlier time when the MacBook was selected.

The fix adds a dedicated iOS route-event stream, independent of Fake Cast/native Cast subscriptions. It emits AVAudioSession's current AirPlay route immediately and whenever the audio route changes. Play On uses this route to mark AirPlay selected, show the receiver name, and clear the This Device check. Cast retains selection precedence. Tapping This Device while AirPlay is active opens Apple's picker to choose the iPhone; returning to the local controller alone does not pretend to disconnect system routing.

Files changed:
- `ios/Runner/AppDelegate.swift`: register the dedicated AVAudioSession route observer and Flutter event stream.
- `lib/core/network_outputs/airplay_route.dart`: system-route model, stream providers, and selection rules.
- `lib/features/network_outputs/output_picker.dart`: use actual audio routing for local/AirPlay selection and return-to-iPhone action.
- `lib/features/network_outputs/airplay_output_tile.dart`: show the active receiver name/check and native return-to-iPhone picker.
- `test/core/network_outputs/airplay_route_test.dart`: initial/current route, connect/disconnect updates, and Cast precedence.
- `test/features/network_outputs/airplay_output_tile_test.dart`: selected MacBook label/check regression.

Validation: 285 Flutter tests passed; flutter analyze reports no issues; Swift syntax validation passed. The physical-device build is deployed for receiver testing. Audio transfer to a real AirPlay receiver is not claimed by the mocked regression tests.

Physical iPhone confirmation: the updated app launched successfully and emitted a real route event naming `Lucas’s MacBook Pro` with `connected=true`, followed by a `connected=false` update. See `device-route.log`. This verifies real native route detection and event delivery; audible receiver playback was not independently checked.
