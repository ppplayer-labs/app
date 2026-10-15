import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/shared/widgets/player_route_transition.dart';

void main() {
  testWidgets(
    'route clock drives expansion and delayed controls in both directions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final clock = AnimationController(
        vsync: tester,
        duration: playerTransitionDuration,
      );
      final childKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: PlayerRouteTransitionBoundary(
              animation: clock,
              child: SizedBox(key: childKey),
            ),
          ),
        ),
      );
      final transition = container.read(playerRouteTransitionProvider);
      final originalChild = childKey.currentContext;
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.byKey(childKey),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;

      expect(transition.progress, 0);
      expect(opacity(), 0);
      clock.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(transition.progress, greaterThan(0));
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 120));
      final openingProgress = transition.progress;
      final openingOpacity = opacity();
      expect(openingOpacity, inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 90));
      expect(transition.progress, 1);
      expect(opacity(), 1);
      clock.reverse();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(transition.progress, closeTo(openingProgress, 0.0001));
      expect(opacity(), closeTo(openingOpacity, 0.0001));
      await tester.pump(const Duration(milliseconds: 210));
      expect(transition.progress, 0);
      expect(opacity(), 0);
      expect(childKey.currentContext, same(originalChild));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(transition.isAttached, false);
      clock.dispose();
    },
  );
}
