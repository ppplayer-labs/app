import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' as media;
import 'package:media_kit_video/media_kit_video.dart' as video;
import 'package:mocktail/mocktail.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';

class _Controller extends Mock implements PlaybackController {}

class _Player extends Mock implements media.Player {}

class _Streams extends Mock implements media.PlayerStream {}

class _VideoController extends Mock implements video.VideoController {}

void main() {
  testWidgets(
    'iOS native surface does not pause on background or replay on return',
    (tester) async {
      final player = _Player();
      final streams = _Streams();
      final renderer = _VideoController();
      final controller = _Controller();
      final notifier = ValueNotifier<video.PlatformVideoController?>(null);
      addTearDown(notifier.dispose);
      when(
        () => player.state,
      ).thenReturn(const media.PlayerState(playing: true));
      when(() => player.stream).thenReturn(streams);
      when(() => streams.width).thenAnswer((_) => const Stream<int?>.empty());
      when(() => streams.height).thenAnswer((_) => const Stream<int?>.empty());
      when(() => streams.playing).thenAnswer((_) => const Stream<bool>.empty());
      when(() => renderer.player).thenReturn(player);
      when(() => renderer.notifier).thenReturn(notifier);
      when(() => controller.renderer).thenReturn(renderer);
      await tester.pumpWidget(
        MaterialApp(
          home: PlaybackView(
            controller: controller,
            status: const PlaybackStatus(state: PlaybackState.playing),
            subtitleViewConfiguration: const video.SubtitleViewConfiguration(
              visible: false,
            ),
          ),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      verifyNever(() => player.pause());
      // A deliberate pause must remain paused when the app returns.
      when(
        () => player.state,
      ).thenReturn(const media.PlayerState(playing: false));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      verifyNever(() => player.play());
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );
}
