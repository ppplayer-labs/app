import 'package:flutter/foundation.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';

/// Source capabilities of the candidate, independent of native initialization.
enum PlaybackRoute { nativeMedia, chromiumYoutube, webKitYoutube, unsupported }

class PlaybackSelection {
  const PlaybackSelection({
    required this.platform,
    required this.chromiumEnabled,
  });

  final TargetPlatform platform;
  final bool chromiumEnabled;

  bool get usesWebKit => platform == TargetPlatform.iOS;
  bool get usesChromium =>
      chromiumEnabled &&
      {
        TargetPlatform.android,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }.contains(platform);

  PlaybackRoute routeFor(PlaybackTrack track) {
    if (track.sourceType != PlaybackSourceType.online) {
      return PlaybackRoute.nativeMedia;
    }
    if (usesWebKit) return PlaybackRoute.webKitYoutube;
    return usesChromium
        ? PlaybackRoute.chromiumYoutube
        : PlaybackRoute.unsupported;
  }
}
