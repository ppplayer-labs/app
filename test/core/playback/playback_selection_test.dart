import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/playback/playback_selection.dart';

void main() {
  for (final platform in TargetPlatform.values) {
    for (final enabled in [true, false]) {
      final selection = PlaybackSelection(
        platform: platform,
        chromiumEnabled: enabled,
      );
      test('$platform Chromium=$enabled source capability matrix', () {
        for (final video in [true, false]) {
          expect(
            selection.routeFor(
              PlaybackTrack(
                id: 'local',
                title: 'Local',
                sourceType: PlaybackSourceType.local,
                isVideo: video,
              ),
            ),
            PlaybackRoute.nativeMedia,
          );
          expect(
            selection.routeFor(
              PlaybackTrack(id: 'youtube', title: 'YouTube', isVideo: video),
            ),
            platform == TargetPlatform.iOS
                ? PlaybackRoute.webKitYoutube
                : enabled && platform != TargetPlatform.fuchsia
                ? PlaybackRoute.chromiumYoutube
                : PlaybackRoute.unsupported,
          );
        }
        for (final live in PlaybackLiveStatus.values) {
          expect(
            selection.routeFor(
              PlaybackTrack(
                id: 'stream',
                title: 'Stream',
                sourceType: PlaybackSourceType.networkStream,
                liveStatus: live,
              ),
            ),
            PlaybackRoute.nativeMedia,
          );
        }
      });
    }
  }
}
