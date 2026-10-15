import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/db/app_database.dart';
import '../../core/network_streams/network_stream_service.dart';
import '../../core/player/player_provider.dart';
import '../../core/models/track.dart';
import '../../shared/widgets/animated_equalizer.dart';
import '../../shared/widgets/empty_results_widget.dart';
import '../../shared/widgets/pp_image.dart';
import '../../shared/widgets/pp_logo_loader.dart';

class _StreamMetadata {
  static String? extractQuality(String title, {String? tvgId}) {
    final combined = '$title ${tvgId ?? ''}'.toUpperCase();
    if (combined.contains('4K') || combined.contains('UHD')) return '4K';
    if (combined.contains('1080P') || combined.contains('FHD')) return '1080p';
    if (combined.contains('720P') ||
        combined.contains('@HD') ||
        combined.contains(' HD')) {
      return '720p';
    }
    if (combined.contains('576P') ||
        combined.contains('480P') ||
        combined.contains('@SD') ||
        combined.contains(' SD')) {
      return 'SD';
    }
    return null;
  }

  static String extractFormat(String url) {
    final clean = url.split('?').first.split('|').first.toLowerCase();
    if (clean.endsWith('.m3u8')) return 'HLS';
    if (clean.endsWith('.mpd')) return 'DASH';
    if (clean.endsWith('.ts')) return 'TS';
    if (clean.endsWith('.mp4')) return 'MP4';
    if (clean.endsWith('.mp3')) return 'MP3';
    return 'LIVE';
  }

  static String? extractDomain(String url) {
    try {
      final clean = url.split('|').first;
      final uri = Uri.parse(clean);
      return uri.host.isNotEmpty ? uri.host : null;
    } catch (_) {
      return null;
    }
  }
}

class StreamPlaylistDetailScreen extends ConsumerStatefulWidget {
  final int playlistId;

  const StreamPlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<StreamPlaylistDetailScreen> createState() =>
      _StreamPlaylistDetailScreenState();
}

