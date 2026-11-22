import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/core/player/player_provider.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/scaffold_with_nav.dart';

class _FrameMetrics {
  const _FrameMetrics({
    required this.width,
    required this.height,
    required this.nonBlackRatio,
    required this.meanLuma,
    required this.rgba,
  });

  final int width;
  final int height;
  final double nonBlackRatio;
  final double meanLuma;
  final Uint8List rgba;

  double diffRatio(_FrameMetrics other) {
    if (rgba.length != other.rgba.length || rgba.isEmpty) return 1.0;
    var changed = 0;
    final total = rgba.length ~/ 4;
    for (var i = 0; i < rgba.length; i += 4) {
      final dr = (rgba[i] - other.rgba[i]).abs();
      final dg = (rgba[i + 1] - other.rgba[i + 1]).abs();
      final db = (rgba[i + 2] - other.rgba[i + 2]).abs();
      if (dr + dg + db > 12) changed++;
    }
    return changed / total;
  }
}

class _LiveCefPlaybackController implements PlaybackController {
  _LiveCefPlaybackController(this._renderer, this._status);

  final Widget _renderer;
  PlaybackStatus _status;
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _eventController = StreamController<PlaybackEvent>.broadcast();

  void emitStatus(PlaybackStatus next) {
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<PlaybackEvent> get eventStream => _eventController.stream;

  @override
  PlaybackStatus get currentStatus => _status;

  @override
  dynamic get renderer => _renderer;

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

class _LivePlayerNotifier extends PlayerNotifier {
  @override
  PlayerState build() => const PlayerState(
    videoId: 'M7lc1UVf-VE',
    isPlaying: true,
    duration: Duration(minutes: 5),
    position: Duration(seconds: 12),
    playbackQueue: PlaybackQueue(
      tracks: [
        Track(
          spotifyId: 'cef-track-1',
          name: 'CEF Native Mini-Video Validation',
          artistId: 'cef-artist',
          artistName: 'PPPlayer QA',
          youtubeVideoId: 'M7lc1UVf-VE',
        ),
      ],
    ),
  );

  @override
  PlaybackTrack? get currentPlaybackTrack => null;
}

Future<_FrameMetrics> _captureFrame(GlobalKey boundaryKey) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = Uint8List.fromList(
      byteData!.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
    final pixelCount = rgba.length ~/ 4;
    var nonBlack = 0;
    var lumaSum = 0.0;
    for (var i = 0; i < rgba.length; i += 4) {
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final luma = 0.299 * r + 0.587 * g + 0.114 * b;
      lumaSum += luma;
      if (r > 12 || g > 12 || b > 12) nonBlack++;
    }
    return _FrameMetrics(
      width: image.width,
      height: image.height,
      nonBlackRatio: pixelCount == 0 ? 0.0 : nonBlack / pixelCount,
      meanLuma: pixelCount == 0 ? 0.0 : lumaSum / pixelCount,
      rgba: rgba,
    );
  } finally {
    image.dispose();
  }
}

Future<void> _waitForLiveAdvancingFrames(
  WidgetTester tester,
  GlobalKey boundaryKey, {
  required String label,
  Duration timeout = const Duration(seconds: 20),
  double minNonBlack = 0.25,
  double minDiff = 0.005,
}) async {
  final deadline = DateTime.now().add(timeout);
  _FrameMetrics? first;
  _FrameMetrics? second;
  var bestDiff = 0.0;
  var bestNonBlack = 0.0;
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 120));
    final current = await _captureFrame(boundaryKey);
    if (current.nonBlackRatio > bestNonBlack) {
      bestNonBlack = current.nonBlackRatio;
    }
    if (current.nonBlackRatio >= minNonBlack) {
      if (first == null) {
        first = current;
        await Future<void>.delayed(const Duration(milliseconds: 350));
      } else {
        final diff = first.diffRatio(current);
        if (diff > bestDiff) bestDiff = diff;
        if (diff >= minDiff) {
          second = current;
          debugPrint(
            '[CEF_PHASE6] $label PASS: size=${current.width}x${current.height} '
            'nonBlack=${(current.nonBlackRatio * 100).toStringAsFixed(1)}% '
            'meanLuma=${current.meanLuma.toStringAsFixed(1)} '
            'frameDiff=${(diff * 100).toStringAsFixed(2)}%',
          );
          return;
        }
        first = current;
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
  fail(
    '[CEF_PHASE6] $label FAILED: surface appears black or frozen '
    '(bestNonBlack=${(bestNonBlack * 100).toStringAsFixed(1)}%, '
    'bestDiff=${(bestDiff * 100).toStringAsFixed(2)}%, '
    'first=${first?.nonBlackRatio}, second=${second?.nonBlackRatio})',
  );
}

Future<void> _dumpProcessTelemetry(String tag) async {
  if (!Platform.isMacOS) return;
  final result = await Process.run('ps', ['-axo', 'pid,ppid,rss,%cpu,comm']);
  if (result.exitCode != 0) return;
  final lines = (result.stdout as String).split('\n').where((l) {
    return l.contains('PPPlayer.app');
  }).toList();
  var totalRssKb = 0;
  for (final line in lines) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      totalRssKb += int.tryParse(parts[2]) ?? 0;
    }
  }
  debugPrint(
    '[CEF_PHASE6] TELEMETRY($tag): procs=${lines.length} '
    'totalRSS=${(totalRssKb / 1024).toStringAsFixed(1)}MB',
  );
  for (final line in lines) {
    debugPrint('[CEF_PHASE6]   $line');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets(
    'macOS real CEF + Metal/IOSurface mini-video survives 1x/10x/50x/100x rapid Hide/Show, pause/resume, route transitions, and live YouTube playback',
    (tester) async {
      if (!Platform.isMacOS) return;

      final hiveDir = Directory.systemTemp.createTempSync(
        'ppplayer-phase6-hive-',
      );
      final cacheDir = Directory.systemTemp.createTempSync(
        'ppplayer-phase6-cef-',
      );
      Hive.init(hiveDir.path);

      // Local deterministic HTTP server serving real MP4 video + live animated canvas fallback.
      final videoFile = File('assets/test_fixtures/test_video.mp4');
      final videoBytes = videoFile.existsSync()
          ? videoFile.readAsBytesSync()
          : Uint8List(0);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        if (req.uri.path == '/test_video.mp4' && videoBytes.isNotEmpty) {
          req.response.headers.contentType = ContentType('video', 'mp4');
          req.response.headers.set('Accept-Ranges', 'bytes');
          req.response.add(videoBytes);
          await req.response.close();
          return;
        }
        final variant = req.uri.queryParameters['v'] ?? '1';
        req.response.headers.contentType = ContentType.html;
        req.response.write('''
<!doctype html>
<html>
<head>
<style>
  html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #102030; }
  video { position: fixed; inset: 0; width: 100%; height: 100%; object-fit: cover; }
  canvas { position: fixed; inset: 0; width: 100%; height: 100%; opacity: 0.85; }
</style>
</head>
<body>
  <video id="v" src="/test_video.mp4" autoplay muted loop playsinline></video>
  <canvas id="c" width="320" height="180"></canvas>
  <script>
    const c = document.getElementById('c');
    const ctx = c.getContext('2d');
    let frame = 0;
    const hueOffset = ${variant == '2' ? 140 : 0};
    function tick() {
      frame++;
      const hue = (frame * 5 + hueOffset) % 360;
      ctx.fillStyle = 'hsl(' + hue + ', 85%, 50%)';
      ctx.fillRect(0, 0, c.width, c.height);
      const x = (frame * 9) % c.width;
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(x, 20, 60, 140);
      ctx.fillStyle = '#111111';
      ctx.fillRect((c.width - x) % c.width, 50, 40, 80);
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  </script>
</body>
</html>
''');
        await req.response.close();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(
        await ChromiumWebViewController.initialize(cachePath: cacheDir.path),
        isTrue,
      );

      final webController = ChromiumWebViewController();
      final surfaceKey = GlobalKey();
      const playingStatus = PlaybackStatus(
        state: PlaybackState.playing,
        isIFrameMode: true,
        hasVideo: true,
        activeVideoId: 'M7lc1UVf-VE',
      );
      final playbackController = _LiveCefPlaybackController(
        RepaintBoundary(
          key: surfaceKey,
          child: ChromiumWebView(
            controller: webController,
            disposeController: false,
          ),
        ),
        playingStatus,
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
                path: '/player',
                builder: (context, state) => const SizedBox.expand(),
              ),
            ],
          ),
        ],
      );

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(playbackController),
              playbackStatusProvider.overrideWith(
                (_) => playbackController.statusStream,
              ),
              playerProvider.overrideWith(_LivePlayerNotifier.new),
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
        playbackController.emitStatus(playingStatus);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await webController.loadRequest('http://127.0.0.1:${server.port}/?v=1');

        await _waitForLiveAdvancingFrames(
          tester,
          surfaceKey,
          label: '1_CLEAN_LAUNCH',
        );
        await _dumpProcessTelemetry('after_clean_launch');

        Future<void> runToggleWave(int toggleCount, String label) async {
          assert(toggleCount.isEven, 'Use even toggleCount to end visible');
          var shown = true;
          for (var i = 0; i < toggleCount; i++) {
            final tooltip = shown ? 'Hide video' : 'Show video';
            final btn = find.byTooltip(tooltip);
            expect(btn, findsOneWidget, reason: '$label toggle #$i ($tooltip)');
            await tester.tap(btn);
            await tester.pump(const Duration(milliseconds: 16));
            shown = !shown;
          }
          await tester.pump(const Duration(milliseconds: 200));
          await _waitForLiveAdvancingFrames(tester, surfaceKey, label: label);
        }

        // 1x Hide -> Show (2 clicks)
        await runToggleWave(2, '2_SINGLE_HIDE_SHOW');
        // 10x rapid Hide/Show cycles (20 clicks)
        await runToggleWave(20, '3_10X_RAPID_TOGGLES');
        // 50x rapid Hide/Show cycles (50 clicks = 25 cycles)
        await runToggleWave(50, '4_50X_RAPID_TOGGLES');
        // 100x rapid Hide/Show (100 clicks = 50 cycles)
        await runToggleWave(100, '5_100X_RAPID_TOGGLES');
        await _dumpProcessTelemetry('after_100x_toggles');

        // Pause rendering (setRenderingActive(false)) -> 10 toggles -> resume rendering.
        await webController.setRenderingActive(false);
        await tester.pump(const Duration(milliseconds: 200));
        for (var i = 0; i < 10; i++) {
          final btn = find.byTooltip(i.isEven ? 'Hide video' : 'Show video');
          await tester.tap(btn);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await webController.setRenderingActive(true);
        await tester.pump(const Duration(milliseconds: 200));
        await _waitForLiveAdvancingFrames(
          tester,
          surfaceKey,
          label: '6_PAUSE_TOGGLE_RESUME',
        );

        // Track switch / navigation reload while toggling rapidly.
        unawaited(
          webController.loadRequest('http://127.0.0.1:${server.port}/?v=2'),
        );
        await runToggleWave(10, '7_TRACK_SWITCH_DURING_TOGGLE');

        // Route transitions: /home -> /discover -> /player (full) -> /home (mini) + rapid toggles.
        router.go('/discover');
        await tester.pump(const Duration(milliseconds: 200));
        await runToggleWave(6, '8_DISCOVER_ROUTE_TOGGLES');

        router.go('/player');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await _waitForLiveAdvancingFrames(
          tester,
          surfaceKey,
          label: '9_FULL_PLAYER_TRANSITION',
        );

        router.go('/home');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await runToggleWave(10, '10_BACK_TO_MINI_TOGGLES');

        // Real YouTube network playback test inside ChromiumYoutubePlayerController.
        final ytKey = GlobalKey();
        final ytController = ChromiumYoutubePlayerController(
          documentUrl: 'https://ppplayer.com/chromium/player.html',
        );
        final ytPlaying = Completer<void>();
        final ytSub = ytController.events.listen((event) {
          if (event['StateChange'] == 1 && !ytPlaying.isCompleted) {
            ytPlaying.complete();
          }
        });
        try {
          final ytPlaybackController = _LiveCefPlaybackController(
            RepaintBoundary(
              key: ytKey,
              child: ChromiumWebView(
                controller: ytController.webViewController,
                disposeController: false,
              ),
            ),
            playingStatus,
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appDatabaseProvider.overrideWithValue(db),
                playbackControllerProvider.overrideWithValue(
                  ytPlaybackController,
                ),
                playbackStatusProvider.overrideWith(
                  (_) => ytPlaybackController.statusStream,
                ),
                playerProvider.overrideWith(_LivePlayerNotifier.new),
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
          ytPlaybackController.emitStatus(playingStatus);
          await tester.pump(const Duration(milliseconds: 300));
          await ytController.loadVideoById(
            videoId: 'M7lc1UVf-VE',
            startSeconds: 5,
          );
          // Pump while waiting up to 20s for real YouTube playback state=1.
          final ytDeadline = DateTime.now().add(const Duration(seconds: 20));
          while (!ytPlaying.isCompleted &&
              DateTime.now().isBefore(ytDeadline)) {
            await tester.pump(const Duration(milliseconds: 150));
          }
          debugPrint(
            '[CEF_PHASE6] YOUTUBE_STATE_PLAYING=${ytPlaying.isCompleted}',
          );
          await _waitForLiveAdvancingFrames(
            tester,
            ytKey,
            label: '11_YOUTUBE_LIVE_BEFORE_TOGGLE',
            minNonBlack: 0.15,
            minDiff: 0.002,
          );
          for (var i = 0; i < 20; i++) {
            final btn = find.byTooltip(i.isEven ? 'Hide video' : 'Show video');
            expect(btn, findsOneWidget);
            await tester.tap(btn);
            await tester.pump(const Duration(milliseconds: 16));
          }
          await tester.pump(const Duration(milliseconds: 300));
          await _waitForLiveAdvancingFrames(
            tester,
            ytKey,
            label: '12_YOUTUBE_LIVE_AFTER_20X_TOGGLES',
            minNonBlack: 0.15,
            minDiff: 0.002,
          );
          await ytPlaybackController.dispose();
        } finally {
          await ytSub.cancel();
          await ytController.dispose();
        }

        await _dumpProcessTelemetry('before_cleanup');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        await playbackController.dispose();
        await webController.dispose();
        router.dispose();
        await db.close();
        await server.close(force: true);
        await Hive.close();
        if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
        if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);
      }
    },
  );
}
