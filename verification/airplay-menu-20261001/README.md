# AirPlay in Play On

The iOS menu now shows an AirPlay row when the native host advertises its system picker. With local playback, this row embeds the registered `AVRoutePickerView` as a `UiKitView`: the user taps Apple's actual AirPlay button to choose a receiver.

When Cast/DLNA playback is active, the row first returns playback to the iPhone using the existing controller's local-output handoff. The system picker becomes available afterward. During an output connection, no overlapping switch is allowed. AirPlay remains iOS audio routing; no Cast backend or HTTP media lease is created for it.

Changed files:
- `lib/core/network_outputs/network_output_capabilities.dart`: carry native AirPlay picker availability.
- `lib/features/network_outputs/output_picker.dart`: insert AirPlay in Play On and return remote playback locally before routing.
- `lib/features/network_outputs/airplay_output_tile.dart`: render the native route button and local-playback guard.
- `test/features/network_outputs/airplay_output_tile_test.dart`: three widget regressions for the real platform-view registration and switching/connecting guards.

Validation: all 281 Flutter tests passed; flutter analyze reports no issues. AirPlay receiver playback and video support require on-device receiver testing; this change does not claim that either has been verified.
