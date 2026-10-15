import 'package:ppplayer/core/playback/chromium_playback_engine.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';

class NativeFallback extends Fake implements PlaybackController {
  final statuses = StreamController<PlaybackStatus>.broadcast(sync: true);
  final events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final calls = <String>[];
  @override
  Stream<PlaybackStatus> get statusStream => statuses.stream;
  @override
  Stream<PlaybackEvent> get eventStream => events.stream;
  @override
  bool get supportsSpeed => true;
  @override
  bool get supportsVideoFitMode => true;
  @override
  dynamic get renderer => 'native-renderer';
  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {
    calls.add('play:${track.id}:$play');
  }

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    calls.add('pause:$caller:$failOnTimeout');
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('volume:$volume');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await statuses.close();
    await events.close();
  }
}

class YoutubeFixture extends Fake implements ChromiumYoutubePlayerController {
  final messages = StreamController<Map<String, Object?>>.broadcast(sync: true);
  final calls = <String>[];
  final controller = ChromiumWebViewController();
  Completer<void>? gate;
  bool fail = false;
  bool crashOnInitialize = false;
  bool durationReady = true;
  @override
  Stream<Map<String, Object?>> get events => messages.stream;
  @override
  ChromiumWebViewController get webViewController => controller;
  @override
  Future<void> initialize() async {
    await gate?.future;
    if (crashOnInitialize) throw StateError('Browser crashed');
  }

  @override
  Future<void> loadVideoById({
    required String videoId,
    double startSeconds = 0,
    double? endSeconds,
  }) async {
    if (fail) throw StateError('fixture load failure');
    calls.add('load:$videoId:$startSeconds');
  }

  @override
  Future<void> cueVideoById({
    required String videoId,
    double startSeconds = 0,
    double? endSeconds,
  }) async {
    calls.add('cue:$videoId:$startSeconds');
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
    calls.add('seek:$seconds');
  }

  @override
  Future<void> setVolume(int volume) async {
    calls.add('volume:$volume');
  }

  @override
  Future<double> get duration async {
    if (!durationReady) throw StateError('Invalid YouTube numeric result');
    return 120;
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }
}

