# iOS YouTube background pause

User confirmed audio stops after minimizing. Device log shows app lifecycle paused, YouTube paused, attempted playVideo recovery, and timeline fixed at 124.7399508136635 seconds. The bridge previously labeled playback playing to suppress a paused event despite failed recovery.

Corrected iOS pause handling: live paused confirmation publishes paused; recovery dispatch does not imply playback acknowledgement. Duplicate pause callbacks retain paused state until playing arrives. Stale callbacks still use a live-state check before affecting playback.

Validation: 11 iOS recovery tests passed, including the new confirmed-pause/no-acknowledgement regression; analysis clean. Full app results in app-tests.log.

This corrects status reporting. Continuous YouTube background playback is NOT fixed or verified by this change. Local-file/AirPlay background playback must be assessed separately. Hot reload requested; completion depends on the background device connection.
