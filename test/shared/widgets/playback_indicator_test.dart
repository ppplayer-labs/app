import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/shared/widgets/animated_equalizer.dart';

const _a = Track(spotifyId: 'a', name: 'A', artistId: 'x', artistName: 'X');
const _b = Track(spotifyId: 'b', name: 'B', artistId: 'x', artistName: 'X');

/// Engine-free notifier: state is set the way the engine sync would set it.
class _FakePlayer extends PlayerNotifier {
  int resumes = 0;
  final List<String> played = [];

  @override
  PlayerState build() => const PlayerState(
    playbackQueue: PlaybackQueue(tracks: [_a, _b], currentIndex: 0),
  );

  void setPlaying(bool v, {bool loading = false, String? error}) {
    state = state.copyWith(
      isPlaying: v,
      isLoadingVideo: loading,
      loadError: error,
      clearLoadError: error == null,
    );
  }

  void setIndex(int i) => state = state.copyWith(
    playbackQueue: state.playbackQueue.copyWith(currentIndex: i),
  );

  @override
  Future<void> resume() async {
    resumes++;
    setPlaying(true);
  }

  @override
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    bool isRetry = false,
    String? contextArtistId,
    Duration? position,
    int? queueIndex,
  }) async {
    played.add(track.spotifyId);
    final q = queue ?? [track];
    state = state.copyWith(
      playbackQueue: state.playbackQueue.copyWith(
        tracks: q,
        currentIndex:
            queueIndex ?? q.indexWhere((t) => t.spotifyId == track.spotifyId),
      ),
      isLoadingVideo: true,
    );
  }
}

AnimatedEqualizer _eq(WidgetTester t) =>
    t.widget<AnimatedEqualizer>(find.byType(AnimatedEqualizer));

void main() {
  group('PlaybackIndicator', () {
    testWidgets('follows playing → paused → resumed and track changes', (
      tester,
    ) async {
      final player = _FakePlayer();
      final container = ProviderContainer(
        overrides: [playerProvider.overrideWith(() => player)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final current = ref.watch(
                  playerProvider.select((s) => s.currentTrack),
                );
                // Indicator only on the currently active track, like a tile.
                return Column(
                  children: [
                    if (current?.spotifyId == 'a')
                      const PlaybackIndicator(color: Colors.red),
                    if (current?.spotifyId == 'b')
                      const PlaybackIndicator(color: Colors.blue),
                  ],
                );
              },
            ),
          ),
        ),
      );
      container.read(playerProvider.notifier);

      player.setPlaying(true);
      await tester.pump();
      expect(_eq(tester).animating, isTrue);
      expect(tester.hasRunningAnimations, isTrue);

      player.setPlaying(false);
      await tester.pump();
      expect(_eq(tester).animating, isFalse);
      expect(tester.hasRunningAnimations, isFalse); // static, no ticking

      player.setPlaying(true);
      await tester.pump();
      expect(_eq(tester).animating, isTrue);
      expect(tester.hasRunningAnimations, isTrue);

      // Track changed: indicator moves to the new active track.
      player.setIndex(1);
      await tester.pump();
      expect(find.byType(AnimatedEqualizer), findsOneWidget);
      expect(_eq(tester).color, Colors.blue);

      // Stopped: no current track → no indicator.
      player.state = const PlayerState();
      await tester.pump();
      expect(find.byType(AnimatedEqualizer), findsNothing);
    });
  });

  group('handleTapOnCurrentTrack', () {
    late _FakePlayer player;
    late ProviderContainer container;
    setUp(() {
      player = _FakePlayer();
      container = ProviderContainer(
        overrides: [playerProvider.overrideWith(() => player)],
      );
      addTearDown(container.dispose);
      container.read(playerProvider);
    });

    test('paused current track resumes', () {
      expect(player.handleTapOnCurrentTrack(_a), isTrue);
      expect(player.resumes, 1);
    });

    test('playing current track does not restart or resume', () {
      player.setPlaying(true);
      expect(player.handleTapOnCurrentTrack(_a), isTrue);
      expect(player.resumes, 0);
      expect(player.played, isEmpty);
    });

    test('a different track is not handled (caller starts it)', () {
      expect(player.handleTapOnCurrentTrack(_b), isFalse);
      expect(player.resumes, 0);
    });

    test('loading current track ignores duplicate taps', () {
      player.setPlaying(false, loading: true);
      expect(player.handleTapOnCurrentTrack(_a), isTrue);
      expect(player.handleTapOnCurrentTrack(_a), isTrue);
      expect(player.resumes, 0);
    });

    test('errored current track is left to the caller to restart', () {
      player.setPlaying(false, error: 'boom');
      expect(player.handleTapOnCurrentTrack(_a), isFalse);
    });

    test('rapid selection: last tap wins, repeats are deduped', () async {
      // Tap B, B again (duplicate), then A: only B once, then A.
      Future<void> tap(Track t, int i) async {
        if (!player.handleTapOnCurrentTrack(t)) {
          await player.playTrack(t, queue: [_a, _b], queueIndex: i);
        }
      }

      await tap(_b, 1);
      await tap(_b, 1);
      await tap(_a, 0);
      expect(player.played, ['b', 'a']);
      expect(player.resumes, 0);
      expect(container.read(playerProvider).currentTrack, _a);
    });

    test('queue skipTo on the playing current index does not restart', () {
      player.setPlaying(true);
      player.skipTo(0);
      expect(player.played, isEmpty);
      player.skipTo(1);
      expect(player.played, ['b']);
    });
  });
}
