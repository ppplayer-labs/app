import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/app_database.dart';
import 'local_library_providers.dart';
import 'local_folder_detail_screen.dart';

class LocalFoldersTab extends ConsumerWidget {
  const LocalFoldersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(localFoldersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) {
          return Center(
            child: Text(
              l10n.noResultsFound,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 16),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            final displayName = folder.path == 'imported'
                ? l10n.importedFiles
                : (folder.name.isNotEmpty
                      ? folder.name
                      : l10n.importedFolderFallback);

            final subtitleText = folder.path.startsWith('/')
                ? '${folder.path} • ${l10n.trackCount(folder.trackCount)}'
                : l10n.trackCount(folder.trackCount);

            return ListTile(
              leading: Icon(
                Icons.folder_rounded,
                color: colorScheme.primary,
                size: 40,
              ),
              title: Text(
                displayName,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                subtitleText,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: folder.path == 'imported'
                  ? null
                  : IconButton(
                      tooltip: l10n.removeFolder,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.removeFolderConfirmTitle),
                            content: Text(
                              l10n.removeFolderConfirmMessage(displayName),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ref
                              .read(appDatabaseProvider)
                              .deleteLocalFolder(folder.path);
                        }
                      },
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocalFolderDetailScreen(
                      rootLocator: folder.path,
                      currentPath: folder.path,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(l10n.error(e.toString()))),
    );
  }
}
