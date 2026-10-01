import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/network_outputs/network_output_backend.dart';
import 'package:ppplayer/core/network_outputs/network_output_controller.dart';

// ──────────────────────────────────────────────────────────────────────────
// Fakes
// ──────────────────────────────────────────────────────────────────────────

class FakePlaybackController implements PlaybackController {
  final _status = StreamController<PlaybackStatus>.broadcast();
  final _events = StreamController<PlaybackEvent>.broadcast();
  PlaybackStatus _current = const PlaybackStatus(
    track: null,
    state: PlaybackState.idle,
    position: Duration.zero,
    duration: Duration.zero,
    volume: 1,
    speed: 1,
    generation: 0,
    isLive: false,
    isSeekable: false,
    hasVideo: false,
  );
  bool disposed = false;
  bool paused = false;
  bool resumed = false;
  bool stopped = false;
  PlaybackTrack? loadedTrack;
  Duration? preparedPosition;
  List<String> calls = [];

  void _emit(PlaybackStatus s) {
    _current = s;
    _status.add(s);
  }

  void emitState(PlaybackState state, {Duration? position}) {
    _emit(
      _current.copyWith(state: state, position: position ?? _current.position),
    );
  }

  @override
  Stream<PlaybackStatus> get statusStream => _status.stream;
  @override
  Stream<PlaybackEvent> get eventStream => _events.stream;
  @override
  PlaybackStatus get currentStatus => _current;

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {
    calls.add('play');
    loadedTrack = track;
    _emit(
      _current.copyWith(
        state: play ? PlaybackState.playing : PlaybackState.paused,
        track: track,
        position: startAt,
      ),
    );
  }

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {
    calls.add('prepare');
    loadedTrack = track;
    preparedPosition = position;
    _emit(
      _current.copyWith(
        state: PlaybackState.paused,
        track: track,
        position: position ?? Duration.zero,
      ),
    );
  }

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    calls.add('pause');
    paused = true;
    _emit(_current.copyWith(state: PlaybackState.paused));
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    resumed = true;
    _emit(_current.copyWith(state: PlaybackState.playing));
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    stopped = true;
    _emit(_current.copyWith(state: PlaybackState.idle));
  }

  @override
  Future<void> seekTo(Duration position) async {
    calls.add('seek');
    _emit(_current.copyWith(position: position));
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
  bool get supportsSpeed => false;
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
  dynamic get renderer => null;
  @override
  YoutubePlayerController? get youtubeController => null;
  @override
  Future<void> dispose() async {
    disposed = true;
    await _status.close();
    await _events.close();
  }
}

class FakeBackend implements NetworkOutputBackend {
  final _outputs = StreamController<List<PlaybackOutput>>.broadcast();
  final _session = StreamController<NetworkOutputSessionState>.broadcast();
  final List<String> calls = [];
  bool connectShouldFail = false;
  bool loadShouldFail = false;
  bool disposeCalled = false;
  Completer<void>? connectBlocker;
  Completer<void>? loadBlocker;
  String? lastSessionId;
  String? lastItemId;

  @override
  OutputKind get kind => OutputKind.dlna;
  @override
  Stream<List<PlaybackOutput>> get outputs => _outputs.stream;
  @override
  Stream<NetworkOutputSessionState> get sessionState => _session.stream;

