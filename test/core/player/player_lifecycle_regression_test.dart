import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/network_streams/network_stream_service.dart';
import 'package:ppplayer/core/playback/pip_handler.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/services/settings_provider.dart';

class _RecordingPlaybackController implements PlaybackController {
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _eventController = StreamController<PlaybackEvent>.broadcast();
  PlaybackStatus _status = const PlaybackStatus();
  final List<String> calls = [];

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;
  @override
  Stream<PlaybackEvent> get eventStream => _eventController.stream;
  @override
  PlaybackStatus get currentStatus => _status;
  @override
  dynamic get renderer => null;
  @override
  bool get supportsSpeed => true;
  @override
  bool get supportsTrackSelection => false;
  @override
  bool get supportsExternalSubtitles => false;
  @override
  bool get supportsSubtitleDelay => false;
  @override
  bool get supportsSubtitleTextSize => false;
  @override
  bool get supportsSubtitleBackgroundStyling => false;
  @override
  bool get supportsVideoFitMode => false;

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {
    calls.add('play:${track.id}');
    _status = _status.copyWith(
      track: track,
      state: play ? PlaybackState.playing : PlaybackState.paused,
      position: startAt,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {
    calls.add('prepare:${track.id}');
  }

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    calls.add('pause');
    _status = _status.copyWith(state: PlaybackState.paused);
    _statusController.add(_status);
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _status = const PlaybackStatus(state: PlaybackState.idle);
    _statusController.add(_status);
  }

  @override
  Future<void> seekTo(Duration position) async {
    calls.add('seek:${position.inMilliseconds}');
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setSubtitleTrack(String? uri) async {}
  @override
  Future<void> setSubtitleDelay(Duration delay) async {}
  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {}

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _eventController.close();
  }
}

class _StubPlaybackService extends Fake implements PlaybackService {
  @override
  Future<void> recordPlay(Track track) async {}
}

class _SlowNetworkStreamService extends Fake implements NetworkStreamService {
  final Map<String, Completer<ExtractedStream?>> gates = {};

  @override
  Future<ExtractedStream?> extractDirectStreamUrl(String videoUrl) async {
    final gate = gates[videoUrl];
    if (gate != null) {
      return gate.future;
    }
    return ExtractedStream(url: videoUrl);
  }
}

class _NoOpSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState(
    selectedCountry: 'US',
    showVideo: true,
    themeIndex: 0,
    performanceMode: PerformanceMode.high,
    lowDataMode: false,
    autoplayEnabled: false,
    isLoaded: true,
  );
}

void main() {
  late Directory hiveDir;

  setUp(() async {
    PipHandler.resetForTest();
    hiveDir = await Directory.systemTemp.createTemp('ppplayer_lifecycle_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    PipHandler.resetForTest();
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test(
    'PlayerNotifier unregisters all PipHandler listeners on dispose across 100 cycles',
    () async {
      final pendingPersistence = <Future<void>>[];
      for (var i = 0; i < 100; i++) {
        final controller = _RecordingPlaybackController();
        final container = ProviderContainer(
          overrides: [
            playbackControllerProvider.overrideWithValue(controller),
            playbackServiceProvider.overrideWithValue(_StubPlaybackService()),
            networkStreamServiceProvider.overrideWithValue(
              _SlowNetworkStreamService(),
            ),
            settingsProvider.overrideWith(_NoOpSettingsNotifier.new),
          ],
        );

        final notifier = container.read(playerProvider.notifier);
        pendingPersistence.add(notifier.persistenceSettled);
        container.dispose();
        await controller.dispose();
      }

      // Wait for all fire-and-forget Hive restore futures to settle before
      // tearDown closes Hive and deletes the Windows temp directory.
      await Future.wait(pendingPersistence);

      // If any disposed PlayerNotifier closure remained registered, these calls
      // would throw StateError from mutating a disposed Riverpod Notifier.
      expect(() => PipHandler.simulatePipModeChanged(true), returnsNormally);
      expect(() => PipHandler.simulatePipEntryRequested(), returnsNormally);
      expect(() => PipHandler.simulatePipEntryFailed(), returnsNormally);
      expect(() => PipHandler.simulateActivityStopped(), returnsNormally);
    },
  );

  test('skipPrevious on an empty queue does not throw RangeError', () async {
    final controller = _RecordingPlaybackController();
    final container = ProviderContainer(
      overrides: [
        playbackControllerProvider.overrideWithValue(controller),
        playbackServiceProvider.overrideWithValue(_StubPlaybackService()),
        networkStreamServiceProvider.overrideWithValue(
          _SlowNetworkStreamService(),
        ),
        settingsProvider.overrideWith(_NoOpSettingsNotifier.new),
      ],
    );
    final notifier = container.read(playerProvider.notifier);
    addTearDown(() async {
      container.dispose();
      await notifier.persistenceSettled;
      await controller.dispose();
    });

    expect(() => notifier.skipPrevious(), returnsNormally);
    expect(controller.calls, isEmpty);
  });

  test(
    'stale extractDirectStreamUrl completion does not stop a newer track',
    () async {
      final controller = _RecordingPlaybackController();
      final streamService = _SlowNetworkStreamService();
      final slowGate = Completer<ExtractedStream?>();
      streamService.gates['https://example.com/slow.m3u8'] = slowGate;

      final container = ProviderContainer(
        overrides: [
          playbackControllerProvider.overrideWithValue(controller),
          playbackServiceProvider.overrideWithValue(_StubPlaybackService()),
          networkStreamServiceProvider.overrideWithValue(streamService),
          settingsProvider.overrideWith(_NoOpSettingsNotifier.new),
        ],
      );
      final notifier = container.read(playerProvider.notifier);
      addTearDown(() async {
        container.dispose();
        await notifier.persistenceSettled;
        await controller.dispose();
      });
      final slowTrack = Track(
        spotifyId: 'stream_slow',
        name: 'Slow Stream',
        artistName: 'Test',
        artistId: '',
        sourceType: TrackSourceType.networkStream,
        networkStreamUrl: 'https://example.com/slow.m3u8',
      );
      final fastTrack = Track(
        spotifyId: 'stream_fast',
        name: 'Fast Stream',
        artistName: 'Test',
        artistId: '',
        sourceType: TrackSourceType.networkStream,
        networkStreamUrl: 'https://example.com/fast.m3u8',
      );

      final slowFuture = notifier.playTrack(slowTrack);
      await Future<void>.delayed(Duration.zero);

      await notifier.playTrack(fastTrack);
      final callsAfterFast = List<String>.from(controller.calls);
      expect(callsAfterFast, contains('play:stream_fast'));

      // Complete the stale extraction from track 1.
      slowGate.complete(
        const ExtractedStream(url: 'https://example.com/resolved-slow.m3u8'),
      );
      await slowFuture;

      // Track 2 must NOT have been stopped or replaced by the stale extraction.
      expect(controller.calls, equals(callsAfterFast));
      expect(controller.currentStatus.track?.id, 'stream_fast');
    },
  );

  test('PlaybackQueue.fromJson clamps corrupted indices and repeatMode', () {
    final queue = PlaybackQueue.fromJson({
      'tracks': [
        {
          'spotifyId': 't1',
          'name': 'Track 1',
          'artistName': 'Artist',
          'artistId': '',
          'albumName': '',
          'albumId': '',
          'imageUrl': '',
        },
      ],
      'currentIndex': 999,
      'repeatMode': 42,
      'isShuffled': 'not-a-bool',
    });

    expect(queue.currentIndex, 0);
    expect(queue.repeatMode, RepeatMode.all);
    expect(queue.isShuffled, isFalse);
  });
}
