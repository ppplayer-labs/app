import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/playback/chromium_playback_engine.dart';

/// Automated Windows memory & lifecycle benchmark harness.
///
/// Build and run in Release mode via:
///   flutter build windows --release -t tool/windows_memory_benchmark.dart
///   powershell -ExecutionPolicy Bypass -File scripts/benchmark_windows_memory.ps1 -Mode scenarios
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  int stressCycles = 10;
  for (final arg in args) {
    if (arg.startsWith('--bench-stress-cycles=')) {
      stressCycles = int.tryParse(arg.split('=').last) ?? 10;
    }
  }

  runApp(_BenchmarkApp(stressCycles: stressCycles));
}

class _BenchmarkApp extends StatefulWidget {
  const _BenchmarkApp({required this.stressCycles});
  final int stressCycles;

  @override
  State<_BenchmarkApp> createState() => _BenchmarkAppState();
}

class _BenchmarkAppState extends State<_BenchmarkApp> {
  late final MediaKitPlaybackEngine _mediaKit;
  late final ChromiumPlaybackEngine _engine;
  StreamSubscription<PlaybackStatus>? _statusSub;
  PlaybackStatus _status = const PlaybackStatus();
  Size _viewportSize = const Size(1280, 720);
  String _stage = 'starting';
  bool _showPlayer = false;

  final List<double> _frameBuildMs = [];
  final List<double> _frameRasterMs = [];
  int _droppedFrames = 0;

