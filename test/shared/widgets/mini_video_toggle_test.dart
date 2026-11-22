import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/scaffold_with_nav.dart';

class _SurfaceProbeMetrics {
  int initCount = 0;
  int disposeCount = 0;
  final List<Size> layoutSizes = <Size>[];
}

class _VideoSurfaceProbe extends StatefulWidget {
  const _VideoSurfaceProbe({required this.metrics});

  final _SurfaceProbeMetrics metrics;

  @override
  State<_VideoSurfaceProbe> createState() => _VideoSurfaceProbeState();
}

class _VideoSurfaceProbeState extends State<_VideoSurfaceProbe> {
  @override
  void initState() {
    super.initState();
    widget.metrics.initCount++;
  }

  @override
  void dispose() {
    widget.metrics.disposeCount++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (widget.metrics.layoutSizes.isEmpty ||
            widget.metrics.layoutSizes.last != size) {
          widget.metrics.layoutSizes.add(size);
        }
        return const ColoredBox(
          key: ValueKey('probe_video_frame'),
          color: Colors.green,
        );
      },
    );
  }
}

class _FakePlaybackController implements PlaybackController {
  _FakePlaybackController(this.metrics, this._status);

  final _SurfaceProbeMetrics metrics;
  final PlaybackStatus _status;
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _eventController = StreamController<PlaybackEvent>.broadcast();

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<PlaybackEvent> get eventStream => _eventController.stream;

  @override
  PlaybackStatus get currentStatus => _status;

  @override
  dynamic get renderer => _VideoSurfaceProbe(metrics: metrics);

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {}

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setSubtitleTrack(String? uri) async {}

  @override
  Future<void> setSubtitleDelay(Duration delay) async {}

  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {}

  @override
  bool get supportsSpeed => false;

  @override
  bool get supportsTrackSelection => false;

  @override
  bool get supportsExternalSubtitles => false;

  @override
  bool get supportsSubtitleDelay => false;

  @override
  bool get supportsSubtitleTextSize => false;

  @override
  bool get supportsSubtitleBackgroundStyling => false;

  @override
  bool get supportsVideoFitMode => false;

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {}

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _eventController.close();
  }
}

class _FakePlayerNotifier extends PlayerNotifier {
  @override
  PlayerState build() => const PlayerState(
    videoId: 'dQw4w9WgXcQ',
    isPlaying: true,
    duration: Duration(minutes: 3),
    position: Duration(seconds: 30),
    playbackQueue: PlaybackQueue(
      tracks: [
        Track(
          spotifyId: 'track-1',
          name: 'Test Video Track',
          artistId: 'artist-1',
          artistName: 'Test Artist',
          youtubeVideoId: 'dQw4w9WgXcQ',
        ),
      ],
    ),
  );

  @override
  PlaybackTrack? get currentPlaybackTrack => null;
}