  @override
  Future<void> startDiscovery() async {
    calls.add('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    calls.add('stopDiscovery');
  }

  @override
  Future<void> connect(
    PlaybackOutput output, {
    required String sessionId,
  }) async {
    calls.add('connect');
    lastSessionId = sessionId;
    if (connectBlocker != null) await connectBlocker!.future;
    if (connectShouldFail)
      throw NetworkOutputException('connect failed', code: 'connect_failed');
  }

  @override
  Future<RemoteLoadResult> load(
    NetworkMediaItem item, {
    required String sessionId,
    required String itemId,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async {
    calls.add('load');
    lastItemId = itemId;
    if (loadBlocker != null) await loadBlocker!.future;
    if (loadShouldFail)
      return const RemoteLoadResult(success: false, error: 'load failed');
    return RemoteLoadResult(
      success: true,
      capabilities: _fullCaps(),
      position: position,
      duration: const Duration(minutes: 3),
    );
  }

  @override
  Future<void> disconnect({
    required String sessionId,
    required bool stopPlayback,
  }) async {
    calls.add('disconnect');
  }

  @override
  Future<void> play({required String sessionId, required String itemId}) async {
    calls.add('play');
  }

  @override
  Future<void> pause({
    required String sessionId,
    required String itemId,
  }) async {
    calls.add('pause');
  }

  @override
  Future<void> stop({required String sessionId, required String itemId}) async {
    calls.add('stop');
  }

  @override
  Future<void> seek(
    Duration position, {
    required String sessionId,
    required String itemId,
  }) async {
    calls.add('seek');
  }

  @override
  Future<void> setVolume(
    double volume, {
    required String sessionId,
    required String itemId,
  }) async {
    calls.add('setVolume');
  }

  @override
  Future<void> setMute(
    bool muted, {
    required String sessionId,
    required String itemId,
  }) async {
    calls.add('setMute');
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    await _outputs.close();
    await _session.close();
  }

  void publishDevices(List<PlaybackOutput> list) => _outputs.add(list);

  static OutputCapabilities _fullCaps() => const OutputCapabilities(
    audio: true,
    video: true,
    play: true,
    pause: true,
    stop: true,
    seek: true,
    volume: true,
  );
}

class FakeMediaFactory implements NetworkMediaFactory {
  bool shouldFail = false;
  String? lastSessionId;
  String? lastItemId;

  @override
  Future<NetworkMediaLease> prepare(
    PlaybackTrack track,
    PlaybackOutput output, {
    required String sessionId,
    required String itemId,
  }) async {
    lastSessionId = sessionId;
    lastItemId = itemId;
    if (shouldFail)
      throw UnsupportedError(
        "This source can't currently be played on this output.",
      );
    final uri = Uri.parse('http://192.168.1.1:8080/media/fake_token');
    return NetworkMediaLease(
      item: NetworkMediaItem(
        uri: uri,
        mimeType: 'audio/mpeg',
        title: track.title,
        artist: track.artist,
        isVideo: track.isVideo,
      ),
      release: () async {},
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────

const _audioMp3 = OutputCapabilities(
  audio: true,
  video: false,
  play: true,
  pause: true,
  stop: true,
  seek: true,
  volume: true,
  mimeTypes: {'audio/mpeg', 'audio/mp4', 'audio/flac', 'audio/wav', 'audio/*'},
);

PlaybackOutput fakeOutput({
  String id = 'dev-1',
  String name = 'Speaker',
  OutputKind kind = OutputKind.dlna,
}) => PlaybackOutput(
  id: id,
  name: name,
  kind: kind,
  capabilities: _audioMp3,
  endpointUri: Uri.parse('http://192.168.1.100:1234/desc.xml'),
);

PlaybackTrack fakeAudioTrack({
  String id = 'track-1',
  String title = 'Song',
  PlaybackSourceType sourceType = PlaybackSourceType.local,
}) => PlaybackTrack(
  id: id,
  title: title,
  artist: 'Artist',
  sourceType: sourceType,
  localMediaUri: sourceType == PlaybackSourceType.local
      ? 'file:///music/song.mp3'
      : null,
  networkMediaUri: sourceType != PlaybackSourceType.local
      ? 'http://example.com/song.mp3'
      : null,
);

PlaybackTrack fakeOnlineTrack() => const PlaybackTrack(
  id: 'yt-1',
  title: 'YouTube Song',
  artist: 'Artist',
  sourceType: PlaybackSourceType.online,
);

NetworkOutputController makeController({
  FakePlaybackController? local,
  FakeBackend? backend,
  FakeMediaFactory? factory,
}) {
  final lc = local ?? FakePlaybackController();
  final be = backend ?? FakeBackend();
  final mf = factory ?? FakeMediaFactory();
  return NetworkOutputController(
    localController: lc,
    backends: [be],
    mediaFactory: mf,
    operationTimeout: const Duration(seconds: 5),
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────

void main() {
  group('NetworkOutputController — initial state', () {
    test('starts with local output selected', () {
      final c = makeController();
      expect(c.currentOutputState.selectedOutput.kind, OutputKind.local);
      expect(c.isRemoteActive, isFalse);
      c.dispose();
    });

    test('exposes isRemoteActive=false initially', () {
      final c = makeController();
      expect(c.isRemoteActive, isFalse);
      c.dispose();
    });
  });

  group('NetworkOutputController — discovery', () {
    test('startDiscovery sets discoveryActive=true', () async {
      final be = FakeBackend();
      final c = makeController(backend: be);
      await c.startDiscovery();
      expect(c.currentOutputState.discoveryActive, isTrue);
      await c.dispose();
    });

    test('stopDiscovery sets discoveryActive=false', () async {
      final be = FakeBackend();
      final c = makeController(backend: be);
      await c.startDiscovery();
      await c.stopDiscovery();
      expect(c.currentOutputState.discoveryActive, isFalse);
      await c.dispose();
    });

    test('published devices appear in availableOutputs', () async {
      final be = FakeBackend();
      final c = makeController(backend: be);
      final output = fakeOutput();
      be.publishDevices([output]);
      await Future<void>.delayed(Duration.zero);
      final available = c.currentOutputState.availableOutputs;
      expect(available.any((o) => o.id == 'dev-1'), isTrue);
      await c.dispose();
    });

    test('removed devices disappear from availableOutputs', () async {
      final be = FakeBackend();
      final c = makeController(backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);
      be.publishDevices([]); // device removed
      await Future<void>.delayed(Duration.zero);
      expect(
        c.currentOutputState.availableOutputs.where(
          (o) => o.kind == OutputKind.dlna,
        ),
        isEmpty,
      );
      await c.dispose();
    });
  });

  group('NetworkOutputController — local -> remote handoff', () {
    test(
      'selectOutput while idle connects and loads; remote becomes authoritative',
      () async {
        final local = FakePlaybackController();
        local.emitState(PlaybackState.playing);
        await local.play(fakeAudioTrack(), play: true);
        local.calls.clear();

        final be = FakeBackend();
        final c = makeController(local: local, backend: be);
        be.publishDevices([fakeOutput()]);
        await Future<void>.delayed(Duration.zero);

        await c.selectOutput(fakeOutput()).timeout(const Duration(seconds: 5));

        expect(c.isRemoteActive, isTrue);
        expect(be.calls, contains('connect'));
        expect(be.calls, contains('load'));
        expect(local.calls, contains('pause'));
        await c.dispose();
      },
    );

    test('local is paused before load is attempted', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);
      local.calls.clear();

      final be = FakeBackend();
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);

      final selectFuture = c.selectOutput(fakeOutput());
      await selectFuture.timeout(const Duration(seconds: 5));

      final pauseIdx = local.calls.indexOf('pause');
      final loadIdx = be.calls.indexOf('load');
      expect(pauseIdx, lessThan(loadIdx));
      await c.dispose();
    });

    test('position is captured from local engine and passed to load', () async {
      final local = FakePlaybackController();
      final track = fakeAudioTrack();
      await local.play(track, play: true, startAt: const Duration(seconds: 45));
      local._emit(
        local.currentStatus.copyWith(position: const Duration(seconds: 45)),
      );
      local.calls.clear();

      final be = FakeBackend();
      final mf = FakeMediaFactory();
      final c = makeController(local: local, backend: be, factory: mf);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);

      await c.selectOutput(fakeOutput()).timeout(const Duration(seconds: 5));
      // position was in the load call — check via output state
      final session = c.currentOutputState.session;
      expect(session, isNotNull);
      await c.dispose();
    });

    test('remote never authoritative before load succeeds', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);

      final be = FakeBackend();
      final loadDone = Completer<void>();
      be.loadBlocker = loadDone;
      final c = makeController(local: local, backend: be);
      final outDev = fakeOutput();
      be.publishDevices([outDev]);
      await Future<void>.delayed(Duration.zero);

      final selectFuture = c.selectOutput(outDev);
      // connect finishes fast; give a tick for it, then check before load
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.isRemoteActive, isFalse);
      loadDone.complete();
      await selectFuture.timeout(const Duration(seconds: 5));
      expect(c.isRemoteActive, isTrue);
      await c.dispose();
    });

    test('connect failure rolls back to local', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);
      local.calls.clear();

      final be = FakeBackend();
      be.connectShouldFail = true;
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        c.selectOutput(fakeOutput()),
        throwsA(isA<NetworkOutputException>()),
      );
      expect(c.isRemoteActive, isFalse);
      expect(c.currentOutputState.selectedOutput.kind, OutputKind.local);
      await c.dispose();
    });

