# Video page layout

Transport controls now show previous, play/pause, and next. Queue is a labeled button with a minimum height of 48 and selected state. Playback options contain shuffle, repeat, autoplay, subtitles, audio tracks, and native video fit mode; unsupported options remain excluded. Fullscreen stays directly accessible.

Under 600 logical pixels (or enlarged text), queue/options/fullscreen occupy a separate row beneath transport. Wider screens use one balanced row. Landscape below 500 logical pixels in height omits the metadata row and reduces gradient padding. Portrait track options are grouped with title/favorite, and the top view switcher can scroll at large text sizes.

Validation: flutter analyze clean; full app suite 293 passed; focused player suite 28 passed. Eight new interaction/layout cases cover 320x568, 390x844, 844x390, and 1280x800 at text scales 1 and 2. Existing tests verify queue transitions retain the video surface and that Fit/Fill appears only for supported playback. Actual player layout additionally exercised at 320x568.

The supplied screenshot was unavailable. Reviewed source and a rendered 320px widget preview. Native iPhone visual/playback testing of this layout remains pending; the previous debug session had disconnected before hot reload.
