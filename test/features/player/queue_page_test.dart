import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/features/player/queue_page.dart';
import 'package:ppplayer/l10n/app_localizations.dart';

class _Player extends PlayerNotifier {
  int? selected;
  @override
  PlayerState build() => const PlayerState(
    playbackQueue: PlaybackQueue(
      tracks: [
        Track(
          spotifyId: 'previous',
          name: 'Previous song',
          artistId: 'artist',
          artistName: 'Artist',
        ),
        Track(
          spotifyId: 'current',
          name: 'Current song',
          artistId: 'artist',
          artistName: 'Artist',
          durationMs: 183000,
        ),
        Track(
          spotifyId: 'next',
          name: 'Next song',
          artistId: 'artist',
          artistName: 'Artist',
          albumName: 'Album',
          durationMs: 215000,
        ),
        Track(
          spotifyId: 'last',
          name: 'Last song',
          artistId: 'artist',
          artistName: 'Artist',
        ),
      ],
      currentIndex: 1,
    ),
  );
  @override
  Future<void> skipTo(int index) async {
    selected = index;
  }

  @override
  void reorderQueue(int from, int to) {
    state = state.copyWith(
      playbackQueue: state.playbackQueue.reorder(from, to),
    );
  }
}

class _Settings extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState(selectedCountry: 'US');
}

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets('queue sections and actions fit a $width pixel viewport', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final player = _Player();
      final container = ProviderContainer(
        overrides: [
          playerProvider.overrideWith(() => player),
          settingsProvider.overrideWith(_Settings.new),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const QueuePage(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Now playing'), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('Previous song'), findsNothing);
      expect(find.text('Current song'), findsOneWidget);
      expect(find.text('3:03'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Next song'));
      expect(player.selected, 2);

      // Reorder only the upcoming segment; keep current/history in place.
      final list = tester.widget<SliverReorderableList>(
        find.byType(SliverReorderableList),
      );
      list.onReorderItem!(0, 1);
      await tester.pump();
      expect(container.read(playerProvider).queue.map((t) => t.spotifyId), [
        'previous',
        'current',
        'last',
        'next',
      ]);
      expect(container.read(playerProvider).currentIndex, 1);
      tester
          .widget<SliverReorderableList>(find.byType(SliverReorderableList))
          .onReorderItem!(1, 0);
      await tester.pump();
      expect(container.read(playerProvider).queue.map((t) => t.spotifyId), [
        'previous',
        'current',
        'next',
        'last',
      ]);
      expect(tester.takeException(), isNull);
    });
  }
}
