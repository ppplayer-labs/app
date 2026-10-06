import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart' hide PlaybackState;
import 'package:ppplayer/core/playback/media_handler.dart';
import 'package:ppplayer/core/playback/media_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;
import 'package:media_kit_video/media_kit_video.dart' show VideoController;
import 'package:drift/native.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:ppplayer/core/db/app_database.dart' as db;
import 'package:ppplayer/core/playback/chromium_playback_engine.dart';
import 'package:ppplayer/core/playback/chromium_media_service.dart';
import 'package:ppplayer/core/playback/hybrid_playback_engine.dart';
import 'package:ppplayer/core/playback/pip_handler.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/models/resolved_video_candidate.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/features/player/player_screen.dart';
import 'package:ppplayer/features/player/player_providers.dart';
import 'package:ppplayer/l10n/app_localization_delegates.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/tactile_buttons.dart';
import '../test/core/player/player_notifier_playback_speed_test.dart'
    as fixtures;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  testWidgets('live YouTube through ppplayer screen controls', (tester) async {
    MediaKit.ensureInitialized();
    PipHandler.init();
    Hive.init(Directory.systemTemp.createTempSync('ppplayer-live-ui-').path);
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    final android = Platform.isAndroid;
    late ChromiumYoutubePlayerController player;
    final playerEvents = <StreamSubscription<Map<String, Object?>>>[];
    ChromiumYoutubePlayerController createPlayer() {
      player = ChromiumYoutubePlayerController(
        documentUrl: 'https://ppplayer.com/chromium/player.html',
      );
      playerEvents.add(
        player.events.listen((event) {
          if (event.containsKey('StateChange') ||
              event.containsKey('PlayerError')) {
            print('LIVE_BROWSER_EVENT $event');
          }
        }),
      );
      return player;
    }

    final engine = ChromiumPlaybackEngine(
      fallback: android
          ? HybridPlaybackEngine(
              backgroundEngine: NativeServicePlaybackEngine(
                startAutomatically: false,
              ),
            )
          : MediaKitPlaybackEngine(),
      initializeCef: () async {
        if (!await ChromiumWebViewController.initialize(
          cachePath: Directory.systemTemp
              .createTempSync('ppplayer-live-browser-')
              .path,
        )) {
          throw StateError('Browser initialization failed');
        }
      },
      createPlayer: createPlayer,
      showBrowser: !android,
      startPlaybackService: android ? ChromiumMediaService.start : null,
      stopPlaybackService: android ? ChromiumMediaService.stop : null,
    );
    final service = fixtures.FakePlaybackService()
      ..candidates = [
        const ResolvedVideoCandidate(
          videoId: 'M7lc1UVf-VE',
          title: 'Live probe',
          channel: 'YouTube',
          confidenceScore: 1,
        ),
      ];
    late ProviderContainer container;
    final handler = android
        ? await AudioService.init<PpPlayerAudioHandler>(
            builder: () => PpPlayerAudioHandler(() => container),
            config: const AudioServiceConfig(
              androidNotificationChannelId: 'com.ppplayer.app.playback',
              androidNotificationChannelName: 'Music Playback',
              androidNotificationOngoing: true,
              androidStopForegroundOnPause: true,
              androidNotificationIcon: 'mipmap/ic_launcher',
            ),
          )
        : PpPlayerAudioHandler(() => container);
    container = ProviderContainer(
      overrides: [
        db.appDatabaseProvider.overrideWithValue(database),
        audioHandlerProvider.overrideWithValue(handler),
        settingsProvider.overrideWith(() => fixtures.FakeSettingsNotifier()),
        playbackServiceProvider.overrideWithValue(service),
        playbackControllerProvider.overrideWithValue(engine),
      ],
    );
    if (android) container.read(mediaSyncServiceProvider);
    Future<void> waitInBackground(
      Future<bool> Function() check,
      String reason,
    ) async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!await check() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(await check(), isTrue, reason: reason);
    }

    Future<bool> isInteractive() async =>
        (await ChromiumMediaService.channel.invokeMapMethod<String, dynamic>(
          'chromiumServiceState',
        ))?['interactive'] ==
        true;
    Future<void> waitFor(bool Function() check, String description) async {
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (!check() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (!check() && engine.renderer is VideoController) {
        final native = (engine.renderer as VideoController).player;
        print(
          'NATIVE_STALL statePosition=${native.state.position} playing=${native.state.playing} duration=${native.state.duration}',
        );
        for (final property in ['time-pos', 'pause', 'ao', 'video-sync']) {
          try {
            final value = await (native.platform as dynamic)
                .getProperty(property)
                .timeout(const Duration(seconds: 2));
            print('NATIVE_STALL $property=$value');
          } catch (error) {
            print('NATIVE_STALL $property error=$error');
          }
        }
      }
      expect(
        check(),
        isTrue,
        reason:
            '$description: ${engine.currentStatus.error}, '
            'state=${engine.currentStatus.state}, position=${engine.currentStatus.position}',
      );
    }

    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const PlayerScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final notifier = container.read(playerProvider.notifier);
      var openingDone = false;
      Object? openingError;
      notifier
          .playTrack(
            const Track(
              spotifyId: 'live-probe',
              name: 'Live probe',
              artistId: 'youtube',
              artistName: 'YouTube',
            ),
          )
          .then(
            (_) => openingDone = true,
            onError: (Object error) {
              openingError = error;
              openingDone = true;
            },
          );
      await waitFor(() => openingDone, 'Track opening timed out');
      if (openingError != null) throw openingError!;
      await waitFor(
        () => engine.currentStatus.position.inSeconds >= 2,
        'Live playback did not progress',
      );
      expect(container.read(playerProvider).isPlaying, isTrue);
      final playButton = find.byType(TactilePlayerPlayPauseButton);
      expect(playButton, findsOneWidget);
      if (!container.read(controlsVisibilityProvider)) {
        await tester.tapAt(tester.getCenter(find.byType(PlayerScreen)));
        await tester.pump(const Duration(milliseconds: 350));
      }
      await tester.tap(playButton);
      await waitFor(
        () => engine.currentStatus.state == PlaybackState.paused,
        'UI pause failed',
      );
      final paused = await player.currentTime;
      await tester.pump(const Duration(seconds: 1));
      expect((await player.currentTime) - paused, lessThan(0.5));
      final seekSlider = find.byType(Slider).first;
      await tester.tapAt(tester.getRect(seekSlider).center);
      await waitFor(
        () => engine.currentStatus.position.inSeconds > 100,
        'UI seeking failed',
      );
      await notifier.seekTo(const Duration(seconds: 10));
      await tester.tap(playButton);
      await waitFor(() => engine.currentStatus.isPlaying, 'UI resume failed');
      await notifier.setVolume(0.35);
      final volumeDeadline = DateTime.now().add(const Duration(seconds: 5));
      while (await player.volume != 35 &&
          DateTime.now().isBefore(volumeDeadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(await player.volume, 35);
      if (android) {
        final state = await ChromiumMediaService.channel
            .invokeMapMethod<String, dynamic>('chromiumServiceState');
        expect(state, containsPair('chromiumPlayer', true));
        expect(state, containsPair('ownsWebView', false));
        expect(engine.renderer, isNull);
        if (const bool.fromEnvironment('PPPLAYER_BACKGROUND_PROBE')) {
          // Android's Home transition needs frames until onStop completes.
          binding.framePolicy =
              LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
          print('CHROMIUM_BACKGROUND_READY');
          await waitInBackground(
            () async => PipHandler.isActivityStopped,
            'Home did not stop the activity',
          );
          final before = await player.currentTime.timeout(
            const Duration(seconds: 8),
          );
          await Future<void>.delayed(const Duration(seconds: 3));
          final after = await player.currentTime.timeout(
            const Duration(seconds: 8),
          );
          expect(PipHandler.isActivityStopped, isTrue);
          expect(after - before, greaterThan(0.5));
          print('CHROMIUM_BACKGROUND_PROGRESS before=$before after=$after');
          print('CHROMIUM_SCREEN_OFF_READY');
          await waitInBackground(
            () async => !await isInteractive(),
            'Device screen did not turn off',
          );
          expect(PipHandler.isActivityStopped, isTrue);
          expect(await isInteractive(), isFalse);
          final screenOffBefore = await player.currentTime.timeout(
            const Duration(seconds: 8),
          );
          await Future<void>.delayed(const Duration(seconds: 20));
          final screenOffAfter = await player.currentTime.timeout(
            const Duration(seconds: 8),
          );
          expect(PipHandler.isActivityStopped, isTrue);
          expect(screenOffAfter - screenOffBefore, greaterThan(10));
          expect(await isInteractive(), isFalse);
          print(
            'CHROMIUM_SCREEN_OFF_PROGRESS before=$screenOffBefore after=$screenOffAfter',
          );
          print('CHROMIUM_SCREEN_ON_READY');
          await waitInBackground(isInteractive, 'Device screen did not wake');
          print('CHROMIUM_MEDIA_PAUSE_READY');
          final pauseDeadline = DateTime.now().add(const Duration(seconds: 10));
          while (engine.currentStatus.state != PlaybackState.paused &&
              DateTime.now().isBefore(pauseDeadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          expect(engine.currentStatus.state, PlaybackState.paused);
          final pausedPosition = await player.currentTime;
          await Future<void>.delayed(const Duration(seconds: 1));
          expect((await player.currentTime) - pausedPosition, lessThan(0.5));
          print('CHROMIUM_MEDIA_PLAY_READY');
          final playDeadline = DateTime.now().add(const Duration(seconds: 10));
          while (!engine.currentStatus.isPlaying &&
              DateTime.now().isBefore(playDeadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          expect(engine.currentStatus.isPlaying, isTrue);
          expect(PipHandler.isActivityStopped, isTrue);
          print('CHROMIUM_BACKGROUND_DONE');
          await Future<void>.delayed(const Duration(seconds: 3));
          await waitInBackground(
            () async => !PipHandler.isActivityStopped,
            'Activity did not restore',
          );
          binding.framePolicy =
              LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
        }
      }
      if (const bool.fromEnvironment('PPPLAYER_SOURCE_SWITCH_PROBE')) {
        // Native video surfaces need the same continuous frames as the app.
        binding.framePolicy =
            LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
        final data = await rootBundle.load(
          'assets/test_fixtures/test_video.mp4',
        );
        final file = File(
          '${Directory.systemTemp.createTempSync('ppplayer-source-probe-').path}/video.mp4',
        );
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        final local = Track.fromLocalFile(
          libraryId: 'local:source-probe',
          name: 'Local source probe',
          artistName: 'Local',
          albumName: 'Probe',
          localFilePath: file.path,
          isVideoFile: true,
        );
        for (var attempt = 1; attempt <= 3; attempt++) {
          final previousPlayer = player;
          var localDone = false;
          Object? localError;
          notifier
              .playTrack(local)
              .then(
                (_) => localDone = true,
                onError: (Object error) {
                  localError = error;
                  localDone = true;
                },
              );
          await waitFor(() => localDone, 'Local switch $attempt timed out');
          if (localError != null) throw localError!;
          await waitFor(
            () => engine.currentStatus.position.inMilliseconds > 400,
            'Local switch $attempt did not progress',
          );
          expect(engine.currentStatus.isIFrameMode, isFalse);
          expect(() => previousPlayer.currentTime, throwsStateError);
          if (android) {
            final serviceState = await ChromiumMediaService.channel
                .invokeMapMethod<String, dynamic>('chromiumServiceState');
            expect(serviceState, containsPair('running', false));
          }
          var restartDone = false;
          Object? restartError;
          notifier
              .playTrack(
                const Track(
                  spotifyId: 'live-probe',
                  name: 'Live probe',
                  artistId: 'youtube',
                  artistName: 'YouTube',
                ),
              )
              .then(
                (_) => restartDone = true,
                onError: (Object error) {
                  restartError = error;
                  restartDone = true;
                },
              );
          await waitFor(
            () => restartDone,
            'Browser restart $attempt timed out',
          );
          if (restartError != null) throw restartError!;
          await waitFor(
            () => engine.currentStatus.position.inSeconds >= 2,
            'Browser restart $attempt did not progress',
          );
          expect(identical(previousPlayer, player), isFalse);
          print(
            'CHROMIUM_SOURCE_SWITCH_PASS attempt=$attempt position=${engine.currentStatus.position}',
          );
        }
      }
      print(
        'PPPLAYER_LIVE_UI_PASS platform=${Platform.operatingSystem} volume=${await player.volume}',
      );
    } finally {
      if (android && const bool.fromEnvironment('PPPLAYER_BACKGROUND_PROBE')) {
        // Restore the activity even when a background assertion fails, so
        // widget cleanup can receive frames and report the original failure.
        print('CHROMIUM_BACKGROUND_DONE');
        await Future<void>.delayed(const Duration(seconds: 2));
        await waitInBackground(
          () async => !PipHandler.isActivityStopped,
          'Activity did not restore for cleanup',
        );
      }
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
      await tester.pumpWidget(const SizedBox());
      if (android) await handler.stop();
      container.dispose();
      for (final subscription in playerEvents) {
        await subscription.cancel();
      }
      await engine.dispose();
      await database.close();
      await Hive.close();
    }
  });
}
