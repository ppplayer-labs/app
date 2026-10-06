import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/compact_desktop_navigation.dart';
import 'package:ppplayer/shared/widgets/scaffold_with_nav.dart';

class TestPlayer extends PlayerNotifier {
  @override
  PlayerState build() => const PlayerState(
    playbackQueue: PlaybackQueue(
      tracks: [
        Track(
          spotifyId: 'track',
          name: 'A very long song title that needs room',
          artistId: 'artist',
          artistName: 'An artist with a long name',
        ),
      ],
    ),
  );
  @override
  PlaybackTrack? get currentPlaybackTrack => null;
  @override
  void toggleShuffle() {
    state = state.copyWith(
      playbackQueue: state.playbackQueue.copyWith(isShuffled: true),
    );
  }
}

class TestSettings extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState(selectedCountry: 'US');
  @override
  Future<void> setPlayerView(PlayerView view) async {
    state = state.copyWith(playerView: view);
  }
}

void main() {
  testWidgets(
    'Queue button opens a sheet in narrow windows without changing video mode',
    (tester) async {
      tester.view.physicalSize = const Size(610, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: DesktopPlayerBar()),
          ),
          GoRoute(
            path: '/queue',
            builder: (_, _) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Text(
                  'Selected view: ${ref.watch(settingsProvider).playerView.name}',
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerProvider.overrideWith(TestPlayer.new),
            settingsProvider.overrideWith(TestSettings.new),
            networkOutputSnapshotProvider.overrideWith(
              (_) => const NetworkOutputState(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Queue'));
      await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(DesktopPlayerBar), findsOneWidget);
      final context = tester.element(find.byType(DesktopPlayerBar));
      expect(
        ProviderScope.containerOf(context).read(settingsProvider).playerView,
        PlayerView.video,
      );
      await tester.tap(find.byKey(const ValueKey('queue_dismiss_button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  Widget app(Widget child, {double scale = 1}) => ProviderScope(
    overrides: [
      playerProvider.overrideWith(TestPlayer.new),
      settingsProvider.overrideWith(TestSettings.new),
      networkOutputSnapshotProvider.overrideWith(
        (_) => const NetworkOutputState(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: widget!,
      ),
      home: Scaffold(body: child),
    ),
  );

  for (final width in [600.0, 610.0, 800.0, 999.0, 1000.0, 1200.0]) {
    testWidgets('playback controls fit a $width pixel desktop window', (
      tester,
    ) async {
      tester.view.reset();
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          const Align(
            alignment: Alignment.bottomCenter,
            child: DesktopPlayerBar(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final tooltip in ['Play On', 'Queue']) {
        final button = find.byTooltip(tooltip);
        expect(button, findsOneWidget);
        final bounds = tester.getRect(button);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(width));
      }
      if (width < 1000) {
        await tester.tap(find.byTooltip('More playback controls'));
        await tester.pumpAndSettle();
        expect(find.text('Shuffle: Off'), findsOneWidget);
        expect(find.text('Repeat: Off'), findsOneWidget);
        expect(find.text('Hide video'), findsOneWidget);
        expect(find.text('Volume'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Shuffle: Off'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('More playback controls'));
        await tester.pumpAndSettle();
        expect(find.text('Shuffle: On'), findsOneWidget);
      }
    });
  }

  testWidgets(
    'compact navigation stays usable in short windows and reaches favorites',
    (tester) async {
      tester.view.physicalSize = const Size(610, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? destination;
      await tester.pumpWidget(
        app(
          Align(
            alignment: Alignment.centerLeft,
            child: CompactDesktopNavigation(
              location: '/home',
              onNavigate: (path) => destination = path,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(CompactDesktopNavigation)).width, 72);
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.favorite_outline));
      expect(destination, '/liked-songs');
      expect(tester.takeException(), isNull);
    },
  );
}
