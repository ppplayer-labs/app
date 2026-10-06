import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit_video/media_kit_video.dart' as video;
import 'package:mocktail/mocktail.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';

class _Controller extends Mock implements PlaybackController {}

void main() {
  testWidgets('browser widget renderer bypasses the native video surface', (
    tester,
  ) async {
    final controller = _Controller();
    const browser = SizedBox(key: ValueKey('browser-renderer'));
    when(() => controller.renderer).thenReturn(browser);
    await tester.pumpWidget(
      MaterialApp(
        home: PlaybackView(
          controller: controller,
          status: const PlaybackStatus(state: PlaybackState.playing),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('browser-renderer')), findsOneWidget);
    expect(find.byType(video.Video), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
