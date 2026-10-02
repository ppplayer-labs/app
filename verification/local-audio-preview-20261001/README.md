# Local audio video preview correction

Local audio was assigned activeVideoId by native prepare/play, and PlaybackStatus.copyWith could not clear a previous ID. The scaffold selected the floating video preview from that ID. Decoder image dimensions (including embedded cover art) also enabled hasVideo for audio.

The engine now assigns IDs only to video, explicitly clears them for audio, and ignores decoder image dimensions for known local audio. The scaffold requires video capability and the local track video flag before showing its video preview.

Validation: flutter analyze clean; flutter test 285 passed; two focused production engine regressions passed (video to audio, prepare audio following online video). Wider engine tests: 46 passed, 2 failed. Both pause-related failures reproduced against unchanged HEAD engine/model/test sources copied to /tmp; unrelated to this change.

Physical iPhone build and launch succeeded on retry after unlocking (device-launch.log). Manual local song playback remains to be confirmed.