  @override
  void initState() {
    super.initState();
    _mediaKit = MediaKitPlaybackEngine();
    _engine = ChromiumPlaybackEngine(
      fallback: _mediaKit,
      initializeCef: () async {
        final dir = await getApplicationSupportDirectory();
        final ok = await ChromiumWebViewController.initialize(
          cachePath: dir.path,
          keychainBehavior: ChromiumKeychainBehavior.mock,
        );
        if (!ok) throw StateError('CEF initialization failed');
      },
      createPlayer: () => ChromiumYoutubePlayerController(
        documentUrl: 'https://ppplayer.com/chromium/player.html',
        profileName: 'ppplayer_youtube_session',
      ),
    );
    _statusSub = _engine.statusStream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSuite());
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final buildMs = t.buildDuration.inMicroseconds / 1000.0;
      final rasterMs = t.rasterDuration.inMicroseconds / 1000.0;
      _frameBuildMs.add(buildMs);
      _frameRasterMs.add(rasterMs);
      if (buildMs + rasterMs > 16.67) _droppedFrames++;
    }
  }

  String _consumeFrameStats() {
    if (_frameBuildMs.isEmpty) return 'frames=0 dropped=0';
    final avgBuild =
        _frameBuildMs.reduce((a, b) => a + b) / _frameBuildMs.length;
    final avgRaster =
        _frameRasterMs.reduce((a, b) => a + b) / _frameRasterMs.length;
    final count = _frameBuildMs.length;
    final dropped = _droppedFrames;
    _frameBuildMs.clear();
    _frameRasterMs.clear();
    _droppedFrames = 0;
    return 'frames=$count avgBuildMs=${avgBuild.toStringAsFixed(2)} avgRasterMs=${avgRaster.toStringAsFixed(2)} dropped=$dropped';
  }

  static const _cefChannel = MethodChannel('flutter_chromium_webview');

  Future<Map<String, dynamic>> _cefDiag() async {
    try {
      final res = await _cefChannel.invokeMapMethod<String, dynamic>(
        'getDiagnostics',
      );
      return res ?? const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _signalAndWait(String stage) async {
    final benchDir = Directory(p.join(Directory.systemTemp.path, 'ppplayer_bench'));
    final ackFile = File(p.join(benchDir.path, 'ack_$stage.txt'));
    if (ackFile.existsSync()) ackFile.deleteSync();

    final diag = await _cefDiag();
    final imgCache = PaintingBinding.instance.imageCache;
    final frameStats = _consumeFrameStats();
    final rssMb = (ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1);
    stdout.writeln(
      '[BENCH_READY] $stage rssMb=$rssMb browsers=${diag['browsers'] ?? 0} '
      'textures=${diag['textures'] ?? 0} imgCacheMB=${(imgCache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(2)} '
      'liveImgs=${imgCache.liveImageCount} $frameStats',
    );
    await stdout.flush();

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      if (ackFile.existsSync()) {
        try {
          ackFile.deleteSync();
        } catch (_) {}
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  String _fixturePath(String name) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return p.join(
      exeDir,
      'data',
      'flutter_assets',
      'assets',
      'test_fixtures',
      name,
    );
  }

  Future<void> _runSuite() async {
    try {
      setState(() => _stage = 'startup');
      await _signalAndWait('startup');

      // 2. Idle (no media loaded)
      setState(() => _stage = 'idle');
      await Future.delayed(const Duration(seconds: 2));
      await _signalAndWait('idle');

      // 3. Local audio playback (MediaKit)
      setState(() {
        _stage = 'local_audio';
        _showPlayer = true;
      });
      await _engine.play(
        PlaybackTrack(
          id: 'bench_audio',
          title: 'Benchmark Audio',
          sourceType: PlaybackSourceType.local,
          localMediaUri: _fixturePath('test.wav'),
          isVideo: false,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _signalAndWait('local_audio');

      // 4. Local video playback (MediaKit)
      setState(() => _stage = 'local_video');
      await _engine.play(
        PlaybackTrack(
          id: 'bench_video',
          title: 'Benchmark Video',
          sourceType: PlaybackSourceType.local,
          localMediaUri: _fixturePath('test_video.mp4'),
          isVideo: true,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _signalAndWait('local_video');

      // 5. Chromium-based online playback (YouTube IFrame demo video)
      setState(() {
        _stage = 'chromium_playback';
        _viewportSize = const Size(1280, 720);
      });
      try {
        await _engine.play(
          const PlaybackTrack(
            id: 'M7lc1UVf-VE',
            title: 'YouTube Demo',
            sourceType: PlaybackSourceType.online,
            youtubeSourceType: YoutubeSourceType.video,
          ),
        );
      } catch (e) {
        stdout.writeln('[BENCH_WARN] YouTube play error: $e');
      }
      await Future.delayed(const Duration(seconds: 5));
      await _signalAndWait('chromium_playback');

      // 6. 1080p viewport streaming video
      setState(() {
        _stage = 'chromium_1080p';
        _viewportSize = const Size(1920, 1080);
      });
      await Future.delayed(const Duration(seconds: 4));
      await _signalAndWait('chromium_1080p');

      // 7. Paused Chromium playback
      setState(() => _stage = 'chromium_paused');
      await _engine.pause();
      await Future.delayed(const Duration(seconds: 3));
      await _signalAndWait('chromium_paused');

      // 8. Minimized host window (PowerShell minimizes/restores)
      setState(() => _stage = 'minimized');
      await _signalAndWait('minimized');

      // 9. Player closed / stopped with app still running (browser disposed)
      setState(() {
        _stage = 'after_browser_disposal';
        _showPlayer = false;
        _viewportSize = const Size(1280, 720);
      });
      await _engine.stop();
      await Future.delayed(const Duration(seconds: 3));
      await _signalAndWait('after_browser_disposal');

      // 10. Repeated browser create/dispose + resize + audio/video switch stress cycles
      setState(() => _stage = 'stress_cycles');
      for (int i = 1; i <= widget.stressCycles; i++) {
        final ctrl = ChromiumWebViewController(
          initialUrl: 'about:blank',
          mediaPlaybackRequiresUserGesture: false,
        );
        await ctrl.createBrowser();
        final w = (i % 2 == 0) ? 1920.0 : 800.0;
        final h = (i % 2 == 0) ? 1080.0 : 450.0;
        await ctrl.updateBrowserSize(w, h, 1.0);
        await ctrl.loadHtmlString(
          '<!doctype html><html><body style="margin:0;background:#111;color:#fff">Cycle $i</body></html>',
          baseUrl: 'https://ppplayer.com/bench/$i',
        );
        await ctrl.setRenderingActive(false);
        await ctrl.setRenderingActive(true);
        await Future.delayed(const Duration(milliseconds: 60));
        await ctrl.dispose();
        if (i == 1 || i == 25 || i == 50 || i == 75 || i == widget.stressCycles) {
          final rssMb = (ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1);
          final d = await _cefDiag();
          stdout.writeln(
            '[BENCH_STRESS_CHECKPOINT] cycle=$i/${widget.stressCycles} rssMb=$rssMb browsers=${d['browsers'] ?? 0} textures=${d['textures'] ?? 0}',
          );
          await stdout.flush();
        }
      }
      // Audio -> video -> audio -> stop switching cycle
      for (int s = 0; s < 3; s++) {
        await _engine.play(
          PlaybackTrack(
            id: 'switch_audio_$s',
            title: 'Audio $s',
            sourceType: PlaybackSourceType.local,
            localMediaUri: _fixturePath('test.wav'),
            isVideo: false,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 250));
        await _engine.play(
          PlaybackTrack(
            id: 'switch_video_$s',
            title: 'Video $s',
            sourceType: PlaybackSourceType.local,
            localMediaUri: _fixturePath('test_video.mp4'),
            isVideo: true,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 250));
      }
      await _engine.stop();
      await Future.delayed(const Duration(seconds: 2));
      await _signalAndWait('stress_cycles');
    } catch (e, st) {
      stdout.writeln('[BENCH_ERROR] $e\n$st');
    } finally {
      stdout.writeln('[BENCH_DONE]');
      await stdout.flush();
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _statusSub?.cancel();
    unawaited(_engine.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            if (_showPlayer)
              Center(
                child: SizedBox(
                  width: _viewportSize.width,
                  height: _viewportSize.height,
                  child: PlaybackView(
                    controller: _engine,
                    status: _status,
                  ),
                ),
              ),
            Positioned(
              left: 12,
              top: 12,
              child: Text(
                'Benchmark stage: $_stage',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
