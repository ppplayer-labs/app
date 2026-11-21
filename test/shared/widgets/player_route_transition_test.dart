import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/player/video_layout_provider.dart';
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
      expect(transition.status, AnimationStatus.dismissed);
      expect(opacity(), 0);
      clock.forward();
      await tester.pump();
      expect(transition.status, AnimationStatus.forward);
      await tester.pump(const Duration(milliseconds: 90));
      expect(transition.progress, greaterThan(0));
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 120));
      final openingProgress = transition.progress;
      final openingOpacity = opacity();
      expect(openingOpacity, inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 90));
      await tester.pump(const Duration(milliseconds: 1));
      expect(transition.progress, 1);
      expect(transition.status, AnimationStatus.completed);
      expect(opacity(), 1);
      clock.reverse();
      await tester.pump();
      expect(transition.status, AnimationStatus.reverse);
      await tester.pump(const Duration(milliseconds: 90));
      expect(transition.progress, closeTo(openingProgress, 0.0001));
      expect(opacity(), closeTo(openingOpacity, 0.0001));
      await tester.pump(const Duration(milliseconds: 210));
      await tester.pump(const Duration(milliseconds: 1));
      expect(transition.progress, 0);
      expect(transition.status, AnimationStatus.dismissed);
      expect(opacity(), 0);
      expect(childKey.currentContext, same(originalChild));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(transition.isAttached, false);
      expect(transition.status, isNull);
      clock.dispose();
    },
  );

  test('non-player screen ignores completed route transition', () {
    final transition = PlayerRouteTransition();
    final clock = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 300),
    );
    transition.attach(clock);

    clock.value = 1.0;
    // When animation is completed but route is not player screen:
    // status == AnimationStatus.completed.
    // Under followsRoute logic:
    // isPlayerScreen ? status != dismissed : status == reverse
    bool shouldFollowRoute({required bool isPlayerScreen}) =>
        transition.isAttached &&
        (isPlayerScreen
            ? (transition.status != AnimationStatus.dismissed)
            : (transition.status == AnimationStatus.reverse));

    expect(
      shouldFollowRoute(isPlayerScreen: false),
      false,
      reason:
          'Non-player screen must not expand bounds when transition is completed',
    );
    expect(
      shouldFollowRoute(isPlayerScreen: true),
      true,
      reason: 'Player screen must follow route when transition is completed',
    );

    // But when reversing (popping player):
    clock.reverse();
    expect(
      shouldFollowRoute(isPlayerScreen: false),
      true,
      reason:
          'Popping player route must follow transition to animate back to miniplayer',
    );

    clock.stop();
    clock.dispose();
    transition.dispose();
  });

  test(
    'desktop video layout validation rejects sidebar-contaminated dx and stale width',
    () {
      bool isVideoLayoutValid({
        required VideoLayoutState layout,
        required double screenWidth,
        required bool isDesktop,
      }) {
        return layout.isReady &&
            layout.isVisible &&
            (!isDesktop || layout.position.dx <= 1.0) &&
            layout.size.width > 0 &&
            layout.size.height > 0 &&
            (!isDesktop ||
                (layout.size.width - screenWidth).abs() <= 1.0 ||
                (screenWidth - layout.size.width >= 0 &&
                    screenWidth - layout.size.width <= 660)); // max queue width
      }

      // Valid full-width player
      final validFull = VideoLayoutState(
        position: Offset.zero,
        size: const Size(1024, 466),
        isReady: true,
        isVisible: true,
      );
      expect(
        isVideoLayoutValid(
          layout: validFull,
          screenWidth: 1024,
          isDesktop: true,
        ),
        true,
      );

      // Invalid: position.dx == 240 (measured behind desktop sidebar)
      final sidebarContaminated = VideoLayoutState(
        position: const Offset(240, 80),
        size: const Size(784, 386),
        isReady: true,
        isVisible: true,
      );
      expect(
        isVideoLayoutValid(
          layout: sidebarContaminated,
          screenWidth: 1024,
          isDesktop: true,
        ),
        false,
        reason: 'Bounds with dx > 1.0 from sidebar must be rejected',
      );

      // Invalid: stale width larger than current screen after window shrink
      final staleWider = VideoLayoutState(
        position: Offset.zero,
        size: const Size(1504, 761),
        isReady: true,
        isVisible: true,
      );
      expect(
        isVideoLayoutValid(
          layout: staleWider,
          screenWidth: 1024,
          isDesktop: true,
        ),
        false,
        reason: 'Stale bounds wider than screen must be rejected',
      );

      // Valid: desktop player with queue panel open (320px width)
      final withQueue = VideoLayoutState(
        position: Offset.zero,
        size: const Size(704, 466),
        isReady: true,
        isVisible: true,
      );
      expect(
        isVideoLayoutValid(
          layout: withQueue,
          screenWidth: 1024,
          isDesktop: true,
        ),
        true,
        reason: 'Bounds narrowed by active queue panel must be accepted',
      );
    },
  );

  test('videoLayoutProvider clear resets state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(videoLayoutProvider.notifier);
    notifier.updateLayout(
      const Size(800, 600),
      const Offset(10, 20),
      isVisible: true,
    );

    expect(container.read(videoLayoutProvider).isReady, true);
    expect(container.read(videoLayoutProvider).isVisible, true);

    notifier.clear();

    expect(container.read(videoLayoutProvider).isReady, false);
    expect(container.read(videoLayoutProvider).isVisible, false);
    expect(container.read(videoLayoutProvider).size, Size.zero);
    expect(container.read(videoLayoutProvider).position, Offset.zero);
  });
}
