import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/local_library/local_library_service.dart';
import '../../core/player/player_provider.dart';
import '../../core/services/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/context_menu/content_context_menu.dart';
import '../../shared/widgets/pp_image.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context)!;
    try {
      final result = await ref
          .read(localLibraryServiceProvider)
          .exportQueue(ref.read(playerProvider).queue);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? strings.exportCancelled
                : strings.exportComplete(result.skippedCount.toString()),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.error(error.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final autoplay = ref.watch(
      settingsProvider.select((s) => s.autoplayEnabled),
    );
    final current = state.currentTrack;
    final nextStart = current == null ? 0 : state.currentIndex + 1;
    final nextCount = state.queue.length - nextStart;
    return Scaffold(
      key: const ValueKey('queue_screen'),
      appBar: AppBar(
        title: Text(strings.queue1),
        actions: [
          IconButton(
            key: const ValueKey('autoplay_toggle_button'),
            tooltip:
                '${strings.autoplay}: ${autoplay ? strings.enabled : strings.off}',
            color: autoplay ? colors.primary : null,
            icon: const Icon(Icons.all_inclusive_rounded),
            onPressed: () =>
                ref.read(settingsProvider.notifier).toggleAutoplay(!autoplay),
          ),
          IconButton(
            key: const ValueKey('export_queue_button'),
            tooltip: strings.exportPlaylist,
            icon: const Icon(Icons.download_rounded),
            onPressed: state.queue.isEmpty ? null : () => _export(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          final inset = constraints.maxWidth >= 600 ? 40.0 : 16.0;
          return CustomScrollView(
            key: const ValueKey('queue_track_list'),
            slivers: [
              if (current != null) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 24, inset, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionTitle(strings.queueNowPlaying),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  sliver: SliverToBoxAdapter(
                    child: _QueueRow(
                      track: current,
                      index: state.currentIndex,
                      position: 0,
                      current: true,
                      playing: state.isPlaying,
                      wide: wide,
                    ),
                  ),
                ),
              ],
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 32, inset, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(strings.queueUpNext),
                ),
              ),
              if (nextCount == 0)
                SliverPadding(
                  padding: EdgeInsets.all(inset),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      strings.noTracksFound,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
                sliver: SliverReorderableList(
                  itemCount: nextCount,
                  onReorderItem: (from, to) => ref
                      .read(playerProvider.notifier)
                      // PlaybackQueue expects the insertion index before removal.
                      .reorderQueue(
                        nextStart + from,
                        nextStart + to + (to > from ? 1 : 0),
                      ),
                  itemBuilder: (context, position) {
                    final index = nextStart + position;
                    final track = state.queue[index];
                    return _QueueRow(
                      key: ValueKey(
                        track.queueItemId ?? '$index:${track.spotifyId}',
                      ),
                      track: track,
                      index: index,
                      position: position,
                      current: false,
                      playing: false,
                      wide: wide,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({
    super.key,
    required this.track,
    required this.index,
    required this.position,
    required this.current,
    required this.playing,
    required this.wide,
  });
  final Track track;
  final int index;
  final int position;
  final bool current;
  final bool playing;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final seconds = (track.durationMs ?? 0) ~/ 1000;
    final duration = seconds == 0
        ? '—'
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return ContentContextMenuRegion(
      target: TrackContextTarget(track, isInQueue: true, queueIndex: index),
      child: Material(
        color: current
            ? colors.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: colors.onSurface.withValues(alpha: 0.06),
          onTap: () => ref.read(playerProvider.notifier).skipTo(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: current
                      ? Icon(
                          playing ? Icons.equalizer : Icons.play_arrow,
                          size: 18,
                          color: colors.primary,
                        )
                      : Text(
                          '${position + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: PPImage(
                    imageUrl: track.albumImage ?? track.localArtworkPath ?? '',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: current ? colors.primary : colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (wide) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Text(
                      track.albumName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 16),
                Text(
                  duration,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (!current)
                  ReorderableDragStartListener(
                    index: position,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
