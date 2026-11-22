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
        return Semantics(
          label: 'probe_video_semantics',
          child: const ColoredBox(
            key: ValueKey('probe_video_frame'),
            color: Colors.green,
          ),
        );
      },
    );
  }
}

class _FakePlaybackController implements PlaybackController {
  _FakePlaybackController(this.metrics, this._status);

  final _SurfaceProbeMetrics metrics;
  PlaybackStatus _status;
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _eventController = StreamController<PlaybackEvent>.broadcast();

  void emitStatus(PlaybackStatus next) {
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }

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
  _FakePlayerNotifier({
    this.initialIsPlaying = true,
    this.initialIsPipMode = false,
  });

  final bool initialIsPlaying;
  final bool initialIsPipMode;

  @override
  PlayerState build() => PlayerState(
    videoId: 'dQw4w9WgXcQ',
    isPlaying: initialIsPlaying,
    isPipMode: initialIsPipMode,
    duration: const Duration(minutes: 3),
    position: const Duration(seconds: 30),
    playbackQueue: const PlaybackQueue(
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

  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void setPip(bool pip) {
    state = state.copyWith(isPipMode: pip);
  }

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

class _ShellHarness {
  _ShellHarness({
    required this.router,
    required this.controller,
    required this.playerNotifier,
  });

  final GoRouter router;
  final _FakePlaybackController controller;
  final _FakePlayerNotifier playerNotifier;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<_ShellHarness> pumpShell(
    WidgetTester tester, {
    required Size windowSize,
    required _SurfaceProbeMetrics metrics,
    PlaybackState initialPlaybackState = PlaybackState.playing,
    bool initialIsPlaying = true,
    bool initialIsPipMode = false,
  }) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final status = PlaybackStatus(
      state: initialPlaybackState,
      isIFrameMode: true,
      hasVideo: true,
      activeVideoId: 'dQw4w9WgXcQ',
    );
    final controller = _FakePlaybackController(metrics, status);
    addTearDown(controller.dispose);
    final playerNotifier = _FakePlayerNotifier(
      initialIsPlaying: initialIsPlaying,
      initialIsPipMode: initialIsPipMode,
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              ScaffoldWithNav(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const SizedBox.expand(),
            ),
            GoRoute(
              path: '/discover',
              builder: (context, state) => const SizedBox.expand(),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const SizedBox.expand(),
            ),
            GoRoute(
              path: '/player',
              builder: (context, state) => const SizedBox.expand(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playbackControllerProvider.overrideWithValue(controller),
          playbackStatusProvider.overrideWith((_) => controller.statusStream),
          playerProvider.overrideWith(() => playerNotifier),
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
    controller.emitStatus(status);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return _ShellHarness(
      router: router,
      controller: controller,
      playerNotifier: playerNotifier,
    );
  }

  Future<void> unmountCleanly(WidgetTester tester) async {
    // Unmount before teardown so Drift's StreamQueryStore zero-duration
    // close timer flushes inside the test frame.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> runDesktopToggleCycle(
    WidgetTester tester, {
    required int toggleCount,
    required _SurfaceProbeMetrics metrics,
    required Rect initialRect,
    Duration frameInterval = const Duration(milliseconds: 16),
  }) async {
    final probeFinder = find.byKey(const ValueKey('probe_video_frame'));
    var shown = true;
    for (var i = 0; i < toggleCount; i++) {
      final button = find.byTooltip(shown ? 'Hide video' : 'Show video');
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump(frameInterval);
      shown = !shown;

      final rect = tester.getRect(probeFinder);
      expect(rect.size, const Size(160, 90));
      if (!shown) {
        expect(rect.left, -9999.0);
        expect(rect.top, -9999.0);
        expect(
          find.byKey(const ValueKey('video_thumbnail_open')),
          findsNothing,
        );
      } else {
        expect(rect, initialRect);
        expect(
          find.byKey(const ValueKey('video_thumbnail_open')),
          findsOneWidget,
        );
      }
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(metrics.initCount, 1);
    expect(metrics.disposeCount, 0);
    expect(metrics.layoutSizes, [const Size(160, 90)]);
    expect(metrics.layoutSizes.contains(const Size(2, 2)), isFalse);
  }

  for (final count in [2, 5, 10, 50, 100]) {
    testWidgets(
      'desktop $count rapid Hide/Show toggles keep mini video mounted at constant 160x90 with zero resizes',
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
          final initialRect = tester.getRect(probeFinder);
          expect(initialRect.size, const Size(160, 90));

          await runDesktopToggleCycle(
            tester,
            toggleCount: count,
            metrics: metrics,
            initialRect: initialRect,
          );

          final finalRect = tester.getRect(probeFinder);
          if (count.isEven) {
            expect(finalRect, initialRect);
          } else {
            expect(finalRect.left, -9999.0);
            expect(finalRect.top, -9999.0);
          }

          await unmountCleanly(tester);
          expect(metrics.disposeCount, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }

  testWidgets(
    'desktop single Hide -> Show cycle restores exact bounds and toggles IgnorePointer & ExcludeSemantics',
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
        final initialRect = tester.getRect(probeFinder);

        ExcludeSemantics surfaceSemantics() => tester.widget<ExcludeSemantics>(
          find
              .ancestor(
                of: probeFinder,
                matching: find.byType(ExcludeSemantics),
              )
              .first,
        );
        IgnorePointer surfaceIgnorePointer() => tester.widget<IgnorePointer>(
          find
              .ancestor(of: probeFinder, matching: find.byType(IgnorePointer))
              .first,
        );

        expect(surfaceSemantics().excluding, isFalse);
        expect(surfaceIgnorePointer().ignoring, isFalse);

        // Hide
        await tester.tap(find.byTooltip('Hide video'));
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.getRect(probeFinder),
          const Rect.fromLTWH(-9999, -9999, 160, 90),
        );
        expect(surfaceSemantics().excluding, isTrue);
        expect(surfaceIgnorePointer().ignoring, isTrue);

        // Show
        await tester.tap(find.byTooltip('Show video'));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getRect(probeFinder), initialRect);
        expect(surfaceSemantics().excluding, isFalse);
        expect(surfaceIgnorePointer().ignoring, isFalse);

        expect(metrics.initCount, 1);
        expect(metrics.disposeCount, 0);
        expect(metrics.layoutSizes, [const Size(160, 90)]);

        await unmountCleanly(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'desktop Hide/Show toggles during loading, playing, and paused states never recreate or resize surface',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final metrics = _SurfaceProbeMetrics();
        final harness = await pumpShell(
          tester,
          windowSize: const Size(1280, 800),
          metrics: metrics,
          initialPlaybackState: PlaybackState.buffering,
          initialIsPlaying: false,
        );

        final probeFinder = find.byKey(const ValueKey('probe_video_frame'));
        final initialRect = tester.getRect(probeFinder);

        // 1. Loading state
        await runDesktopToggleCycle(
          tester,
          toggleCount: 6,
          metrics: metrics,
          initialRect: initialRect,
        );

        // 2. Playing state
        harness.playerNotifier.setPlaying(true);
        harness.controller.emitStatus(
          const PlaybackStatus(
            state: PlaybackState.playing,
            isIFrameMode: true,
            hasVideo: true,
            activeVideoId: 'dQw4w9WgXcQ',
          ),
        );
        await tester.pump();
        await runDesktopToggleCycle(
          tester,
          toggleCount: 6,
          metrics: metrics,
          initialRect: initialRect,
        );

        // 3. Paused state
        harness.playerNotifier.setPlaying(false);
        harness.controller.emitStatus(
          const PlaybackStatus(
            state: PlaybackState.paused,
            isIFrameMode: true,
            hasVideo: true,
            activeVideoId: 'dQw4w9WgXcQ',
          ),
        );
        await tester.pump();
        await runDesktopToggleCycle(
          tester,
          toggleCount: 6,
          metrics: metrics,
          initialRect: initialRect,
        );

        expect(metrics.initCount, 1);
        expect(metrics.disposeCount, 0);
        expect(metrics.layoutSizes, [const Size(160, 90)]);

        await unmountCleanly(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'desktop Hide/Show toggles during route navigation and window resizing preserve 160x90 with zero 2x2 sizes',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final metrics = _SurfaceProbeMetrics();
        final harness = await pumpShell(
          tester,
          windowSize: const Size(1280, 800),
          metrics: metrics,
        );

        final probeFinder = find.byKey(const ValueKey('probe_video_frame'));
        expect(metrics.layoutSizes, [const Size(160, 90)]);

        // Navigate across shell routes while toggling Hide/Show.
        for (final route in ['/discover', '/search', '/home']) {
          harness.router.go(route);
          await tester.pump(const Duration(milliseconds: 16));
          await tester.tap(find.byTooltip('Hide video'));
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.getRect(probeFinder).size, const Size(160, 90));
          await tester.tap(find.byTooltip('Show video'));
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.getRect(probeFinder).size, const Size(160, 90));
        }

        // Resize window dynamically while toggling Hide/Show (including compact overflow bar).
        for (final size in [
          const Size(1024, 700),
          const Size(1440, 900),
          const Size(1100, 680),
          const Size(1280, 800),
        ]) {
          tester.view.physicalSize = size;
          await tester.pump(const Duration(milliseconds: 16));
          await tester.tap(find.byTooltip('Hide video'));
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.getRect(probeFinder).size, const Size(160, 90));
          await tester.tap(find.byTooltip('Show video'));
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.getRect(probeFinder).size, const Size(160, 90));
        }

        // Narrow desktop width switches player bar to compact mode (overflow menu).
        tester.view.physicalSize = const Size(860, 760);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byTooltip('More playback controls'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Hide video'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(probeFinder).size, const Size(160, 90));
        expect(tester.getRect(probeFinder).left, -9999.0);
        await tester.tap(find.byTooltip('More playback controls'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Show video'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(probeFinder).size, const Size(160, 90));
        expect(tester.getRect(probeFinder).left, greaterThan(0));

        await tester.pump(const Duration(milliseconds: 300));
        expect(metrics.initCount, 1);
        expect(metrics.disposeCount, 0);
        expect(metrics.layoutSizes, [const Size(160, 90)]);
        expect(metrics.layoutSizes.contains(const Size(2, 2)), isFalse);
      } finally {
        await unmountCleanly(tester);
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'desktop rapid Hide/Show toggle immediately followed by widget disposal does not throw or leak',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final metrics = _SurfaceProbeMetrics();
        await pumpShell(
          tester,
          windowSize: const Size(1280, 800),
          metrics: metrics,
        );

        await tester.tap(find.byTooltip('Hide video'));
        await tester.pump(const Duration(milliseconds: 4));
        await tester.tap(find.byTooltip('Show video'));
        await tester.pump(const Duration(milliseconds: 4));
        await tester.tap(find.byTooltip('Hide video'));
        // Dispose immediately mid-frame without letting timers settle first.
        await unmountCleanly(tester);

        expect(metrics.initCount, 1);
        expect(metrics.disposeCount, 1);
        expect(metrics.layoutSizes, [const Size(160, 90)]);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'mobile (${platform.name}) rapid Hide/Show preserves 2x2 peek at constant 160x90, blocks pointer/semantics, and preserves PiP',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          final metrics = _SurfaceProbeMetrics();
          const mobileSize = Size(400, 800);
          final harness = await pumpShell(
            tester,
            windowSize: mobileSize,
            metrics: metrics,
          );

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
            expect(rect.size, const Size(160, 90));
            final ignorePointer = tester.widget<IgnorePointer>(
              find
                  .ancestor(
                    of: probeFinder,
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            );
            final excludeSemantics = tester.widget<ExcludeSemantics>(
              find
                  .ancestor(
                    of: probeFinder,
                    matching: find.byType(ExcludeSemantics),
                  )
                  .first,
            );

            if (isCurrentlyShown) {
              expect(rect.left, mobileSize.width - 2.0);
              expect(rect.top, mobileSize.height - 2.0);
              expect(ignorePointer.ignoring, isTrue);
              expect(excludeSemantics.excluding, isTrue);
            } else {
              expect(rect, initialRect);
              expect(ignorePointer.ignoring, isFalse);
              expect(excludeSemantics.excluding, isFalse);
            }
          }

          // Hide video, then enter PiP: PiP must override hidden bounds and fill screen.
          await tester.tap(find.byTooltip('Hide video'));
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.getRect(probeFinder).left, mobileSize.width - 2.0);

          harness.playerNotifier.setPip(true);
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            tester.getRect(probeFinder),
            Rect.fromLTWH(0, 0, mobileSize.width, mobileSize.height),
          );

          // Exit PiP: returns cleanly to hidden 2x2 peek without resizing to 2x2.
          harness.playerNotifier.setPip(false);
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.getRect(probeFinder).size, const Size(160, 90));
          expect(tester.getRect(probeFinder).left, mobileSize.width - 2.0);
          expect(metrics.initCount, 1);
          expect(metrics.disposeCount, 0);
          expect(metrics.layoutSizes.contains(const Size(2, 2)), isFalse);
          expect(tester.takeException(), isNull);

          await unmountCleanly(tester);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }
}
