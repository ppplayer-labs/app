import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/playback/playback_service.dart';

void main() {
  for (final source in [TrackSourceType.local, TrackSourceType.networkStream]) {
    test('$source never invokes YouTube resolution or prefetch', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(Provider(PlaybackService.new));
      final track = Track(
        spotifyId: 'source:${source.name}',
        name: 'Independent source',
        artistId: 'artist',
        artistName: 'Artist',
        sourceType: source,
        localFilePath: source == TrackSourceType.local
            ? '/music/test.mp3'
            : null,
        networkStreamUrl: source == TrackSourceType.networkStream
            ? 'https://example.com/test.mp3'
            : null,
      );
      expect(await service.resolveCandidates(track, null), isEmpty);
      await service.prefetchNext(track, null);
    });
  }
}
