# Android playback architecture examined

Candidate 4.0.0+12, same app source as prior audit plus diagnostic/test changes.

1. `PlayerNotifier` owns track/queue and explicit play/pause intent. Production
   `HybridPlaybackEngine` uses persistent foreground ownership on Android:
   ChromiumPlaybackEngine handles online YouTube; MediaKit handles local/direct
   media. The background NativeServicePlaybackEngine is not an alternate player
   for this path. Source transitions close the previous browser generation.
2. ChromiumYoutubePlayerController generates an HTTPS wrapper document and
   creates YouTube's iframe through the official iframe API. Commands are
   serialized, identified by controller generation and delivered through the JS
   channel. State events and progress are renderer-derived. Its debug heartbeat
   samples wrapper visibility, time and estimated loaded fraction; these do not
   expose iframe decoder state by themselves.
3. The Android plugin creates one System WebView, not desktop CEF. It uses an
   autoplay-isolated profile and application/Activity MutableContextWrapper.
   HTML is intercepted as an in-memory main-frame response. Subframe/segment
   requests go to the normal WebView network stack. No media URL extractor or
   proxy substitutes for the YouTube iframe.
4. Native WebView window visibility is currently reported as visible for autoplay
   browsers, even when the Activity stops. That patch predates this investigation
   and was not expanded. The view normally remains attached to FlutterMutatorView;
   widget disposal can park it in a transparent 1x1 DecorView. It is not detached
   at the observed Home transition. Android onPause/onResume calls are logged,
   without periodic resume/play/seek commands.
5. `ChromiumMediaService` serializes a lease to CustomWebViewService. In Chromium
   mode that foreground service owns no WebView and creates no second playback
   pipeline. A separate AudioService publishes notification/MediaSession controls
   through PpPlayerAudioHandler and MediaSyncService to PlayerNotifier. The
   Chromium browser's audio focus delegate owns audible browser focus; other
   platform session work must not compete with that ownership.
6. MediaSyncService maps buffering as not currently playing. AudioService can
   leave its own foreground state when paused; the Chromium support foreground
   service remains active. Its service snapshot during the observed live decoder
   underflow reports isForeground=true/type mediaPlayback. Audio dump shows the
   app's Chromium AudioFocusDelegate has GAIN with loss:none. This is evidence
   against missing support-service ownership or recorded focus loss in that run,
   not proof that every interruption path is correct.
7. Inside the iframe, Chromium media diagnostics show ChunkDemuxer (MSE), VP9
   MediaCodecVideoDecoder / c2.goldfish.vp9.decoder and OpusAudioDecoder. Video
   adapts 854x480→1280x720; Chromium reports eliding EOS/flush for that resolution
   change. Native DECODER_UNDERFLOW events occur with buffered data ahead. This
   is a materially different path from the passing small H.264/AAC inline MP4.
8. Flutter publishes observed buffering rather than synthesizing progress.
   Continued wrapper and iframe JS does not mean decoded video advances. The
   CDP observer samples the actual cross-origin media element and native media
   domain through the existing debuggable test app, without enabling remote
   debugging in production. Observation can affect timing; unobserved repeats
   are still required for acceptance.

No causal claim about YouTube deliberate policy enforcement is supported by a
buffering state alone. No native decoder configuration change, visibility spoof,
cache reset, forced quality/audio-only route, wake-lock or replay loop was added.