class _StreamPlaylistDetailScreenState
    extends ConsumerState<StreamPlaylistDetailScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedGroup = 'All';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Track _channelToTrack(StreamChannel channel) {
    return Track.fromNetworkStream(
      streamUrl: channel.streamUrl,
      title: channel.title,
      liveStatus: StreamLiveStatus.fromValue(channel.liveStatus),
      groupTitle: channel.groupTitle ?? 'IPTV',
      logoUrl: channel.logo,
    );
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final service = ref.read(networkStreamServiceProvider);
      final count = await service.refreshPlaylist(widget.playlistId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? AppLocalizations.of(context)!.addedChannels(count.toString())
                : 'Playlist refreshed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh playlist: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _playAll(List<StreamChannel> channels, {bool shuffle = false}) {
    if (channels.isEmpty) return;
    final tracks = channels.map(_channelToTrack).toList();
    if (shuffle) {
      ref.read(playerProvider.notifier).shuffleAndPlay(tracks);
    } else {
      ref
          .read(playerProvider.notifier)
          .playTrack(tracks.first, queue: tracks, queueIndex: 0);
    }
  }

  void _addAllToQueue(BuildContext context, List<StreamChannel> channels) {
    if (channels.isEmpty) return;
    final tracks = channels.map(_channelToTrack).toList();
    ref.read(playerProvider.notifier).addTracksToQueue(tracks);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tracks.length} ${AppLocalizations.of(context)!.addedToQueue.toLowerCase()}',
        ),
      ),
    );
  }

  void _editPlaylist(
    BuildContext context,
    StreamPlaylist playlist,
  ) {
    final controller = TextEditingController(text: playlist.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editPlaylist),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.sortTitle,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(networkStreamServiceProvider)
                    .updatePlaylist(widget.playlistId, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _deletePlaylist(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlaylist),
        content: Text(AppLocalizations.of(context)!.deletePlaylistConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref
                  .read(networkStreamServiceProvider)
                  .deletePlaylist(widget.playlistId);
              Navigator.pop(ctx);
              if (context.mounted) {
                context.pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _editChannel(BuildContext context, StreamChannel channel) {
    final titleController = TextEditingController(text: channel.title);
    final urlController = TextEditingController(text: channel.streamUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editStreamItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.sortTitle,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.streamUrl,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty &&
                  urlController.text.trim().isNotEmpty) {
                ref
                    .read(networkStreamServiceProvider)
                    .updateChannel(
                      channel.id,
                      titleController.text.trim(),
                      urlController.text.trim(),
                    );
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(networkStreamServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currentTrack = ref.watch(
      playerProvider.select((s) => s.currentTrack),
    );
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));

    return StreamBuilder<StreamPlaylist>(
      stream: service.watchPlaylist(widget.playlistId),
      builder: (context, playlistSnap) {
        final playlist = playlistSnap.data;
        if (playlist == null) {
          if (playlistSnap.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.networkStream),
              ),
              body: const Center(child: PPLogoLoader()),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.networkStream),
            ),
            body: Center(
              child: EmptyResultsWidget(
                icon: Icons.error_outline_rounded,
                message: AppLocalizations.of(context)!.noResultsFound,
              ),
            ),
          );
        }

        return StreamBuilder<List<StreamChannel>>(
          stream: service.watchChannelsForPlaylist(widget.playlistId),
          builder: (context, snap) {
            final allChannels = snap.data ?? [];
            final isLoading = snap.connectionState == ConnectionState.waiting;

            // Extract groups for category filtering
            final groups = <String>{'All'};
            for (final c in allChannels) {
              if (c.groupTitle != null && c.groupTitle!.trim().isNotEmpty) {
                groups.add(c.groupTitle!.trim());
              }
            }

            final filteredChannels = allChannels.where((c) {
              if (_selectedGroup != 'All' && c.groupTitle != _selectedGroup) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final matchTitle = c.title.toLowerCase().contains(_searchQuery);
                final matchGroup =
                    c.groupTitle?.toLowerCase().contains(_searchQuery) ?? false;
                final matchTvgId =
                    c.tvgId?.toLowerCase().contains(_searchQuery) ?? false;
                final matchUrl =
                    c.streamUrl.toLowerCase().contains(_searchQuery);
                if (!matchTitle && !matchGroup && !matchTvgId && !matchUrl) {
                  return false;
                }
              }
              return true;
            }).toList();

            return Scaffold(
              appBar: AppBar(
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '${AppLocalizations.of(context)!.search}...',
                          border: InputBorder.none,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      )
                    : Text(playlist.title),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isSearching
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh playlist',
                    onPressed: _isRefreshing ? null : _refresh,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'play_all':
                          _playAll(filteredChannels);
                          break;
                        case 'shuffle':
                          _playAll(filteredChannels, shuffle: true);
                          break;
                        case 'add_all_queue':
                          _addAllToQueue(context, filteredChannels);
                          break;
                        case 'edit':
                          _editPlaylist(context, playlist);
                          break;
                        case 'delete':
                          _deletePlaylist(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (filteredChannels.isNotEmpty) ...[
                        PopupMenuItem(
                          value: 'play_all',
                          child: Row(
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.playAll),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'shuffle',
                          child: const Row(
                            children: [
                              Icon(Icons.shuffle_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Shuffle'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'add_all_queue',
                          child: Row(
                            children: [
                              const Icon(Icons.queue_music_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.addToQueue),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                      ],
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.editPlaylist),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.deletePlaylist,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Category filter chips if multiple groups exist
                  if (groups.length > 2)
                    Container(
                      height: 44,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groups.length,
                        itemBuilder: (context, i) {
                          final grp = groups.elementAt(i);
                          final isSelected = _selectedGroup == grp;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(grp),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedGroup = grp);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  // Header bar showing channel count and quick play all button
                  if (allChannels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            filteredChannels.length == allChannels.length
                                ? '${allChannels.length} ${allChannels.length == 1 ? "channel" : "channels"}'
                                : '${filteredChannels.length} of ${allChannels.length} channels',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (filteredChannels.isNotEmpty)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: Text(AppLocalizations.of(context)!.playAll),
                              onPressed: () => _playAll(filteredChannels),
                            ),
                        ],
                      ),
                    ),

                  // Channel list or state view
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (isLoading) {
                          return const Center(child: PPLogoLoader());
                        }

                        if (allChannels.isEmpty) {
                          return Center(
                            child: EmptyResultsWidget(
                              icon: Icons.connected_tv_rounded,
                              message: AppLocalizations.of(context)!.noResultsFound,
                            ),
                          );
                        }

                        if (filteredChannels.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EmptyResultsWidget(
                                  icon: Icons.search_off_rounded,
                                  message:
                                      'No channels match "${_searchController.text.trim()}"',
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _selectedGroup = 'All';
                                    });
                                  },
                                  child: const Text('Clear filter'),
                                ),
                              ],
                            ),
                          );
                        }

                        final allTracks =
                            filteredChannels.map(_channelToTrack).toList();

                        return ListView.builder(
                          itemCount: filteredChannels.length,
                          itemBuilder: (context, index) {
                            final channel = filteredChannels[index];
                            final isCurrent =
                                currentTrack?.networkStreamUrl ==
                                    channel.streamUrl;
                            final qualityBadge = _StreamMetadata.extractQuality(
                              channel.title,
                              tvgId: channel.tvgId,
                            );
                            final formatBadge =
                                _StreamMetadata.extractFormat(channel.streamUrl);
                            final domain =
                                _StreamMetadata.extractDomain(channel.streamUrl);

                            return Dismissible(
                              key: ValueKey(channel.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) {
                                service.deleteChannel(channel.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${AppLocalizations.of(context)!.removedFromPlaylist}: ${channel.title}',
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: channel.logo != null &&
                                            channel.logo!.isNotEmpty
                                        ? PPImage(
                                            imageUrl: channel.logo!,
                                            fit: BoxFit.contain,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          )
                                        : Container(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              Icons.tv_rounded,
                                              color: isCurrent
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurfaceVariant,
                                              size: 24,
                                            ),
                                          ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    if (isCurrent && isPlaying) ...[
                                      AnimatedEqualizer(
                                        color: colorScheme.primary,
                                        size: 14,
                                        animating: true,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        channel.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? colorScheme.primary
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 3.0),
                                  child: Row(
                                    children: [
                                      if (qualityBadge != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            qualityBadge,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          formatBadge,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      if (channel.groupTitle != null) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            channel.groupTitle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ] else if (domain != null) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            domain,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 20,
                                  ),
                                  onSelected: (val) {
                                    final track = _channelToTrack(channel);
                                    if (val == 'play_next') {
                                      ref
                                          .read(playerProvider.notifier)
                                          .playNext(track);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${channel.title} ${AppLocalizations.of(context)!.addedToQueue.toLowerCase()}',
                                          ),
                                        ),
                                      );
                                    } else if (val == 'add_queue') {
                                      ref
                                          .read(playerProvider.notifier)
                                          .addToQueue(track);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${channel.title} ${AppLocalizations.of(context)!.addedToQueue.toLowerCase()}',
                                          ),
                                        ),
                                      );
                                    } else if (val == 'edit') {
                                      _editChannel(context, channel);
                                    } else if (val == 'delete') {
                                      service.deleteChannel(channel.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'play_next',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.playlist_play_rounded,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Play next'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'add_queue',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.queue_music_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.addToQueue,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.editStreamItem,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  ref.read(playerProvider.notifier).playTrack(
                                        allTracks[index],
                                        queue: allTracks,
                                        queueIndex: index,
                                      );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
