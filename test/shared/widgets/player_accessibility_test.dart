import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/features/player/widgets/player_overlays.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/player_route_transition.dart';
import 'package:ppplayer/shared/widgets/tactile_buttons.dart';

/// Walks the entire attached semantics tree and verifies that every node with a
/// [SemanticsNode.traversalChildIdentifier] has a matching attached node with
/// the same [SemanticsNode.traversalParentIdentifier].
///
/// On Windows, Flutter's AccessibilityBridge (`accessibility_bridge.cc:114`)
/// fails `ui::AXTree::Unserialize` with
/// `"<id> will not be in the tree and is not the new root"` whenever an
/// OverlayPortal traversal child is attached without its traversal parent
/// (for example when `HeroController` sets `route.offstage = true` on frame 1
/// or when `FadeTransition`/`AnimatedOpacity` drops semantics at opacity 0).
void expectNoOrphanTraversalChildren(WidgetTester tester) {
  final root =
      tester.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  expect(root, isNotNull, reason: 'Semantics must be enabled for this check');

  final parents = <Object>{};
  final children = <Object, SemanticsNode>{};

  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.traversalParentIdentifier != null) {
      parents.add(data.traversalParentIdentifier!);
    }
    if (data.traversalChildIdentifier != null) {
      children[data.traversalChildIdentifier!] = node;
    }
    node.visitChildren((SemanticsNode child) {
      walk(child);
      return true;
    });
  }

  walk(root!);

  for (final entry in children.entries) {
    expect(
      parents.contains(entry.key),
      isTrue,
      reason:
          'Orphan traversalChild SemanticsNode#${entry.value.id} '
          '(${entry.key}) has no attached traversalParent in the semantics tree',
    );
  }
}

