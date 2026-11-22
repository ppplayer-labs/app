import 'dart:async';
import 'dart:convert';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/playback/chromium_playback_engine.dart';

class _FallbackStub extends Fake implements PlaybackController {
  final _statuses = StreamController<PlaybackStatus>.broadcast(sync: true);
  final _events = StreamController<PlaybackEvent>.broadcast(sync: true);

  @override
  Stream<PlaybackStatus> get statusStream => _statuses.stream;
  @override
  Stream<PlaybackEvent> get eventStream => _events.stream;
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {}
  @override
  Future<void> dispose() async {
    await _statuses.close();
    await _events.close();
  }
}

class _TrackedYoutubePlayer extends Fake
    implements ChromiumYoutubePlayerController {
  final messages = StreamController<Map<String, Object?>>.broadcast(sync: true);
  final controller = ChromiumWebViewController();
  Completer<void>? initGate;
  int disposeCount = 0;

  @override
  Stream<Map<String, Object?>> get events => messages.stream;
  @override
  ChromiumWebViewController get webViewController => controller;
  @override
  Future<void> initialize() async {
    await initGate?.future;
  }

  @override
  Future<void> setVolume(int volume) async {}
  @override
  Future<void> loadVideoById({
    required String videoId,
    double startSeconds = 0,
    double? endSeconds,
  }) async {}
  @override
  Future<void> cueVideoById({
    required String videoId,
    double startSeconds = 0,
    double? endSeconds,
  }) async {}
  @override
  Future<void> pauseVideo() async {}
  @override
  Future<void> playVideo() async {}
  @override
  Future<void> seekTo({
    required double seconds,
    bool allowSeekAhead = true,
  }) async {}
  @override
  Future<double> get duration async => 120;
  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

void main() {
  test(
    'malformed VideoState JSON does not crash ChromiumPlaybackEngine',
    () async {
      final fallback = _FallbackStub();
      final player = _TrackedYoutubePlayer();
      final engine = ChromiumPlaybackEngine(
        fallback: fallback,
        initializeCef: () async {},
        createPlayer: () => player,
      );
      addTearDown(() async {
        await engine.dispose();
        await player.messages.close();
      });

      await engine.play(const PlaybackTrack(id: 'M7lc1UVf-VE', title: 'Test'));

      expect(
        () => player.messages.add({'VideoState': '{not-valid-json'}),
        returnsNormally,
      );
      player.messages.add({
        'VideoState': jsonEncode({'currentTime': 12.5, 'loadedFraction': 0.5}),
      });
      expect(
        engine.currentStatus.position,
        const Duration(milliseconds: 12500),
      );
    },
  );

  test(
    'superseded player initialized concurrently is disposed without leaking',
    () async {
      final fallback = _FallbackStub();
      final created = <_TrackedYoutubePlayer>[];
      final firstGate = Completer<void>();

      final engine = ChromiumPlaybackEngine(
        fallback: fallback,
        initializeCef: () async {},
        createPlayer: () {
          final player = _TrackedYoutubePlayer();
          if (created.isEmpty) {
            player.initGate = firstGate;
          }
          created.add(player);
          return player;
        },
      );
      addTearDown(() async {
        await engine.dispose();
        for (final p in created) {
          await p.messages.close();
        }
      });

      final firstPlay = engine.play(
        const PlaybackTrack(id: 'M7lc1UVf-VE', title: 'First'),
      );
      await Future<void>.delayed(Duration.zero);

      // Supersede while first player.initialize() is still pending.
      await engine.stop();
      expect(created, hasLength(1));
      expect(created.first.disposeCount, 1);

      // Release gate: superseded _open() must exit cleanly and not leave an active listener.
      firstGate.complete();
      await firstPlay;
      expect(created.first.messages.hasListener, isFalse);
    },
  );

  test(
    '100 rapid play/seek/pause/stop cycles leak zero players or listeners',
    () async {
      final fallback = _FallbackStub();
      final created = <_TrackedYoutubePlayer>[];
      final engine = ChromiumPlaybackEngine(
        fallback: fallback,
        initializeCef: () async {},
        createPlayer: () {
          final player = _TrackedYoutubePlayer();
          created.add(player);
          return player;
        },
      );

      for (var i = 0; i < 100; i++) {
        final track = PlaybackTrack(id: 'M7lc1UVf-V${i % 10}', title: 'T$i');
        await engine.play(track);
        await engine.seekTo(Duration(seconds: i % 30));
        await engine.pause();
        await engine.stop();
      }

      await engine.dispose();
      for (final p in created) {
        expect(p.disposeCount, greaterThanOrEqualTo(1));
        expect(p.messages.hasListener, isFalse);
        await p.messages.close();
      }
      expect(created, hasLength(100));
    },
  );
}
