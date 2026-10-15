import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../core/db/app_database.dart';
import '../../core/models/track.dart' as model;
import '../../shared/widgets/tactile_buttons.dart';
import '../../shared/widgets/track_tile.dart';
import '../../core/player/player_provider.dart';

final localFolderContentsProvider =
    FutureProvider.family<List<model.Track>, String>((ref, rootLocator) async {
      return ref.watch(appDatabaseProvider).getFolderAppTracks(rootLocator);
    });

/// Human-readable root path for an import root (the locator itself may be an
/// opaque security-scoped bookmark).
final localFolderRootPathProvider = FutureProvider.family<String, String>((
  ref,
  rootLocator,
) async {
  final roots = await ref.watch(appDatabaseProvider).getAllImportRoots();
  for (final r in roots) {
    if (r.rootLocator == rootLocator) return r.displayPath;
  }
  return rootLocator;
});

class LocalFolderDetailScreen extends ConsumerWidget {
  final String rootLocator;
  final String currentPath;

  const LocalFolderDetailScreen({
    super.key,
    required this.rootLocator,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(localFolderContentsProvider(rootLocator));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final rootPath =
        ref.watch(localFolderRootPathProvider(rootLocator)).value ??
        rootLocator;
    final effectivePath = currentPath == rootLocator ? rootPath : currentPath;
    final l10n = AppLocalizations.of(context)!;
    String folderName;
    if (rootLocator == 'imported') {
      folderName = l10n.importedFiles;
    } else {
      final lastSeg = effectivePath
          .split(RegExp(r'[\\/]'))
          .where((s) => s.isNotEmpty)
          .lastOrNull;
      if (lastSeg == null || lastSeg.isEmpty || lastSeg.length > 64) {
        folderName = l10n.importedFolderFallback;
      } else {
        folderName = lastSeg;
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  TactileIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      folderName,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contentsAsync.when(
                data: (tracks) {
                  // Filter and organize items for currentPath
                  final Set<String> subfolders = {};
                  final List<model.Track> directTracks = [];

                  if (rootLocator == 'imported') {
                    directTracks.addAll(tracks);
                  } else {
                    for (final track in tracks) {
                      final filePath = track.localFilePath; // absolute path
                      if (filePath == null) continue;

                      if (filePath.startsWith(effectivePath)) {
                        final relativePath = filePath.substring(
                          effectivePath.length,
                        );
                        // Remove leading slash if any
                        final cleanRelative =
                            relativePath.startsWith('/') ||
                                relativePath.startsWith(Platform.pathSeparator)
                            ? relativePath.substring(1)
                            : relativePath;

                        final segments = cleanRelative.split(
                          Platform.pathSeparator,
                        );

                        if (segments.length == 1) {
                          // Direct file
                          directTracks.add(track);
                        } else {
                          // In a subfolder
                          subfolders.add(segments.first);
                        }
                      }
                    }

                    // Fallback safeguard: if path prefix didn't match but folder has tracks,
                    // show all tracks directly so user never sees a blank screen.
                    if (subfolders.isEmpty &&
                        directTracks.isEmpty &&
                        tracks.isNotEmpty) {
                      directTracks.addAll(tracks);
                    }
                  }

                  final subfolderList = subfolders.toList()..sort();
                  directTracks.sort((a, b) => a.name.compareTo(b.name));

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: subfolderList.length + directTracks.length,
                    itemBuilder: (context, index) {
                      if (index < subfolderList.length) {
                        final subfolderName = subfolderList[index];
                        final subfolderPath =
                            '$effectivePath${Platform.pathSeparator}$subfolderName';
                        return ListTile(
                          leading: Icon(
                            Icons.folder_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            subfolderName,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocalFolderDetailScreen(
                                  rootLocator: rootLocator,
                                  currentPath: subfolderPath,
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        final trackIndex = index - subfolderList.length;
                        final track = directTracks[trackIndex];
                        return TrackTile(
                          index: trackIndex + 1,
                          track: track,
                          onTap: () {
                            ref
                                .read(playerProvider.notifier)
                                .playTracks(
                                  directTracks,
                                  initialIndex: trackIndex,
                                );
                          },
                        );
                      }
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text(
                    AppLocalizations.of(context)!.error(e.toString()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