class _InMemorySettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState(
    selectedCountry: 'US',
    showVideo: true,
    playerView: PlayerView.video,
    isLoaded: true,
  );

  @override
  Future<void> toggleVideo() async {
    final newValue = !state.showVideo;
    final nextView = newValue
        ? PlayerView.video
        : (state.playerView == PlayerView.video
              ? PlayerView.artwork
              : state.playerView);
    state = state.copyWith(showVideo: newValue, playerView: nextView);
  }

  @override
  Future<void> setPlayerView(PlayerView view) async {
    final nextShowVideo = switch (view) {
      PlayerView.video => true,
      PlayerView.artwork => false,
      PlayerView.queue => state.showVideo,
    };
    state = state.copyWith(playerView: view, showVideo: nextShowVideo);
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<GoRouter> pumpShell(
    WidgetTester tester, {
    required Size windowSize,
    required _SurfaceProbeMetrics metrics,
  }) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const status = PlaybackStatus(
      state: PlaybackState.playing,
      isIFrameMode: true,
      hasVideo: true,
      activeVideoId: 'dQw4w9WgXcQ',
    );
    final controller = _FakePlaybackController(metrics, status);
    addTearDown(controller.dispose);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const ScaffoldWithNav(
            location: '/home',
            child: SizedBox.expand(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playbackControllerProvider.overrideWithValue(controller),
          playbackStatusProvider.overrideWith((_) => Stream.value(status)),
          playerProvider.overrideWith(_FakePlayerNotifier.new),
          settingsProvider.overrideWith(_InMemorySettingsNotifier.new),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return router;
  }

  testWidgets(
    'desktop rapid Hide/Show toggling keeps mini video mounted at constant 160x90 with zero resizes',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final metrics = _SurfaceProbeMetrics();
        await pumpShell(
          tester,
          windowSize: const Size(1280, 800),
          metrics: metrics,
        );

        final probeFinder = find.byKey(const ValueKey('probe_video_frame'));
        expect(probeFinder, findsOneWidget);
        expect(metrics.initCount, 1);
        expect(metrics.disposeCount, 0);
        expect(metrics.layoutSizes, [const Size(160, 90)]);

        final initialRect = tester.getRect(probeFinder);
        expect(initialRect.size, const Size(160, 90));
        expect(initialRect.left, greaterThan(0));
        expect(initialRect.top, greaterThan(0));
        expect(
          find.byKey(const ValueKey('video_thumbnail_open')),
          findsOneWidget,
        );

        // Rapidly toggle Hide/Show 12 times in quick succession (even -> shown).
        for (var i = 0; i < 12; i++) {
          final isCurrentlyShown = i.isEven;
          final button = find.byTooltip(
            isCurrentlyShown ? 'Hide video' : 'Show video',
          );
          expect(button, findsOneWidget);
          await tester.tap(button);
          // Pump short 16ms frames to simulate rapid clicking mid-transition.
          await tester.pump(const Duration(milliseconds: 16));

          final rect = tester.getRect(probeFinder);
          expect(rect.size, const Size(160, 90));
          if (isCurrentlyShown) {
            // Just hidden: immediately parked off-screen on desktop.
            expect(rect.left, -9999.0);
            expect(rect.top, -9999.0);
            expect(
              find.byKey(const ValueKey('video_thumbnail_open')),
              findsNothing,
            );
          } else {
            // Just shown: immediately restored to mini-player bounds.
            expect(rect, initialRect);
            expect(
              find.byKey(const ValueKey('video_thumbnail_open')),
              findsOneWidget,
            );
          }
        }

        await tester.pump(const Duration(milliseconds: 300));

        // Surface must never have been recreated, disposed, or resized away from 160x90.
        expect(metrics.initCount, 1);
        expect(metrics.disposeCount, 0);
        expect(metrics.layoutSizes, [const Size(160, 90)]);
        expect(tester.getRect(probeFinder), initialRect);

        // Unmount before teardown so Drift's StreamQueryStore zero-duration
        // close timer flushes inside the test frame.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'mobile rapid Hide/Show toggling preserves 2x2 peek without shrinking surface below 160x90',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final metrics = _SurfaceProbeMetrics();
        const mobileSize = Size(400, 800);
        await pumpShell(tester, windowSize: mobileSize, metrics: metrics);

        final probeFinder = find.byKey(const ValueKey('probe_video_frame'));
        expect(probeFinder, findsOneWidget);
        expect(metrics.initCount, 1);
        expect(metrics.layoutSizes, [const Size(160, 90)]);

        final initialRect = tester.getRect(probeFinder);
        expect(initialRect.size, const Size(160, 90));

        // Rapidly toggle Hide/Show 10 times (even -> ends shown).
        for (var i = 0; i < 10; i++) {
          final isCurrentlyShown = i.isEven;
          final button = find.byTooltip(
            isCurrentlyShown ? 'Hide video' : 'Show video',
          );
          expect(button, findsOneWidget);
          await tester.tap(button);
          await tester.pump(const Duration(milliseconds: 16));

          final rect = tester.getRect(probeFinder);
          // Layout size NEVER shrinks to 2x2; only position shifts to 2x2 peek.
          expect(rect.size, const Size(160, 90));
          if (isCurrentlyShown) {
            expect(rect.left, mobileSize.width - 2.0);
            expect(rect.top, mobileSize.height - 2.0);
          } else {
            expect(rect, initialRect);
          }
        }

        await tester.pump(const Duration(milliseconds: 300));

        expect(metrics.initCount, 1);
        expect(metrics.disposeCount, 0);
        expect(metrics.layoutSizes, [const Size(160, 90)]);
        expect(tester.getRect(probeFinder), initialRect);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
