import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ppplayer/features/player/player_screen.dart';
import 'package:go_router/go_router.dart';
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

      await tester.binding.setSurfaceSize(const Size(1200, 800));

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
            theme: ThemeData.dark(),
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
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('queue_toggle_button')))
            .bottom,
        lessThanOrEqualTo(568),
      );
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump(const Duration(milliseconds: 500));

      // Queue navigation opens only the queue, independently of viewport size.
      await tester.tap(find.byKey(const ValueKey('queue_toggle_button')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(QueueScreen), findsOneWidget);
      expect(find.byType(PlayerScreen), findsNothing);
      expect(find.byKey(const ValueKey('desktop_queue_panel')), findsNothing);
      expect(find.byKey(const ValueKey('export_queue_button')), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(QueueScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Back returns to the existing video page without changing playback mode.
      router.pop();
      await tester.pump(const Duration(milliseconds: 500));
      expect(videoSlotFinder, findsOneWidget);
      expect(find.byType(QueueScreen), findsNothing);
      final context = tester.element(find.byType(PlayerScreen));
      expect(
        ProviderScope.containerOf(context).read(settingsProvider).playerView,
        PlayerView.video,
      );

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
      await tester.pump(const Duration(milliseconds: 50));

      // Unmount and flush drift stream cancellation timers
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pump(
        const Duration(seconds: 3),
      ); // Flush engine dispose timers
    },
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
