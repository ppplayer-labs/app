import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/playback/chromium_playback_engine.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/tactile_buttons.dart';

class _StubFallbackController extends Fake implements PlaybackController {
  final _statuses = StreamController<PlaybackStatus>.broadcast(sync: true);
  final _events = StreamController<PlaybackEvent>.broadcast(sync: true);

  @override
  Stream<PlaybackStatus> get statusStream => _statuses.stream;

  @override
  Stream<PlaybackEvent> get eventStream => _events.stream;

  @override
  PlaybackStatus get currentStatus => const PlaybackStatus();

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _statuses.close();
    await _events.close();
  }
}

class _FakeYoutubePlayer extends Fake implements ChromiumYoutubePlayerController {
  final messages = StreamController<Map<String, Object?>>.broadcast(sync: true);
  final calls = <String>[];
  final controller = ChromiumWebViewController();
  bool disposed = false;

  @override
  Stream<Map<String, Object?>> get events => messages.stream;

  @override
  ChromiumWebViewController get webViewController => controller;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadVideoById({
    required String videoId,
    double startSeconds = 0,
    double? endSeconds,
  }) async {
    calls.add('load:$videoId:${startSeconds.round()}');
  }

  @override
  Future<void> cueVideoById({
    required String videoId,
    double startSeconds = 0,
    double? endSeconds,
  }) async {
    calls.add('cue:$videoId:${startSeconds.round()}');
  }

  @override
  Future<void> pauseVideo() async {
    calls.add('pause');
  }

  @override
  Future<void> playVideo() async {
    calls.add('play');
  }

  @override
  Future<void> seekTo({
    required double seconds,
    bool allowSeekAhead = true,
  }) async {
    calls.add('seek:${seconds.round()}');
  }

  @override
  Future<void> setVolume(int volume) async {
    calls.add('volume:$volume');
  }

  @override
  Future<double> get duration async => 180.0;

  @override
  Future<void> dispose() async {
    disposed = true;
    calls.add('dispose');
    await messages.close();
  }
}

void main() {
  const youtubeTrack = PlaybackTrack(
    id: 'dQw4w9WgXcQ',
    title: 'Perf Test Video',
    artist: 'Test Artist',
    sourceType: PlaybackSourceType.online,
  );

  group('ChromiumPlaybackEngine idle reclamation and surface visibility', () {
    test('reclaims paused browser after idle delay and transparently resumes at saved position', () async {
      final fallback = _StubFallbackController();
      final created = <_FakeYoutubePlayer>[];
      final engine = ChromiumPlaybackEngine(
        fallback: fallback,
        initializeCef: () async {},
        createPlayer: () {
          final player = _FakeYoutubePlayer();
          created.add(player);
          return player;
        },
        idleBrowserReleaseDelay: const Duration(milliseconds: 80),
      );
      addTearDown(engine.dispose);

      await engine.play(youtubeTrack);
      expect(created.length, 1);
      expect(engine.hasActiveBrowser, isTrue);

      created.first.messages.add({'StateChange': 1});
      created.first.messages.add({
        'VideoState': jsonEncode({'currentTime': 42.0, 'loadedFraction': 0.5}),
      });
      expect(engine.isRenderingActive, isTrue);

      await engine.pause();
      created.first.messages.add({'StateChange': 2});
      expect(engine.isRenderingActive, isFalse);
      expect(engine.hasActiveBrowser, isTrue);

      // Wait past idleBrowserReleaseDelay so the paused browser is reclaimed.
      await Future<void>.delayed(const Duration(milliseconds: 140));
      expect(engine.hasActiveBrowser, isFalse);
      expect(created.first.disposed, isTrue);
      expect(engine.currentStatus.state, PlaybackState.paused);
      expect(engine.currentStatus.track?.id, youtubeTrack.id);
      expect(engine.currentStatus.position, const Duration(seconds: 42));

      // Seeking while idle-reclaimed updates the saved position without spawning.
      await engine.seekTo(const Duration(seconds: 65));
      expect(created.length, 1);
      expect(engine.currentStatus.position, const Duration(seconds: 65));

      // Resuming transparently allocates a fresh browser at the saved position.
      await engine.resume();
      expect(created.length, 2);
      expect(engine.hasActiveBrowser, isTrue);
      expect(created.last.calls, contains('load:dQw4w9WgXcQ:65'));
    });

    test('cancels idle browser reclamation if resumed before timeout', () async {
      final fallback = _StubFallbackController();
      final created = <_FakeYoutubePlayer>[];
      final engine = ChromiumPlaybackEngine(
        fallback: fallback,
        initializeCef: () async {},
        createPlayer: () {
          final player = _FakeYoutubePlayer();
          created.add(player);
          return player;
        },
        idleBrowserReleaseDelay: const Duration(milliseconds: 120),
      );
      addTearDown(engine.dispose);

      await engine.play(youtubeTrack);
      created.first.messages.add({'StateChange': 1});
      await engine.pause();
      created.first.messages.add({'StateChange': 2});

      await Future<void>.delayed(const Duration(milliseconds: 40));
      await engine.resume();
      created.first.messages.add({'StateChange': 1});

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(created.length, 1);
      expect(created.first.disposed, isFalse);
      expect(engine.hasActiveBrowser, isTrue);
    });

    test('setSurfaceVisible suspends and restores rendering without interrupting playback', () async {
      final fallback = _StubFallbackController();
      final created = <_FakeYoutubePlayer>[];
      final engine = ChromiumPlaybackEngine(
        fallback: fallback,
        initializeCef: () async {},
        createPlayer: () {
          final player = _FakeYoutubePlayer();
          created.add(player);
          return player;
        },
      );
      addTearDown(engine.dispose);

      await engine.play(youtubeTrack);
      created.first.messages.add({'StateChange': 1});
      expect(engine.isRenderingActive, isTrue);

      engine.setSurfaceVisible(false);
      expect(engine.isRenderingActive, isFalse);
      expect(created.first.calls, isNot(contains('pause')));
      expect(engine.hasActiveBrowser, isTrue);

      engine.setSurfaceVisible(true);
      expect(engine.isRenderingActive, isTrue);
    });
  });

  group('TactilePlayerPlayPauseButton idle ticker behavior', () {
    testWidgets('settles with zero infinite tickers during steady playback', (
      tester,
    ) async {
      bool playing = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Center(
                child: TactilePlayerPlayPauseButton(
                  isPlaying: playing,
                  isLoading: false,
                  onTap: () => setState(() => playing = !playing),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Transition to playing triggers the one-shot Brand Ignition burst,
      // then settles cleanly without any continuous 60 FPS loop ticker.
      await tester.tap(find.byType(TactilePlayerPlayPauseButton));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(playing, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Transition back to paused also settles cleanly.
      await tester.tap(find.byType(TactilePlayerPlayPauseButton));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(playing, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
