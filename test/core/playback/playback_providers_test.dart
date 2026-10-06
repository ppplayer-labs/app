import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ppplayer/core/playback/chromium_playback_engine.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Android enables visible video alongside its playback service', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final engine = container.read(localPlaybackControllerProvider);
    expect(engine, isA<ChromiumPlaybackEngine>());
    final chromium = engine as ChromiumPlaybackEngine;
    expect(chromium.showBrowser, isTrue);
    expect(chromium.startPlaybackService, isNotNull);
    expect(chromium.stopPlaybackService, isNotNull);
  });

  group('TrackToPlayback Extension', () {
    test('toPlaybackTrack correctly preserves isVideo for local video', () {
      final videoTrack = const Track(
        spotifyId: 'local_video_1',
        name: 'My Video',
        artistId: 'artist_1',
        artistName: 'Unknown',
        sourceType: TrackSourceType.local,
        localFilePath: '/path/to/video.mp4',
        isVideoFile: true,
      );

      final playbackTrack = videoTrack.toPlaybackTrack();

      expect(playbackTrack.sourceType, PlaybackSourceType.local);
      expect(playbackTrack.isVideo, isTrue);
    });

    test('toPlaybackTrack correctly keeps isVideo false for local audio', () {
      final audioTrack = const Track(
        spotifyId: 'local_audio_1',
        name: 'My Audio',
        artistId: 'artist_1',
        artistName: 'Unknown',
        sourceType: TrackSourceType.local,
        localFilePath: '/path/to/audio.mp3',
        isVideoFile: false,
      );

      final playbackTrack = audioTrack.toPlaybackTrack();

      expect(playbackTrack.sourceType, PlaybackSourceType.local);
      expect(playbackTrack.isVideo, isFalse);
    });

    test(
      'Imported local track preserves local locator and video flag, and selects native playback',
      () {
        final importedTrack = Track.fromLocalFile(
          libraryId: 'local:1234',
          name: 'Imported Video',
          artistName: 'Local Artist',
          albumName: 'Local Album',
          localFilePath: '/absolute/path/to/imported_video.mp4',
          isVideoFile: true,
        );

        final playbackTrack = importedTrack.toPlaybackTrack();

        expect(playbackTrack.sourceType, PlaybackSourceType.local);
        expect(
          playbackTrack.localMediaUri,
          '/absolute/path/to/imported_video.mp4',
        );
        expect(playbackTrack.isVideo, isTrue);
        expect(importedTrack.isLocal, isTrue);
      },
    );

    test(
      'toPlaybackTrack throws StateError for online track with UUID as youtubeVideoId',
      () {
        final invalidOnlineTrack = const Track(
          spotifyId: 'uuid-1234',
          name: 'Online Track',
          artistId: 'artist_1',
          artistName: 'Artist',
          sourceType: TrackSourceType.online,
          youtubeVideoId:
              'e4b9f2c1-d2e8-4b71-a2c9-9a7f3e8b0a1d', // UUID is 36 chars
        );

        expect(
          () => invalidOnlineTrack.toPlaybackTrack(),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
