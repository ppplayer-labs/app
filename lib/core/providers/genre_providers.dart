import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/spotify_repository.dart';
import '../models/track.dart';

final browseCategoriesProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.watchBrowseCategories(limit: 50).map((res) => res.data);
});

final categoryPlaylistsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      categoryId,
    ) {
      final repo = ref.watch(spotifyRepositoryProvider);
      return repo.watchCategoryPlaylists(categoryId).map((r) => r.data);
    });

final categoryTopTracksProvider = StreamProvider.family<List<Track>, String>((
  ref,
  categoryId,
) async* {
  final playlists = await ref.watch(
    categoryPlaylistsProvider(categoryId).future,
  );
  if (playlists.isEmpty) {
    yield [];
    return;
  }

  final playlistId = playlists.first['id'] as String?;
  if (playlistId == null) {
    yield [];
    return;
  }

  final repo = ref.watch(spotifyRepositoryProvider);
  yield* repo.watchPlaylistTracks(playlistId).map((r) => r.data);
});

final categoryCollageImagesProvider =
    StreamProvider.family<List<String>, String>((ref, categoryId) async* {
      final tracks = await ref.watch(
        categoryTopTracksProvider(categoryId).future,
      );

      final images = <String>{};
      for (final track in tracks) {
        if (track.albumImage != null && track.albumImage!.isNotEmpty) {
          images.add(track.albumImage!);
          if (images.length >= 3) break;
        }
      }

      yield images.toList();
    });

final playlistCollageImagesProvider =
    StreamProvider.family<List<String>, String>((ref, playlistId) async* {
      final repo = ref.watch(spotifyRepositoryProvider);
      final tracksStream = repo.watchPlaylistTracks(playlistId);

      await for (final cacheResult in tracksStream) {
        final images = <String>{};
        for (final track in cacheResult.data) {
          if (track.albumImage != null && track.albumImage!.isNotEmpty) {
            images.add(track.albumImage!);
            if (images.length >= 3) break;
          }
        }
        yield images.toList();
      }
    });

final artistCollageImagesProvider = StreamProvider.family<List<String>, String>(
  (ref, artistId) async* {
    final repo = ref.watch(spotifyRepositoryProvider);
    final tracksStream = repo.watchArtistTopTracks(artistId);

    await for (final cacheResult in tracksStream) {
      final images = <String>{};
      for (final trackData in cacheResult.data) {
        final album = trackData['album'];
        if (album != null &&
            album['images'] != null &&
            (album['images'] as List).isNotEmpty) {
          final url = album['images'][0]['url'] as String?;
          if (url != null && url.isNotEmpty) {
            images.add(url);
            if (images.length >= 4) break;
          }
        }
      }
      yield images.toList();
    }
  },
);

final radioCollageImagesProvider =
    Provider.family<AsyncValue<List<String>>, String>((ref, radioKey) {
      final parts = radioKey.split(':');
      if (parts.length != 2) return const AsyncValue.data([]);
      final seedType = parts[0];
      final seedId = parts[1];

      if (seedType == 'genre') {
        return ref.watch(categoryCollageImagesProvider(seedId));
      } else if (seedType == 'artist') {
        return ref.watch(artistCollageImagesProvider(seedId));
      } else if (seedType == 'playlist') {
        return ref.watch(playlistCollageImagesProvider(seedId));
      } else {
        return const AsyncValue.data([]);
      }
    });
