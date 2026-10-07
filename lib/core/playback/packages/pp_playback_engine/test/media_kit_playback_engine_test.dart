import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' show VideoParams, SubtitleTrack;
import 'package:media_kit_video/media_kit_video.dart' show VideoController;
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt;
import 'fake_youtube_controller.dart';

/// Fake adapter that implements INativePlayerAdapter for production engine tests.
/// All streams are controllable via their backing StreamControllers.
class _CapturingStream<T> extends Stream<T> {
  final Stream<T> _source;
  void Function(T)? capturedOnData;

  _CapturingStream(this._source);

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (onData != null) capturedOnData = onData;
    return _source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class FakeNativeAdapter implements INativePlayerAdapter {
  final _playingCtrl = StreamController<bool>.broadcast();
  final _bufferingCtrl = StreamController<bool>.broadcast();
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _durationCtrl = StreamController<Duration>.broadcast();
  final _bufferCtrl = StreamController<Duration>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();
  final _completedCtrl = StreamController<bool>.broadcast();
  final _videoParamsCtrl = StreamController<VideoParams>.broadcast();

  // Observability counters.
  int opens = 0;
  int plays = 0;
  int pauses = 0;
  int stops = 0;
  int disposes = 0;
  bool _disposed = false;
  final Completer<void>? openCompleter; // null = complete immediately
  bool closeStreamsOnDispose = true;
  Completer<void>? stopCompleter;

  FakeNativeAdapter({this.openCompleter});

  late final _capturingPlayingStream = _CapturingStream<bool>(
    _playingCtrl.stream,
  );
  void Function(bool)? get capturedPlayingCallback =>
      _capturingPlayingStream.capturedOnData;

  @override
  VideoController? get videoController => null;
  @override
  Stream<bool> get playingStream => _capturingPlayingStream;
  @override
  Stream<bool> get bufferingStream => _bufferingCtrl.stream;
  @override
  Stream<Duration> get positionStream => _positionCtrl.stream;
  @override
  Stream<Duration> get durationStream => _durationCtrl.stream;
  @override
  Stream<Duration> get bufferStream => _bufferCtrl.stream;
  @override
  Stream<String> get errorStream => _errorCtrl.stream;
  @override
  Stream<bool> get completedStream => _completedCtrl.stream;
  @override
  Stream<VideoParams> get videoParamsStream => _videoParamsCtrl.stream;

  @override
  Future<void> open(
    String uri, {
    bool play = false,
    Map<String, String>? httpHeaders,
  }) async {
    opens++;
    if (openCompleter != null) await openCompleter!.future;
    if (!_disposed) _bufferingCtrl.add(true);
  }

  @override
  Future<void> play() async {
    plays++;
    if (!_disposed) _playingCtrl.add(true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    if (!_disposed) _playingCtrl.add(false);
  }

  @override
  Future<void> stop() async {
    stops++;
    await stopCompleter?.future;
    if (!_disposed) _playingCtrl.add(false);
  }

  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setVolume(double volume100) async {}
  @override
  Future<void> setRate(double rate) async {}
  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async {}

  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {}
  @override
  Future<void> setSubtitleDelay(Duration delay) async {}
  @override
  bool get supportsExternalSubtitles => false;
  @override
  bool get supportsSubtitleBackgroundStyling => false;
  @override
  bool get supportsSubtitleDelay => false;
  @override
  bool get supportsSubtitleTextSize => false;
  @override
  bool get supportsTrackSelection => false;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    disposes++;
    if (closeStreamsOnDispose) {
      await _playingCtrl.close();
      await _bufferingCtrl.close();
      await _positionCtrl.close();
      await _durationCtrl.close();
      await _bufferCtrl.close();
      await _errorCtrl.close();
      await _completedCtrl.close();
      await _videoParamsCtrl.close();
    }
  }
}

const track = PlaybackTrack(id: 'videoAAAAAA', title: 'A');
const other = PlaybackTrack(id: 'videoBBBBBB', title: 'B');

void main() {
  late MediaKitPlaybackEngine engine;
  late List<PlaybackStatus> statuses;
  late StreamSubscription<PlaybackStatus> subscription;
  setUp(() {
    MediaKitPlaybackEngine.isActivityStopped = false;
    engine = MediaKitPlaybackEngine();
    statuses = [];
    subscription = engine.statusStream.listen(statuses.add);
  });
  tearDown(() async {
    engine.dispose();
    await subscription.cancel();
    MediaKitPlaybackEngine.isActivityStopped = false;
  });

  // ---------------------------------------------------------------------------
  // Session isolation regression tests
  // ---------------------------------------------------------------------------
  group('session isolation (production engine)', () {
    late List<FakeNativeAdapter> adapters;

    setUp(() {
      adapters = [];
      engine.dispose();
      engine = MediaKitPlaybackEngine(

        nativeAdapterFactory: () {
          final a = FakeNativeAdapter();
          adapters.add(a);
          return a;
        },
      );
      subscription.cancel();
      statuses = [];
      subscription = engine.statusStream.listen(statuses.add);
    });

    const localTrack = PlaybackTrack(
      id: 'local-a',
      title: 'Local A',
      localMediaUri: 'file:///local/a.mp3',
      sourceType: PlaybackSourceType.local,
    );
    const localTrackB = PlaybackTrack(
      id: 'local-b',
      title: 'Local B',
      localMediaUri: 'file:///local/b.mp3',
      sourceType: PlaybackSourceType.local,
    );

    testWidgets('backward seek during startup still confirms playback', (
      tester,
    ) async {
      await engine.play(localTrack, startAt: const Duration(seconds: 30));
      adapters.last._durationCtrl.add(const Duration(minutes: 3));
      await tester.pump();
      await engine.seekTo(const Duration(seconds: 5));
      adapters.last._positionCtrl.add(const Duration(seconds: 5));
      await tester.pump();
      adapters.last._positionCtrl.add(const Duration(seconds: 6));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(engine.currentStatus.state, PlaybackState.playing);
      expect(engine.currentStatus.error, isNull);
    });

    testWidgets('seek acknowledgement alone does not hide stalled startup', (
      tester,
    ) async {
      await engine.play(localTrack, startAt: const Duration(seconds: 30));
      adapters.last._durationCtrl.add(const Duration(minutes: 3));
      await tester.pump();
      await engine.seekTo(const Duration(seconds: 45));
      adapters.last._positionCtrl.add(const Duration(seconds: 45));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(engine.currentStatus.state, PlaybackState.error);
      expect(engine.currentStatus.error, 'error:playback_timeout');
    });

    testWidgets('native playing without progress still times out', (
      tester,
    ) async {
      await engine.play(localTrack);
      await tester.pump();
      expect(engine.currentStatus.state, PlaybackState.playing);
      await tester.pump(const Duration(seconds: 6));
      expect(engine.currentStatus.state, PlaybackState.error);
      expect(engine.currentStatus.error, 'error:playback_timeout');
    });

    testWidgets('initial seek alone does not confirm native playback', (
      tester,
    ) async {
      await engine.play(localTrack, startAt: const Duration(seconds: 30));
      adapters.last._positionCtrl.add(const Duration(seconds: 30));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(engine.currentStatus.state, PlaybackState.error);
    });

    testWidgets('native progress beyond initial seek cancels startup timeout', (
      tester,
    ) async {
      await engine.play(localTrack, startAt: const Duration(seconds: 30));
      adapters.last._positionCtrl.add(const Duration(seconds: 31));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(engine.currentStatus.state, PlaybackState.playing);
      expect(engine.currentStatus.error, isNull);
    });
    test('local audio clears the preceding video preview', () async {
      const video = PlaybackTrack(
        id: 'local-video',
        title: 'Video',
        localMediaUri: 'file:///local/video.mp4',
        sourceType: PlaybackSourceType.local,
        isVideo: true,
      );
      await engine.play(video);
      expect(engine.currentStatus.activeVideoId, video.id);
      expect(engine.currentStatus.hasVideo, isTrue);

      await engine.play(localTrack);
      expect(engine.currentStatus.activeVideoId, isNull);
      expect(engine.currentStatus.hasVideo, isFalse);
      // Embedded album art can produce video dimensions in an audio decoder.
      adapters.last._videoParamsCtrl.add(VideoParams(w: 600, h: 600));
      await Future<void>.delayed(Duration.zero);
      expect(engine.currentStatus.activeVideoId, isNull);
      expect(engine.currentStatus.hasVideo, isFalse);
    });

    test('preparing local audio clears the preceding video preview', () async {
      const video = PlaybackTrack(id: 'local-video', title: 'Video', localMediaUri: 'file:///local/video.mp4', sourceType: PlaybackSourceType.local, isVideo: true);
      await engine.play(video);
      expect(engine.currentStatus.activeVideoId, video.id);
      await engine.prepare(localTrack);
      expect(engine.currentStatus.activeVideoId, isNull);
      expect(engine.currentStatus.hasVideo, isFalse);
      expect(engine.currentStatus.isIFrameMode, isFalse);
    });

    test(
      'delayed event from disposed session is ignored after new session opens',
      () async {
        // Play track A; get a reference to its adapter.
        final playAFuture = engine.play(localTrack);
        await playAFuture;
        final adapterA = adapters.first;
        expect(adapterA.opens, 1);

        // Switch to track B — A's session is invalidated and torn down.
        await engine.play(localTrackB);
        expect(adapters.length, 2);

        // Verify A was disposed
        expect(
          adapterA.disposes,
          1,
          reason: 'adapter A must be disposed when session is invalidated',
        );

        // Drain any pending microtask emissions from B's initialization before
        // capturing the baseline — e.g., play() signals queued but not yet delivered.
        await Future.delayed(Duration.zero);

        final statesBefore = statuses.length;

        // Simulate a delayed event from A's backend arriving now.
        // Since the stream's subscription was cancelled during teardown, we must
        // invoke the captured callback directly to prove the closure guard evaluates it
        // and rejects the event.
        expect(
          adapterA.capturedPlayingCallback,
          isNotNull,
          reason: 'Engine must have subscribed to playingStream',
        );
        adapterA.capturedPlayingCallback!(true);

        await Future.delayed(Duration.zero);

        expect(
          statuses.length,
          statesBefore,
          reason:
              'stale event from old session must not update status due to ownership guard',
        );
      },
    );

    test('same URI reopening creates a distinct session', () async {
      await engine.play(localTrack);
      final adapterA = adapters.first;

      await engine.play(localTrack); // same URI
      expect(
        adapters.length,
        2,
        reason: 'each play() must create a new adapter/session',
      );
      expect(adapters[0], isNot(same(adapters[1])));
      expect(adapterA.disposes, 1, reason: 'first adapter must be disposed');
    });

    test('initialization events during open() are retained', () async {
      // An in-flight open completer lets us fire events during the open().
      final openCompleter = Completer<void>();
      adapters.clear();
      engine.dispose();
      engine = MediaKitPlaybackEngine(
        nativeAdapterFactory: () {
          final a = FakeNativeAdapter(openCompleter: openCompleter);
          adapters.add(a);
          return a;
        },
      );
      subscription.cancel();
      statuses = [];
      subscription = engine.statusStream.listen(statuses.add);

      // Start play but don't await; open() is blocked on openCompleter.
      final playFuture = engine.play(localTrack);

      // Let the engine reach open().
      await Future.delayed(Duration.zero);
      expect(adapters.length, 1);

      // Fire a duration event DURING open() — session is already active.
      adapters[0]._durationCtrl.add(const Duration(seconds: 180));
      await Future.delayed(Duration.zero);

      // Release open().
      openCompleter.complete();
      await playFuture;

      // The duration update emitted during open() must be reflected.
      expect(
        statuses.any((s) => s.duration == const Duration(seconds: 180)),
        isTrue,
        reason: 'duration event fired during open() must be retained',
      );
    });

    test('superseded open cannot activate or update playback', () async {
      final openA = Completer<void>();
      final openB = Completer<void>();
      int adapterIndex = 0;
      engine.dispose();
      final completers = [openA, openB];
      engine = MediaKitPlaybackEngine(
        nativeAdapterFactory: () {
          final c = completers[adapterIndex++];
          final a = FakeNativeAdapter(openCompleter: c);
          adapters.add(a);
          return a;
        },
      );
      subscription.cancel();
      statuses = [];
      subscription = engine.statusStream.listen(statuses.add);

      // Start A (blocked).
      final playA = engine.play(localTrack);
      await Future.delayed(Duration.zero);

      // Start B (blocked) — supersedes A.
      final playB = engine.play(localTrackB);
      await Future.delayed(Duration.zero);

      // Complete B first.
      openB.complete();
      await playB;

      // Complete A late — its session was torn before activation.
      openA.complete();
      await playA;

      // The engine's active session must be B's.
      expect(adapters.length, 2);
      // B's adapter must have been used for open.
      expect(adapters[1].opens, 1);
      // A's adapter must have been disposed.
      expect(adapters[0].disposes, 1);

      // No event from A's session should have updated the current status to A.
      final lastStatus = statuses.last;
      expect(
        lastStatus.track?.id,
        localTrackB.id,
        reason: 'active track must be B after superseded open',
      );
    });

    test('stop during open prevents subsequent updates', () async {
      final openCompleter = Completer<void>();
      engine.dispose();
      engine = MediaKitPlaybackEngine(
        nativeAdapterFactory: () {
          final a = FakeNativeAdapter(openCompleter: openCompleter);
          adapters.add(a);
          return a;
        },
      );
      subscription.cancel();
      statuses = [];
      subscription = engine.statusStream.listen(statuses.add);

      final playFuture = engine.play(localTrack);
      await Future.delayed(Duration.zero);

      // Stop while open() is in flight.
      await engine.stop();

      // Release the open.
      openCompleter.complete();
      await playFuture;

      // After stop, state must be idle (not playing/buffering from open).
      expect(
        engine.currentStatus.state,
        PlaybackState.idle,
        reason: 'stop during open must leave engine in idle state',
      );
    });

    test('source switching stops old audio and releases subscriptions', () async {
      await engine.play(localTrack);
      final adapterA = adapters.first;
      // After opening the first track, play() was legitimately called on A.
      final playsBeforeSwitch = adapterA.plays;
      expect(
        playsBeforeSwitch,
        greaterThanOrEqualTo(1),
        reason: 'adapter A must have received play() for the first track',
      );

      await engine.play(localTrackB);

      // A must have been stopped before disposal.
      expect(
        adapterA.stops,
        1,
        reason: 'old session must stop once before a replacement opens',
      );
      expect(
        adapterA.disposes,
        1,
        reason: 'old session adapter must be disposed after switching',
      );
      // After switching, A must not have received any additional play() calls.
      expect(
        adapterA.plays,
        playsBeforeSwitch,
        reason:
            'old adapter must not receive additional play() calls after switching',
      );
      final adapterB = adapters[1];
      await engine.play(localTrack);
      expect(
        adapterA.stops,
        1,
        reason: 'queued cleanup must not stop the shared player again',
      );
      expect(
        adapterB.stops,
        1,
        reason: 'each replaced session must stop exactly once',
      );
      expect(adapterB.disposes, 1);
    });

    test(
      'replacement waits for a detached session to finish stopping',
      () async {
        await engine.play(localTrack);
        final gate = Completer<void>();
        adapters.single.stopCompleter = gate;
        final stopping = engine.stop();
        await Future<void>.delayed(Duration.zero);
        final replacement = engine.play(localTrackB);
        await Future<void>.delayed(Duration.zero);
        expect(
          adapters,
          hasLength(1),
          reason: 'do not reopen the shared native player before stop finishes',
        );
        gate.complete();
        await stopping;
        await replacement;
        expect(adapters, hasLength(2));
        expect(adapters.first.stops, 1);
        expect(adapters.last.opens, 1);
      },
    );

    test('dispose during open prevents subsequent updates', () async {
      final openCompleter = Completer<void>();
      engine.dispose();
      engine = MediaKitPlaybackEngine(
        nativeAdapterFactory: () {
          final a = FakeNativeAdapter(openCompleter: openCompleter);
          adapters.add(a);
          return a;
        },
      );
      subscription.cancel();
      statuses = [];
      subscription = engine.statusStream.listen(statuses.add);

      final playFuture = engine.play(localTrack);
      await Future.delayed(Duration.zero);

      // Dispose while open() is in flight.
      engine.dispose();

      // Release open — should be a no-op since engine is disposed.
      openCompleter.complete();
      await playFuture;

      // No playing/buffering status should have been emitted after dispose.
      final postDisposeStates =
          statuses
              .where(
                (s) =>
                    s.state == PlaybackState.playing ||
                    s.state == PlaybackState.buffering,
              )
              .toList();
      expect(
        postDisposeStates,
        isEmpty,
        reason: 'no playing/buffering updates after dispose',
      );
    });
  });
}
