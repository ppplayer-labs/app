import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/features/player/widgets/player_controls_layout.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('queue and transport fit $size at text scale $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var queueTaps = 0;
        var actionTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PlayerControlsLayout(
                      queueLabel: 'Queue',
                      optionsLabel: 'Playback options',
                      queueSelected: true,
                      onInteraction: () {},
                      onToggleQueue: () => queueTaps++,
                      transport: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.skip_previous),
                          ),
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.play_arrow),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.skip_next),
                          ),
                        ],
                      ),
                      fullscreenButton: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.fullscreen),
                      ),
                      actions: [
                        PlayerControlAction(
                          label: 'Shuffle',
                          icon: Icons.shuffle,
                          onSelected: () => actionTaps++,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final queue = find.byKey(const ValueKey('queue_toggle_button'));
        expect(find.text('Queue'), findsOneWidget);
        expect(tester.getSize(queue).height, greaterThanOrEqualTo(48));
        expect(find.byIcon(Icons.shuffle), findsNothing);
        await tester.tap(queue);
        expect(queueTaps, 1);
        await tester.tap(find.byKey(const ValueKey('playback_options_button')));
        await tester.pumpAndSettle();
        expect(find.text('Shuffle'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Shuffle'));
        await tester.pumpAndSettle();
        expect(actionTaps, 1);
      });
    }
  }
}
