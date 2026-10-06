import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ppplayer/features/player/player_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:ppplayer/features/player/queue_page.dart';
import 'package:ppplayer/features/player/queue_presentation.dart';
import 'package:ppplayer/core/models/track.dart';

import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ppplayer.app/network_output_events'),
      (_) async => null,
    );
  });

  tearDown(() async {
    await db.close();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ppplayer.app/network_output_events'),
      null,
    );
  });

  testWidgets(
    'PlayerScreen keeps video slot mounted during queue transitions and breakpoints',
    (WidgetTester tester) async {
      final track = Track(
        youtubeVideoId: 'test',
        spotifyId: 'test',
        name: 'Test',
        albumImage: 'file:///preview-cover.png',
        artistId: 'test',
        artistName: 'Artist',
        sourceType: TrackSourceType.online,
      );
      final queue = PlaybackQueue(tracks: [track], currentIndex: 0);

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;

      final router = GoRouter(
        initialLocation: '/player',
        routes: [
          GoRoute(path: '/player', builder: (_, _) => const PlayerScreen()),
          GoRoute(path: '/queue', builder: (_, _) => const QueueScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerProvider.overrideWith(
              () => FakePlayerNotifier(
                PlayerState(playbackQueue: queue, isPlaying: true),
              ),
            ),
            playbackStatusProvider.overrideWith(
              (ref) => Stream.value(
                const PlaybackStatus(
                  state: PlaybackState.playing,
                  hasVideo: true,
                ),
              ),
            ),
            settingsProvider.overrideWith(() => FakeSettingsNotifier()),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp.router(
            theme: ThemeData.dark().copyWith(platform: TargetPlatform.windows),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The video slot should be mounted
      final videoSlotFinder = find.byWidgetPredicate(
        (widget) =>
            widget.key is GlobalKey &&
            widget.key.toString().contains('player_video_slot'),
      );
      expect(videoSlotFinder, findsOneWidget);

      // Queue navigation is labeled even before the panel is opened.
      expect(find.byKey(const ValueKey('queue_toggle_button')), findsOneWidget);

      // Actual player overlays must fit a narrow phone.
      tester.view.physicalSize = const Size(320, 568);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('queue_toggle_button')))
            .bottom,
        lessThanOrEqualTo(568),
      );
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pump(const Duration(milliseconds: 500));

      // Desktop queue toggles panel state without leaving the player route.
      expect(
        supportsQueuePanel(tester.element(find.byType(PlayerScreen))),
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('queue_toggle_button')));
      await tester.pump(const Duration(milliseconds: 500));
      final context = tester.element(find.byType(PlayerScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(queuePanelProvider), isTrue);
      expect(videoSlotFinder, findsOneWidget);
      expect(router.canPop(), isFalse);
      container.read(queuePanelProvider.notifier).close();

      // Narrow windows/mobile show a dismissible sheet over the same route.
      tester.view.physicalSize = const Size(320, 568);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('queue_toggle_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(QueuePage), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(QueuePage),
          matching: find.text('Test'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('queue_dismiss_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(QueuePage), findsNothing);
      expect(videoSlotFinder, findsOneWidget);
      expect(container.read(settingsProvider).playerView, PlayerView.video);

      // Reset surface size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pump(const Duration(milliseconds: 50));

      // Unmount and flush drift stream cancellation timers
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pump(
        const Duration(seconds: 3),
      ); // Flush engine dispose timers
    },
    variant: TargetPlatformVariant({TargetPlatform.windows}),
  );
}

class FakePlayerNotifier extends Notifier<PlayerState>
    implements PlayerNotifier {
  final PlayerState initialState;
  FakePlayerNotifier(this.initialState);
  @override
  PlayerState build() => initialState;

  @override
  PlaybackTrack? get currentPlaybackTrack => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsNotifier extends Notifier<SettingsState>
    implements SettingsNotifier {
  @override
  SettingsState build() => SettingsState(selectedCountry: 'US');

  @override
  Future<void> setPlayerView(PlayerView view) async {
    state = state.copyWith(playerView: view);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