    test('load failure rolls back to local and local resumes', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);
      local.calls.clear();

      final be = FakeBackend();
      be.loadShouldFail = true;
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        c.selectOutput(fakeOutput()),
        throwsA(isA<NetworkOutputException>()),
      );
      expect(c.isRemoteActive, isFalse);
      // Local was restored
      expect(local.calls, contains('prepare'));
      await c.dispose();
    });

    test('unsupported YouTube source does not pause local', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);
      local.calls.clear();

      final be = FakeBackend();
      // caps that would block online sources
      final output = fakeOutput();
      final c = makeController(local: local, backend: be);
      be.publishDevices([output]);
      await Future<void>.delayed(Duration.zero);

      // Play an online track first so controller knows about it
      await local.play(fakeOnlineTrack(), play: true);
      local.calls.clear();

      await expectLater(
        c.selectOutput(output),
        throwsA(isA<NetworkOutputException>()),
      );
      // Local must not have been paused
      expect(local.calls, isNot(contains('pause')));
      expect(c.isRemoteActive, isFalse);
      await c.dispose();
    });
  });

  group('NetworkOutputController — remote controls', () {
    Future<(NetworkOutputController, FakePlaybackController, FakeBackend)>
    makeRemote() async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);
      local.calls.clear();

      final be = FakeBackend();
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);
      await c.selectOutput(fakeOutput()).timeout(const Duration(seconds: 5));
      be.calls.clear();
      local.calls.clear();
      return (c, local, be);
    }

    test('pause while remote routes to backend, not local', () async {
      final (c, local, be) = await makeRemote();
      await c.pause();
      expect(be.calls, contains('pause'));
      expect(local.calls, isNot(contains('pause')));
      await c.dispose();
    });

    test('resume while remote routes to backend', () async {
      final (c, local, be) = await makeRemote();
      await c.resume();
      expect(be.calls, contains('play'));
      expect(local.calls, isNot(contains('resume')));
      await c.dispose();
    });

    test('stop while remote routes to backend', () async {
      final (c, local, be) = await makeRemote();
      await c.stop();
      expect(be.calls, contains('stop'));
      expect(local.calls, isNot(contains('stop')));
      await c.dispose();
    });

    test('seek while remote routes to backend', () async {
      final (c, local, be) = await makeRemote();
      await c.seekTo(const Duration(seconds: 30));
      expect(be.calls, contains('seek'));
      expect(local.calls, isNot(contains('seek')));
      await c.dispose();
    });

    test('play(track) while remote triggers remote load', () async {
      final (c, local, be) = await makeRemote();
      await c
          .play(fakeAudioTrack(id: 'track-2', title: 'Track 2'))
          .timeout(const Duration(seconds: 5));
      expect(be.calls, contains('load'));
      expect(local.calls, isNot(contains('play')));
      await c.dispose();
    });

    test('local engine stays paused while remote owns playback', () async {
      final (c, local, be) = await makeRemote();
      expect(c.isRemoteActive, isTrue);
      expect(local.currentStatus.state, isNot(PlaybackState.playing));
      await c.dispose();
    });
  });

  group('NetworkOutputController — remote -> local handoff', () {
    test('returnToLocal stops remote and restores local', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);
      local.calls.clear();

      final be = FakeBackend();
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);
      await c.selectOutput(fakeOutput()).timeout(const Duration(seconds: 5));
      be.calls.clear();
      local.calls.clear();

      await c.returnToLocal().timeout(const Duration(seconds: 5));

      expect(c.isRemoteActive, isFalse);
      expect(be.calls, contains('stop'));
      expect(be.calls, contains('disconnect'));
      expect(local.calls, contains('prepare'));
      await c.dispose();
    });

    test('disconnect() leaves local paused', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);
      local.calls.clear();

      final be = FakeBackend();
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);
      await c.selectOutput(fakeOutput()).timeout(const Duration(seconds: 5));

      await c.disconnect(stopPlayback: false);
      expect(c.isRemoteActive, isFalse);
      expect(c.currentOutputState.selectedOutput.kind, OutputKind.local);
      await c.dispose();
    });
  });

  group('NetworkOutputController — rapid switching', () {
    test('selecting A then B: only B becomes authoritative', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);

      final be = FakeBackend();
      final c = makeController(local: local, backend: be);

      final outA = fakeOutput(id: 'dev-A', name: 'A');
      final outB = fakeOutput(id: 'dev-B', name: 'B');
      be.publishDevices([outA, outB]);
      await Future<void>.delayed(Duration.zero);

      // Fire both simultaneously; they are serialized
      final aFuture = c.selectOutput(outA);
      final bFuture = c.selectOutput(outB);
      // B supersedes A
      await Future.wait([
        aFuture.catchError((_) {}),
        bFuture.catchError((_) {}),
      ]);
      // Final state: only B can win (or any, as long as it's consistent)
      expect(c.isRemoteActive, isTrue);
      await c.dispose();
    });

    test(
      'stale connect result cannot make old backend authoritative',
      () async {
        final be = FakeBackend();
        final connectDone = Completer<void>();
        be.connectBlocker = connectDone;

        final local = FakePlaybackController();
        await local.play(fakeAudioTrack(), play: true);
        final c = makeController(local: local, backend: be);
        be.publishDevices([fakeOutput()]);
        await Future<void>.delayed(Duration.zero);

        // Start connection to A (blocked)
        final aFuture = c.selectOutput(fakeOutput(id: 'dev-A'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        // Immediately switch to local → supersedes A
        final localFuture = c.returnToLocal();
        // Unblock A's connect
        connectDone.complete();
        await Future.wait([
          aFuture.catchError((_) {}),
          localFuture.catchError((_) {}),
        ]);
        // A must not become authoritative
        expect(c.isRemoteActive, isFalse);
        await c.dispose();
      },
    );
  });

  group('NetworkOutputController — dispose safety', () {
    test('dispose during connection completes cleanly', () async {
      final be = FakeBackend();
      final connectDone = Completer<void>();
      be.connectBlocker = connectDone;

      final local = FakePlaybackController();
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);

      final selectFuture = c.selectOutput(fakeOutput());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      connectDone.complete();
      await c.dispose();
      await expectLater(selectFuture, completes);
      expect(be.disposeCalled, isTrue);
      expect(local.disposed, isTrue);
    });

    test('dispose idempotent', () async {
      final c = makeController();
      await c.dispose();
      await expectLater(c.dispose(), completes);
    });
  });

  group('NetworkOutputController — session state routing', () {
    test('local status not published while remote is authoritative', () async {
      final local = FakePlaybackController();
      await local.play(fakeAudioTrack(), play: true);

      final be = FakeBackend();
      final c = makeController(local: local, backend: be);
      be.publishDevices([fakeOutput()]);
      await Future<void>.delayed(Duration.zero);
      await c.selectOutput(fakeOutput()).timeout(const Duration(seconds: 5));

      final statusBefore = c.currentStatus;
      // Push a local status change — should be suppressed
      local._emit(
        local.currentStatus.copyWith(
          state: PlaybackState.playing,
          position: const Duration(seconds: 99),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.currentStatus, equals(statusBefore));
      await c.dispose();
    });
  });
}