class _FakePlayerNotifier extends Notifier<PlayerState>
    implements PlayerNotifier {
  final PlayerState initialState;
  _FakePlayerNotifier(this.initialState);

  @override
  PlayerState build() => initialState;

  @override
  PlaybackTrack? get currentPlaybackTrack => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsNotifier extends Notifier<SettingsState>
    implements SettingsNotifier {
  @override
  SettingsState build() => SettingsState(selectedCountry: 'US');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPlaybackController implements PlaybackController {
  _StubPlaybackController(this.renderer);

  @override
  final dynamic renderer;

  @override
  PlaybackStatus get currentStatus => const PlaybackStatus();

  @override
  Stream<PlaybackStatus> get statusStream => const Stream.empty();

  @override
  Stream<PlaybackEvent> get eventStream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'PlayerRouteTransitionBoundary prevents orphaned OverlayPortal/Slider traversal children during HeroController frame-1 offstage and repeated push/pop cycles',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final navKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              navigatorKey: navKey,
              home: const Scaffold(body: Center(child: Text('Home'))),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Route<void> buildPlayerRoute() => PageRouteBuilder<void>(
          transitionDuration: playerTransitionDuration,
          reverseTransitionDuration: playerTransitionDuration,
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
            body: Column(
              children: [
                Tooltip(
                  message: 'Play',
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Play'),
                  ),
                ),
                Slider(value: 0.3, onChanged: (_) {}),
              ],
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PlayerRouteTransitionBoundary(
              animation: animation,
              child: child,
            );
          },
        );

        // Run 20 consecutive rapid open/close cycles and assert no orphaned
        // traversalChild nodes at frame 1 (offstage), mid-transition, settled,
        // and reverse pop frames.
        for (int cycle = 0; cycle < 20; cycle++) {
          navKey.currentState!.push(buildPlayerRoute());
          // Frame 1: HeroController puts the pushed PageRoute offstage (opacity 0).
          await tester.pump();
          expectNoOrphanTraversalChildren(tester);

          // Frame 2: Route moves onstage while FadeTransition opacity is still 0.0
          // (Interval starts at 0.35).
          await tester.pump(const Duration(milliseconds: 16));
          expectNoOrphanTraversalChildren(tester);

          // Mid-transition (opacity > 0).
          await tester.pump(const Duration(milliseconds: 150));
          expectNoOrphanTraversalChildren(tester);

          // Settled open.
          await tester.pumpAndSettle();
          expectNoOrphanTraversalChildren(tester);

          // Pop and check reverse transition frames.
          navKey.currentState!.pop();
          await tester.pump();
          expectNoOrphanTraversalChildren(tester);
          await tester.pump(const Duration(milliseconds: 220));
          expectNoOrphanTraversalChildren(tester);
          await tester.pumpAndSettle();
          expectNoOrphanTraversalChildren(tester);
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'PlayerOverlays exposes accessible button labels/roles and preserves traversal consistency when auto-hiding controls',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final track = Track(
          spotifyId: 'track-1',
          name: 'Test Track',
          artistId: 'artist-1',
          artistName: 'Test Artist',
          sourceType: TrackSourceType.local,
        );
        final queue = PlaybackQueue(tracks: [track], currentIndex: 0);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playerProvider.overrideWith(
                () => _FakePlayerNotifier(
                  PlayerState(playbackQueue: queue, isPlaying: true),
                ),
              ),
              playbackStatusProvider.overrideWith(
                (ref) => const Stream<PlaybackStatus>.empty(),
              ),
              settingsProvider.overrideWith(() => _FakeSettingsNotifier()),
              appDatabaseProvider.overrideWithValue(db),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: PlayerOverlays(
                  isFullscreen: false,
                  onToggleFullscreen: () {},
                  onCollapse: () {},
                  onToggleQueue: () {},
                  middleTopBar: const SizedBox(),
                  alwaysShowControls: false,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expectNoOrphanTraversalChildren(tester);

        // Verify essential controls are exposed with button/slider roles & labels.
        final backSemantics = tester.getSemantics(
          find.byKey(const ValueKey('player_back_button_permanent')),
        );
        expect(backSemantics.flagsCollection.isButton, isTrue);
        expect(backSemantics.label, isNotEmpty);

        expect(find.bySemanticsLabel('Play On'), findsOneWidget);
        expect(find.bySemanticsLabel('Previous'), findsOneWidget);
        expect(find.bySemanticsLabel('Next'), findsOneWidget);
        expect(find.bySemanticsLabel('Pause'), findsOneWidget);
        expect(find.bySemanticsLabel('More options'), findsOneWidget);
        expect(find.bySemanticsLabel('Favorites'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);

        // Let the 3s auto-hide timer expire and AnimatedOpacity animate to 0.0.
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 400));
        expectNoOrphanTraversalChildren(tester);

        // Clean unmount and flush drift timers.
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 4));
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'TactileIconButton and TactilePlayerPlayPauseButton support keyboard Tab focus and Enter/Space activation',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        int prevTaps = 0;
        int playTaps = 0;
        int nextTaps = 0;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Row(
                children: [
                  TactileIconButton(
                    icon: Icons.skip_previous,
                    tooltip: 'Previous',
                    onTap: () => prevTaps++,
                  ),
                  TactilePlayerPlayPauseButton(
                    isPlaying: false,
                    onTap: () => playTaps++,
                  ),
                  TactileIconButton(
                    icon: Icons.skip_next,
                    tooltip: 'Next',
                    onTap: () => nextTaps++,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tab to Previous button and activate with Enter.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(prevTaps, 1);

        // Tab to Play/Pause button and activate with Space.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(playTaps, 1);

        // Tab to Next button and activate with Enter.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(nextTaps, 1);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'PlaybackView keeps renderer error/subtitle semantics accessible and disposes cleanly',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final controller = _StubPlaybackController(
          const Center(child: Text('Caption line 1')),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlaybackView(
                controller: controller,
                status: const PlaybackStatus(state: PlaybackState.playing),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.bySemanticsLabel('Caption line 1'), findsOneWidget);

        // Unmount cleanly.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      } finally {
        semantics.dispose();
      }
    },
  );
}