void main() {
  late NativeFallback native;
  late ChromiumPlaybackEngine engine;
  final players = <YoutubeFixture>[];
  final observed = <PlaybackEvent>[];
  const video = PlaybackTrack(id: 'M7lc1UVf-VE', title: 'Video');
  setUp(() {
    players.clear();
    observed.clear();
    native = NativeFallback();
    engine = ChromiumPlaybackEngine(
      fallback: native,
      initializeCef: () async {},
      createPlayer: () {
        final player = YoutubeFixture();
        players.add(player);
        return player;
      },
    );
    engine.eventStream.listen(observed.add);
  });
  tearDown(() async {
    await engine.dispose();
    for (final player in players) {
      await player.messages.close();
    }
  });
  test(
    'late metadata does not fail playback and progress refreshes duration',
    () async {
      await engine.dispose();
      native = NativeFallback();
      final player = YoutubeFixture()..durationReady = false;
      players.add(player);
      engine = ChromiumPlaybackEngine(
        fallback: native,
        initializeCef: () async {},
        createPlayer: () => player,
      );
      await engine.play(video);
      expect(engine.currentStatus.error, isNull);
      expect(engine.currentStatus.duration, Duration.zero);
      player.durationReady = true;
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      player.messages.add({
        'VideoState': jsonEncode({'currentTime': 2, 'loadedFraction': 0.5}),
      });
      await Future<void>.delayed(Duration.zero);
      expect(engine.currentStatus.duration, const Duration(seconds: 120));
    },
  );
  test('visible browser retains its background service', () async {
    await engine.dispose();
    native = NativeFallback();
    final serviceCalls = <String>[];
    final player = YoutubeFixture();
    players.add(player);
    engine = ChromiumPlaybackEngine(
      fallback: native,
      initializeCef: () async {},
      createPlayer: () => player,
      startPlaybackService: () async => serviceCalls.add('start'),
      stopPlaybackService: () async => serviceCalls.add('stop'),
    );
    await engine.play(video);
    expect(engine.currentStatus.hasVideo, isTrue);
    expect(engine.renderer, isA<ChromiumWebView>());
    expect(serviceCalls, ['start']);
    await engine.stop();
    expect(serviceCalls, ['start', 'stop']);
  });

  test('audio-only browser starts service and releases it on stop', () async {
    await engine.dispose();
    native = NativeFallback();
    final serviceCalls = <String>[];
    final player = YoutubeFixture();
    players.add(player);
    engine = ChromiumPlaybackEngine(
      fallback: native,
      initializeCef: () async {},
      createPlayer: () => player,
      showBrowser: false,
      startPlaybackService: () async {
        serviceCalls.add('start');
      },
      stopPlaybackService: () async {
        serviceCalls.add('stop');
      },
    );
    await engine.play(video);
    expect(engine.renderer, isNull);
    expect(serviceCalls, ['start']);
    await engine.setSubtitleAppearance(textSize: 18);
    await engine.stop();
    expect(serviceCalls, ['start', 'stop']);
  });
  test('maps playing, progress, buffering, pause and one end event', () async {
    await engine.play(video);
    final player = players.single;
    player.messages.add({'StateChange': 1});
    player.messages.add({
      'VideoState': jsonEncode({'currentTime': 4.125, 'loadedFraction': 0.5}),
    });
    expect(engine.currentStatus.position, const Duration(milliseconds: 4125));
    expect(engine.currentStatus.buffered, const Duration(seconds: 60));
    player.messages.add({'StateChange': 3});
    player.messages.add({'StateChange': 1});
    await engine.pause(caller: 'media-command');
    player.messages.add({'StateChange': 2});
    await engine.resume();
    player.messages.add({'StateChange': 1});
    player.messages.add({'StateChange': 0});
    player.messages.add({'StateChange': 0});
    await Future<void>.delayed(Duration.zero);
    expect(
      observed
          .where((event) => event.type == PlaybackEventType.trackStarted)
          .length,
      1,
    );
    expect(
      observed
          .where((event) => event.type == PlaybackEventType.trackEnded)
          .length,
      1,
    );
    expect(
      observed.any((event) => event.type == PlaybackEventType.playbackPaused),
      isTrue,
    );
    expect(engine.currentStatus.state, PlaybackState.ended);
  });
  test('prepare preserves subsecond seek and volume scale', () async {
    await engine.setVolume(0.35);
    await engine.prepare(video, position: const Duration(milliseconds: 1250));
    final player = players.single;
    expect(player.calls, contains('cue:M7lc1UVf-VE:1.25'));
    expect(player.calls, contains('volume:35'));
    await engine.seekTo(const Duration(milliseconds: 2750));
    expect(player.calls.last, 'seek:2.75');
    expect(engine.supportsSpeed, isFalse);
    expect(() => engine.setSpeed(2), throwsUnsupportedError);
  });
  test(
    'switching to local keeps fallback and ignores old video events',
    () async {
      await engine.play(video);
      final old = players.single;
      await engine.play(
        const PlaybackTrack(
          id: 'file',
          title: 'Local',
          sourceType: PlaybackSourceType.local,
          localMediaUri: 'file:///audio.ogg',
        ),
      );
      old.messages.add({'StateChange': 1});
      expect(engine.currentStatus.track!.id, 'file');
      expect(engine.renderer, 'native-renderer');
      await engine.pause(caller: 'native', failOnTimeout: true);
      expect(native.calls, contains('pause:native:true'));
    },
  );
  test('late old player error cannot corrupt new track', () async {
    await engine.play(video);
    final old = players.single;
    await engine.play(const PlaybackTrack(id: 'dQw4w9WgXcQ', title: 'Next'));
    old.messages.add({'PlayerError': 153});
    expect(engine.currentStatus.error, isNull);
    players.last.messages.add({'PlayerError': 100});
    expect(engine.currentStatus.state, PlaybackState.error);
    expect(engine.currentStatus.error, contains('100'));
  });
  test(
    'pause while readiness is pending cues rather than starts playback',
    () async {
      final gate = Completer<void>();
      await engine.dispose();
      native = NativeFallback();
      engine = ChromiumPlaybackEngine(
        fallback: native,
        initializeCef: () async {},
        createPlayer: () {
          final player = YoutubeFixture()..gate = gate;
          players.add(player);
          return player;
        },
      );
      final opening = engine.play(video);
      await Future<void>.delayed(Duration.zero);
      final pause = engine.pause();
      gate.complete();
      await Future.wait([opening, pause]);
      expect(
        players.single.calls.any((call) => call.startsWith('load:')),
        isFalse,
      );
      expect(players.single.calls, contains('cue:M7lc1UVf-VE:0.0'));
      players.single.messages.add({'StateChange': 1});
      await Future<void>.delayed(Duration.zero);
      expect(players.single.calls.last, 'pause');
      expect(engine.currentStatus.state, isNot(PlaybackState.playing));
    },
  );
  test(
    'stop invalidates an in-flight open and disposal rejects new work',
    () async {
      final gate = Completer<void>();
      await engine.dispose();
      native = NativeFallback();
      engine = ChromiumPlaybackEngine(
        fallback: native,
        initializeCef: () => gate.future,
        createPlayer: () {
          throw StateError('must not create after stop');
        },
      );
      final opening = engine.play(video);
      await Future<void>.delayed(Duration.zero);
      await engine.stop();
      gate.complete();
      await opening;
      expect(engine.currentStatus.state, PlaybackState.idle);
      await engine.dispose();
      await engine.dispose();
      expect(() => engine.play(video), throwsStateError);
    },
  );
  test(
    'initialization failure preserves track and position without online fallback',
    () async {
      await engine.dispose();
      native = NativeFallback();
      engine = ChromiumPlaybackEngine(
        fallback: native,
        initializeCef: () async => throw StateError('CEF unavailable'),
        createPlayer: () => throw StateError('must not create'),
      );
      await expectLater(
        engine.play(video, startAt: const Duration(seconds: 9), play: false),
        throwsStateError,
      );
      expect(engine.currentStatus.state, PlaybackState.error);
      expect(engine.currentStatus.track, video);
      expect(engine.currentStatus.position, const Duration(seconds: 9));
      expect(native.calls.where((call) => call.startsWith('play:')), isEmpty);
    },
  );
  test(
    'replacement waits for initialization and preserves latest pause intent',
    () async {
      final gate = Completer<void>();
      await engine.dispose();
      native = NativeFallback();
      engine = ChromiumPlaybackEngine(
        fallback: native,
        initializeCef: () async {},
        createPlayer: () {
          final player = YoutubeFixture();
          if (players.isEmpty) player.gate = gate;
          players.add(player);
          return player;
        },
      );
      final first = engine.play(video);
      await Future<void>.delayed(Duration.zero);
      const next = PlaybackTrack(id: 'dQw4w9WgXcQ', title: 'Next');
      final second = engine.play(
        next,
        startAt: const Duration(seconds: 3),
        play: false,
      );
      expect(players, hasLength(1));
      gate.complete();
      await Future.wait([first, second]);
      expect(players, hasLength(2));
      expect(players.first.calls, contains('dispose'));
      expect(players.last.calls, contains('cue:dQw4w9WgXcQ:3.0'));
      expect(
        players
            .expand((player) => player.calls)
            .where((call) => call.startsWith('load:')),
        isEmpty,
      );
      players.first.messages.add({'StateChange': 1});
      expect(engine.currentStatus.track, next);
      expect(engine.currentStatus.state, isNot(PlaybackState.playing));
    },
  );

  test(
    'disabled YouTube reports unsupported without initializing or delegating online',
    () async {
      await engine.dispose();
      native = NativeFallback();
      engine = ChromiumPlaybackEngine(
        youtubeEnabled: false,
        fallback: native,
        initializeCef: () async => throw StateError('must not initialize'),
        createPlayer: () => throw StateError('must not create'),
      );
      await expectLater(
        engine.play(video, startAt: const Duration(seconds: 4), play: false),
        throwsUnsupportedError,
      );
      expect(engine.currentStatus.track, video);
      expect(engine.currentStatus.position, const Duration(seconds: 4));
      expect(engine.currentStatus.state, PlaybackState.error);
      expect(native.calls.where((call) => call.startsWith('play:')), isEmpty);
      await engine.play(
        const PlaybackTrack(
          id: 'file',
          title: 'File',
          sourceType: PlaybackSourceType.local,
        ),
      );
      expect(native.calls, contains('play:file:true'));
    },
  );
  for (final source in [
    PlaybackSourceType.local,
    PlaybackSourceType.networkStream,
  ]) {
    for (final video in [false, true]) {
      test(
        '$source video=$video delegates to native without a browser',
        () async {
          await engine.play(
            PlaybackTrack(
              id: 'native',
              title: 'Native',
              sourceType: source,
              isVideo: video,
              liveStatus: source == PlaybackSourceType.networkStream
                  ? PlaybackLiveStatus.live
                  : PlaybackLiveStatus.unknown,
            ),
          );
          expect(players, isEmpty);
          expect(native.calls, contains('play:native:true'));
        },
      );
    }
  }
  test(
    'initialization retry preserves a user pause and disposes failed browser',
    () async {
      await engine.dispose();
      native = NativeFallback();
      engine = ChromiumPlaybackEngine(
        fallback: native,
        initializeCef: () async {},
        createPlayer: () {
          final player = YoutubeFixture()..crashOnInitialize = players.isEmpty;
          players.add(player);
          return player;
        },
      );
      final opening = engine.play(video, startAt: const Duration(seconds: 8));
      await Future<void>.delayed(Duration.zero);
      final pause = engine.pause();
      await Future.wait([opening, pause]);
      expect(players, hasLength(2));
      expect(players.first.calls, contains('dispose'));
      expect(players.last.calls, contains('cue:M7lc1UVf-VE:8.0'));
      expect(
        players
            .expand((player) => player.calls)
            .where((call) => call.startsWith('load:')),
        isEmpty,
      );
      players.first.messages.add({'StateChange': 1});
      expect(engine.currentStatus.state, isNot(PlaybackState.playing));
    },
  );
  test(
    'host-coordinated crash rejects late state and explicit retry preserves position',
    () async {
      await engine.play(
        video,
        startAt: const Duration(seconds: 6),
        play: false,
      );
      final old = players.single;
      old.messages.add({'BrowserCrashed': true});
      old.messages.add({'StateChange': 1});
      expect(engine.currentStatus.state, PlaybackState.error);
      await engine.pause();
      expect(players, hasLength(1));
      await engine.resume();
      expect(players, hasLength(2));
      expect(old.calls, contains('dispose'));
      expect(players.last.calls, contains('load:M7lc1UVf-VE:6.0'));
      expect(engine.currentStatus.track, video);
    },
  );
  test(
    'paused process restoration does not start a foreground service',
    () async {
      await engine.dispose();
      native = NativeFallback();
      final serviceCalls = <String>[];
      engine = ChromiumPlaybackEngine(
        fallback: native,
        initializeCef: () async {},
        createPlayer: () {
          final player = YoutubeFixture();
          players.add(player);
          return player;
        },
        startPlaybackService: () async => serviceCalls.add('start'),
        stopPlaybackService: () async => serviceCalls.add('stop'),
      );
      await engine.prepare(video, position: const Duration(seconds: 5));
      expect(serviceCalls, isEmpty);
      expect(players.single.calls, contains('cue:M7lc1UVf-VE:5.0'));
      await engine.resume();
      expect(serviceCalls, ['start']);
      await engine.pause();
      expect(serviceCalls, ['start', 'stop']);
      await engine.stop();
      expect(players.single.calls, contains('dispose'));
    },
  );
  test('service startup failure cannot autoplay a browser', () async {
    await engine.dispose();
    native = NativeFallback();
    engine = ChromiumPlaybackEngine(
      fallback: native,
      initializeCef: () async {},
      createPlayer: () => throw StateError('must not create'),
      startPlaybackService: () async =>
          throw StateError('service start rejected'),
    );
    await expectLater(engine.play(video), throwsStateError);
    expect(engine.currentStatus.state, PlaybackState.error);
    expect(players, isEmpty);
  });
}
