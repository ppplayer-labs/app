import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/playback/media_handler.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/playback/packages/pp_playback_engine/test/fake_youtube_controller.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt;

class _Player extends Notifier<PlayerState> implements PlayerNotifier {
  _Player(this.engine);
  final PlaybackController engine;
  final calls = <String>[];
  @override
  PlayerState build() => PlayerState(isPlaying: true);
  @override
  void pause() {
    calls.add('pause');
    unawaited(engine.pause());
    state = state.copyWith(isPlaying: false);
  }

  @override
  void resume() {
    calls.add('play');
    unawaited(engine.resume());
    state = state.copyWith(isPlaying: true);
  }

  @override
  void skipNext() => calls.add('next');
  @override
  void skipPrevious() => calls.add('previous');
  @override
  Future<void> seekTo(Duration position) async =>
      calls.add('seek:${position.inMilliseconds}');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ppplayer.app/ios_media_controls');
  const codec = StandardMethodCodec();
  Future<void> remote(String method, [Object? arguments]) async {
    final reply = Completer<ByteData?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          codec.encodeMethodCall(MethodCall(method, arguments)),
          reply.complete,
        );
    codec.decodeEnvelope((await reply.future)!);
  }

  test(
    'WebKit state changes do not repeatedly activate the app audio session',
    () async {
      final engine = MediaKitPlaybackEngine();
      final player = _Player(engine);
      final container = ProviderContainer(
        overrides: [playerProvider.overrideWith(() => player)],
      );
      final handler = PpPlayerAudioHandler(
        () => container,
        enableIosCommands: true,
      );
      var activations = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'activateAudioSession') activations++;
            return null;
          });
      try {
        for (final playing in [true, false, true, false, true]) {
          handler.updatePlaybackState(
            playing: playing,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            isIFrameMode: true,
          );
          await Future<void>.delayed(Duration.zero);
        }
        expect(
          activations,
          0,
          reason: 'WebKit owns renderer session activation',
        );
        expect(player.calls, isEmpty);
        await remote('play');
        expect(
          activations,
          1,
          reason: 'explicit system play can activate the app',
        );
        await remote('pause');
        expect(player.calls, ['play', 'pause']);
      } finally {
        await engine.dispose();
        container.dispose();
        channel.setMethodCallHandler(null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );

  test(
    'iOS session activation retries failures and reactivates after pause',
    () async {
      final engine = MediaKitPlaybackEngine();
      final player = _Player(engine);
      final container = ProviderContainer(
        overrides: [playerProvider.overrideWith(() => player)],
      );
      final handler = PpPlayerAudioHandler(
        () => container,
        enableIosCommands: true,
      );
      var activations = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'activateAudioSession') {
              activations++;
              if (activations == 1)
                throw PlatformException(code: 'interrupted');
            }
            return null;
          });
      void publish(bool playing) => handler.updatePlaybackState(
        playing: playing,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
      );
      try {
        publish(true);
        await Future<void>.delayed(Duration.zero);
        expect(activations, 1);
        publish(true);
        await Future<void>.delayed(Duration.zero);
        expect(activations, 2);
        publish(true);
        await Future<void>.delayed(Duration.zero);
        expect(activations, 2, reason: 'position updates do not reactivate');
        publish(false);
        publish(true);
        await Future<void>.delayed(Duration.zero);
        expect(activations, 3, reason: 'resuming requires a fresh activation');
        expect(
          player.calls,
          isEmpty,
          reason: 'session updates never issue play commands',
        );
      } finally {
        await engine.dispose();
        container.dispose();
        channel.setMethodCallHandler(null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );

  test(
    'system pause sets paused intent and late renderer events cannot replay',
    () async {
      final youtube = FakeYoutubeController();
      final engine = MediaKitPlaybackEngine(
        youtubeControllerFactory: (_, _) => youtube,
      );
      final player = _Player(engine);
      final container = ProviderContainer(
        overrides: [playerProvider.overrideWith(() => player)],
      );
      final handler = PpPlayerAudioHandler(
        () => container,
        enableIosCommands: true,
      );
      final nativeUpdates = <Map<dynamic, dynamic>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'updateNowPlaying') {
              nativeUpdates.add(call.arguments as Map);
            }
            return null;
          });
      try {
        handler.updateMetadata(
          id: 'system-pause-video',
          title: 'Test',
          artist: 'Artist',
          duration: const Duration(minutes: 3),
        );
        handler.updatePlaybackState(
          playing: true,
          position: const Duration(seconds: 12),
          bufferedPosition: const Duration(seconds: 20),
        );
        await Future<void>.delayed(Duration.zero);
        expect(nativeUpdates.last, containsPair('title', 'Test'));
        expect(nativeUpdates.last, containsPair('durationMs', 180000));
        expect(nativeUpdates.last, containsPair('positionMs', 12000));
        expect(nativeUpdates.last, containsPair('playing', true));
        const track = PlaybackTrack(id: 'system-pause-video', title: 'Test');
        await engine.play(track);
        youtube.emitState(track.id, yt.PlayerState.cued);
        await Future<void>.delayed(Duration.zero);
        youtube.emitState(track.id, yt.PlayerState.playing);
        await Future<void>.delayed(Duration.zero);
        final playCount = youtube.count('play');
        await remote('pause', {'source': 'webKit'});
        expect(player.calls, ['pause']);
        expect(engine.currentStatus.state, PlaybackState.paused);
        youtube.emitState(track.id, yt.PlayerState.paused);
        youtube.emitState(track.id, yt.PlayerState.playing);
        await Future<void>.delayed(Duration.zero);
        youtube.emitState(track.id, yt.PlayerState.paused);
        await Future<void>.delayed(Duration.zero);
        expect(youtube.count('play'), playCount);
        expect(engine.currentStatus.state, PlaybackState.paused);
        expect(container.read(playerProvider).isPlaying, isFalse);
        handler.updatePlaybackState(
          playing: false,
          position: const Duration(seconds: 12),
          bufferedPosition: const Duration(seconds: 20),
        );
        await Future<void>.delayed(Duration.zero);
        expect(nativeUpdates.last, containsPair('playing', false));
        expect(nativeUpdates.last, containsPair('id', track.id));
        await remote('play');
        await Future<void>.delayed(Duration.zero);
        expect(player.calls, ['pause', 'play']);
        expect(youtube.count('play'), playCount + 1);
        await remote('togglePlayPause');
        expect(player.calls.last, 'pause');
        await remote('next');
        await remote('previous');
        await remote('seek', {'positionMs': 12500});
        expect(player.calls.sublist(player.calls.length - 3), [
          'next',
          'previous',
          'seek:12500',
        ]);
      } finally {
        await engine.dispose();
        container.dispose();
        channel.setMethodCallHandler(null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
}
