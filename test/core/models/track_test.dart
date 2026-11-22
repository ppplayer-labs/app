import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/models/track.dart';

void main() {
  group('Track Serialization / Cache Resources', () {
    test('Track serializes and deserializes correctly', () {
      final track = Track(
        spotifyId: '123',
        name: 'Test Track',
        artistId: 'art1',
        artistName: 'Artist 1',
        albumName: 'Test Album',
        albumId: '456',
        durationMs: 200000,
        albumImage: 'https://example.com/image.jpg',
        isFavorite: false,
      );

      final json = track.toJson();
      final decoded = Track.fromJson(json);

      expect(decoded.spotifyId, '123');
      expect(decoded.name, 'Test Track');
      expect(decoded.artistName, 'Artist 1');
      expect(decoded.albumName, 'Test Album');
      expect(decoded.albumId, '456');
      expect(decoded.durationMs, 200000);
      expect(decoded.albumImage, 'https://example.com/image.jpg');
      expect(decoded.isFavorite, false);
    });

    test(
      'Track.fromSpotify skips empty image entries to pick first valid artwork URL',
      () {
        final track = Track.fromSpotify({
          'id': 't1',
          'name': 'Fallback Art Track',
          'artists': [
            {'id': 'a1', 'name': 'Artist 1'},
          ],
          'album': {
            'id': 'al1',
            'name': 'Album 1',
            'images': [
              {'url': ''},
              {'url': null},
              {'url': 'https://i.scdn.co/image/valid_300'},
            ],
          },
        });
        expect(track.albumImage, 'https://i.scdn.co/image/valid_300');
      },
    );
  });
}
