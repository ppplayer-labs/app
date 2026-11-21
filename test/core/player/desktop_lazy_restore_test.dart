import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/models/resolved_video_candidate.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/features/player/player_screen.dart';
import 'package:ppplayer/l10n/app_localizations.dart';

import 'player_notifier_retry_test.dart' as fakes;

class _RecordingPlaybackController extends fakes.FakePlaybackController {
  int prepareCalls = 0;
  int playCalls = 0;
  final List<({String id, Duration startAt, bool play})> plays = [];
  Duration? recordedStartAt;
  PlaybackStatus _status = const PlaybackStatus();

  @override
  PlaybackStatus get currentStatus => _status;

  @override
  void emitStatus(PlaybackStatus s) {
    _status = s;
    super.emitStatus(s);
  }

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {
    prepareCalls++;
  }

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {
    playCalls++;
    recordedStartAt = startAt;
    plays.add((id: track.id, startAt: startAt, play: play));
    await super.play(track, startAt: startAt, play: play);
  }
}

class _FixedResolveService extends fakes.FakePlaybackService {
  _FixedResolveService({this.fixedCandidates});

  final List<ResolvedVideoCandidate>? fixedCandidates;

  @override
  Future<List<ResolvedVideoCandidate>> resolveCandidates(
    Track track,
    String? regionCode,
  ) async {
    if (fixedCandidates != null) return fixedCandidates!;
    return [
      ResolvedVideoCandidate(
        videoId: track.youtubeVideoId ?? 'dQw4w9WgXcQ',
        title: track.name,
        channel: 'test',
        confidenceScore: 1,
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'desktop startup restore populates PlayerState without eagerly preparing Chromium until resume',
    () async {
      final prevPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final dir = await Directory.systemTemp.createTemp('ppplayer-desktop-restore-');
      Hive.init(dir.path);
      final box = await Hive.openBox('player_state');
      final track0 = fakes.trackWith(spotifyId: 'sp0', youtubeVideoId: 'video000000');
      final track1 = fakes.trackWith(spotifyId: 'sp1', youtubeVideoId: 'videoAAAAAA');
      await box.put(
        'queue',
        jsonEncode(
          PlaybackQueue(tracks: [track0, track1], currentIndex: 1).toJson(),
        ),
      );
      await box.put('positionMs', 12000);
      await box.put('durationMs', 180000);

      final controller = _RecordingPlaybackController();
      final container = ProviderContainer(
        overrides: [
          playbackControllerProvider.overrideWithValue(controller),
          playbackServiceProvider.overrideWithValue(_FixedResolveService()),
          settingsProvider.overrideWith(fakes.FakeSettingsNotifier.new),
        ],
      );
      final sub = container.listen(playerProvider, (_, _) {});
      final notifier = container.read(playerProvider.notifier);

      try {
        await notifier.persistenceSettled;

        // UI state is restored immediately, without spawning CEF/engine.
        final restored = container.read(playerProvider);
        expect(restored.currentIndex, 1);
        expect(restored.currentTrack?.spotifyId, track1.spotifyId);
        expect(restored.position, const Duration(seconds: 12));
        expect(restored.duration, const Duration(seconds: 180));
        expect(restored.isPlaying, isFalse);
        expect(controller.prepareCalls, 0);
        expect(controller.playCalls, 0);

        // Seeking while idle updates saved position before play.
        await notifier.seekTo(const Duration(seconds: 30));
        expect(container.read(playerProvider).position, const Duration(seconds: 30));

        // Pressing Play starts playback from the restored/sought position at the exact queueIndex.
        await notifier.resume();
        expect(controller.playCalls, 1);
        expect(controller.recordedStartAt, const Duration(seconds: 30));
        expect(container.read(playerProvider).currentIndex, 1);
        expect(container.read(playerProvider).position, const Duration(seconds: 30));
        expect(container.read(playerProvider).duration, const Duration(seconds: 180));
      } finally {
        sub.close();
        container.dispose();
        await notifier.persistenceSettled;
        await Hive.close();
        await dir.delete(recursive: true);
        debugDefaultTargetPlatformOverride = prevPlatform;
      }
    },
  );

  test(
    'seeking while idle does not bleed into a different track selected afterwards',
    () async {
      final prevPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final dir = await Directory.systemTemp.createTemp('ppplayer-idle-seek-');
      Hive.init(dir.path);
      final box = await Hive.openBox('player_state');
      final restoredTrack = fakes.trackWith(spotifyId: 'sp1', youtubeVideoId: 'videoAAAAAA');
      await box.put(
        'queue',
        jsonEncode(PlaybackQueue(tracks: [restoredTrack]).toJson()),
      );
      await box.put('positionMs', 15000);
      await box.put('durationMs', 180000);

      final localFile = File('${dir.path}${Platform.pathSeparator}song.mp3');
      await localFile.writeAsBytes(const [0, 1, 2, 3]);
      final otherLocalTrack = Track(
        spotifyId: 'local1',
        name: 'Local Song',
        artistId: 'a1',
        artistName: 'Artist',
        sourceType: TrackSourceType.local,
        localFilePath: localFile.path,
      );

      final controller = _RecordingPlaybackController();
      final container = ProviderContainer(
        overrides: [
          playbackControllerProvider.overrideWithValue(controller),
          playbackServiceProvider.overrideWithValue(_FixedResolveService()),
          settingsProvider.overrideWith(fakes.FakeSettingsNotifier.new),
        ],
      );
      final sub = container.listen(playerProvider, (_, _) {});
      final notifier = container.read(playerProvider.notifier);

      try {
        await notifier.persistenceSettled;
        await notifier.seekTo(const Duration(seconds: 42));
        expect(container.read(playerProvider).position, const Duration(seconds: 42));

        // Now user picks a different local track instead of resuming restoredTrack.
        await notifier.playTrack(otherLocalTrack);
        expect(controller.playCalls, 1);
        expect(controller.recordedStartAt, Duration.zero);
      } finally {
        sub.close();
        container.dispose();
        await notifier.persistenceSettled;
        await Hive.close();
        await dir.delete(recursive: true);
        debugDefaultTargetPlatformOverride = prevPlatform;
      }
    },
  );

  test(
    'candidate failover recovery works after desktop lazy restore',
    () async {
      final prevPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final dir = await Directory.systemTemp.createTemp('ppplayer-restore-failover-');
      Hive.init(dir.path);
      final box = await Hive.openBox('player_state');
      final track = fakes.trackWith(spotifyId: 'sp1', youtubeVideoId: 'videoAAAAAA');
      await box.put(
        'queue',
        jsonEncode(PlaybackQueue(tracks: [track]).toJson()),
      );
      await box.put('positionMs', 20000);
      await box.put('durationMs', 180000);

      final controller = _RecordingPlaybackController();
      final service = _FixedResolveService(
        fixedCandidates: const [
          ResolvedVideoCandidate(
            videoId: 'videoAAAAAA',
            title: 'First',
            channel: 'ch1',
            confidenceScore: 1,
          ),
          ResolvedVideoCandidate(
            videoId: 'videoBBBBBB',
            title: 'Backup',
            channel: 'ch2',
            confidenceScore: 0.9,
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          playbackControllerProvider.overrideWithValue(controller),
          playbackServiceProvider.overrideWithValue(service),
          settingsProvider.overrideWith(fakes.FakeSettingsNotifier.new),
        ],
      );
      final sub = container.listen(playerProvider, (_, _) {});
      final notifier = container.read(playerProvider.notifier);

      try {
        await notifier.persistenceSettled;
        await notifier.resume();
        expect(controller.plays.length, 1);
        expect(controller.plays.first.id, 'videoAAAAAA');
        expect(controller.plays.first.startAt, const Duration(seconds: 20));

        // Simulate candidate 1 failing -> engine should fail over to candidate 2.
        controller.emitStatus(
          const PlaybackStatus(
            state: PlaybackState.error,
            error: 'unavailable_media:150',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.plays.length, 2);
        expect(controller.plays.last.id, 'videoBBBBBB');
      } finally {
        sub.close();
        container.dispose();
        await notifier.persistenceSettled;
        await Hive.close();
        await dir.delete(recursive: true);
        debugDefaultTargetPlatformOverride = prevPlatform;
      }
    },
  );

  testWidgets(
    'PlayerScreen displays artwork when opened on a desktop lazy-restored paused session before first play',
    (tester) async {
      final prevPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final dir = await tester.runAsync(
        () => Directory.systemTemp.createTemp('ppplayer-restore-ui-'),
      );
      await tester.runAsync(() async {
        Hive.init(dir!.path);
        final box = await Hive.openBox('player_state');
        final track = fakes.trackWith(
          spotifyId: 'sp1',
          youtubeVideoId: 'videoAAAAAA',
        );
        await box.put(
          'queue',
          jsonEncode(PlaybackQueue(tracks: [track]).toJson()),
        );
        await box.put('positionMs', 12000);
        await box.put('durationMs', 180000);
      });

      final controller = _RecordingPlaybackController();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            pathProviderChannel,
            (call) async => dir!.path,
          );

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(controller),
              playbackServiceProvider.overrideWithValue(_FixedResolveService()),
              settingsProvider.overrideWith(_PowerSaverSettingsNotifier.new),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: PlayerScreen(),
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byKey(const ValueKey('artwork_view')), findsOneWidget);
        expect(controller.prepareCalls, 0);
        expect(controller.playCalls, 0);
        // Pump past PlayerScreen's safety-net probes (up to 2000ms) so no
        // pending timers remain at test teardown.
        await tester.pump(const Duration(seconds: 3));
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, null);
        await tester.runAsync(() async {
          await db.close();
          await Hive.close();
          await dir?.delete(recursive: true);
        });
        debugDefaultTargetPlatformOverride = prevPlatform;
      }
    },
  );
}

class _PowerSaverSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() {
    return SettingsState(
      selectedCountry: 'US',
      autoplayEnabled: false,
      performanceMode: PerformanceMode.powerSaver,
      isLoaded: true,
    );
  }
}
