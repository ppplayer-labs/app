import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/playback/media_handler.dart';
import 'package:ppplayer/core/player/player_provider.dart';

class MacPlayer extends Notifier<PlayerState> implements PlayerNotifier {
  final calls = <String>[];
  @override
  PlayerState build() => PlayerState(isPlaying: true);
  @override
  Future<void> pause() async {
    calls.add('pause');
    state = state.copyWith(isPlaying: false);
  }

  @override
  Future<void> resume() async {
    calls.add('play');
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
  const channel = MethodChannel('com.ppplayer.app/macos_media_controls');
  test(
    'macOS native metadata and commands share authoritative intent without iOS activation',
    () async {
      final player = MacPlayer();
      final container = ProviderContainer(
        overrides: [playerProvider.overrideWith(() => player)],
      );
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      final handler = PpPlayerAudioHandler(
        () => container,
        enableIosCommands: false,
        enableMacosCommands: true,
        enableAndroidLifecycle: false,
      );
      handler.updateMetadata(
        id: 'track',
        title: 'Mac track',
        artist: 'Artist',
        duration: const Duration(seconds: 80),
      );
      handler.updatePlaybackState(
        playing: false,
        position: const Duration(seconds: 12),
        bufferedPosition: Duration.zero,
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls.map((c) => c.method), everyElement('updateNowPlaying'));
      expect(calls.last.arguments, containsPair('playing', false));
      expect(calls.last.arguments, containsPair('positionMs', 12000));
      for (final method in ['pause', 'play', 'next', 'previous', 'seek']) {
        final reply = Completer<ByteData?>();
        messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, method == 'seek' ? {'positionMs': 7000} : null),
          ),
          reply.complete,
        );
        final data = await reply.future;
        if (data != null) const StandardMethodCodec().decodeEnvelope(data);
      }
      expect(player.calls, ['pause', 'play', 'next', 'previous', 'seek:7000']);
      expect(container.read(playerProvider).isPlaying, true);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.ready,
      );
      channel.setMethodCallHandler(null);
      messenger.setMockMethodCallHandler(channel, null);
      container.dispose();
    },
  );
}
