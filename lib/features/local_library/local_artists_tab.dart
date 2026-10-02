import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_library_providers.dart';
import 'local_artist_detail_screen.dart';

class LocalArtistsTab extends ConsumerWidget {
  const LocalArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(localArtistsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) {
          final isSearching = ref.watch(localSearchQueryProvider).isNotEmpty;
          return Center(
            child: Text(
              isSearching
                  ? AppLocalizations.of(context)!.noArtistsFound
                  : AppLocalizations.of(context)!.noArtistsFound,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 16),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.onSurface,
                ),
              ),
              title: Text(
                artist.name,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.trackCount(artist.trackCount),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LocalArtistDetailScreen(artistName: artist.name),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text(AppLocalizations.of(context)!.error(e.toString())),
      ),
    );
  }
}
