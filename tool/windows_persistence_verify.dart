import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';

const _diagChannel = MethodChannel('flutter_chromium_webview');

/// Real-CEF Windows verification harness for:
/// - Task 1 & 2: Named persistent `profileName` cookies & localStorage across
///   browser disposal AND full OS process restarts, plus incognito isolation
///   when `profileName == null`.
/// - Task 4: Rendering throttling (`setRenderingActive(false/true)`) during
///   YouTube playback pause/resume without breaking audio or resumed rendering.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _VerifyApp());
}

class _VerifyApp extends StatefulWidget {
  const _VerifyApp();

  @override
  State<_VerifyApp> createState() => _VerifyAppState();
}

class _VerifyAppState extends State<_VerifyApp> {
  ChromiumWebViewController? _activeWebView;
  String _status = 'starting';

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _setWebView(ChromiumWebViewController? controller) async {
    if (!mounted) return;
    setState(() => _activeWebView = controller);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _waitForLoad(
    ChromiumWebViewController controller, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final done = Completer<void>();
    var sawLoading = false;
    controller.onLoadingStateChanged = (isLoading, _, _) {
      if (isLoading) {
        sawLoading = true;
      } else if (sawLoading && !done.isCompleted) {
        done.complete();
      }
    };
    await done.future.timeout(timeout, onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<Map<String, Object?>> _queryJs(
    ChromiumWebViewController controller,
    String expr,
  ) async {
    final completer = Completer<Map<String, Object?>>();
    final sub = controller.onMessage.listen((msg) {
      if (msg.channel == 'verify' && !completer.isCompleted) {
        completer.complete(
          (jsonDecode(msg.message) as Map).cast<String, Object?>(),
        );
      }
    });
    try {
      await controller.executeJavaScript(
        "window.chromiumPostMessage('verify', JSON.stringify($expr));",
      );
      return await completer.future.timeout(const Duration(seconds: 10));
    } finally {
      await sub.cancel();
    }
  }

  ChromiumWebViewController _makeController({
    required int port,
    required String? profileName,
    required bool requiresGesture,
  }) {
    return ChromiumWebViewController(
      initialUrl: 'about:blank',
      profileName: profileName,
      mediaPlaybackRequiresUserGesture: requiresGesture,
      javaScriptChannels: [
        JavaScriptChannel(
          name: 'verify',
          allowedOrigins: {'http://127.0.0.1:$port', 'https://ppplayer.com'},
        ),
      ],
    );
  }

  Future<void> _run() async {
    final env = Platform.environment;
    final phase = env['PP_VERIFY_PHASE'] ?? 'write';
    final cachePath = env['PP_VERIFY_CACHE_PATH']!;
    final reportPath = env['PP_VERIFY_REPORT']!;
    final port = int.parse(env['PP_VERIFY_PORT'] ?? '48921');
    final report = <String, Object?>{
      'phase': phase,
      'cachePath': cachePath,
      'port': port,
      'ok': false,
    };

    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      unawaited(() async {
        await for (final req in server!) {
          if (req.uri.path == '/set') {
            req.response.headers.set(
              'Set-Cookie',
              'pp_srv_cookie=srv_persisted_42; Max-Age=3600; Path=/',
            );
          }
          req.response.headers.contentType = ContentType.html;
          req.response.write(
            '<!doctype html><html><body><h1 id="h">ok:${req.uri.path}</h1></body></html>',
          );
          await req.response.close();
        }
      }());

      final initOk = await ChromiumWebViewController.initialize(
        cachePath: cachePath,
        keychainBehavior: ChromiumKeychainBehavior.mock,
      );
      report['cefInitOk'] = initOk;
      if (!initOk) throw StateError('CEF initialize returned false');

      if (phase == 'write') {
        await _runWritePhase(port, report);
      } else {
        await _runReadPhase(port, cachePath, report);
      }

      final diag = await _diagChannel.invokeMethod<Map<Object?, Object?>>(
        'getDiagnostics',
      );
      report['finalDiagnostics'] = diag?.map((k, v) => MapEntry('$k', v));
      report['ok'] = true;
    } catch (e, st) {
      report['error'] = '$e\n$st';
    } finally {
      await _setWebView(null);
      await server?.close(force: true);
      final file = File(reportPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );
      if (mounted) {
        setState(() => _status = report['ok'] == true ? 'DONE_OK' : 'DONE_ERR');
      }
    }
  }

  Future<void> _runWritePhase(int port, Map<String, Object?> report) async {
    // 1. Named persistent profile + autoplay allowed (PPPlayer configuration)
    final c1 = _makeController(
      port: port,
      profileName: 'ppplayer_youtube_session',
      requiresGesture: false,
    );
    await _setWebView(c1);
    await c1.createBrowser();
    final load1 = _waitForLoad(c1);
    await c1.loadRequest('http://127.0.0.1:$port/set');
    await load1;
    await c1.executeJavaScript(
      "document.cookie = 'pp_js_cookie=js_persisted_99; max-age=3600; path=/';"
      "localStorage.setItem('pp_ls_key', 'ls_persisted_ok');",
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    report['browser1Http'] = await _queryJs(
      c1,
      "{cookie: document.cookie, ls: localStorage.getItem('pp_ls_key')}",
    );

    // Also persist storage on PPPlayer's HTTPS origin
    final loadHttps = _waitForLoad(c1);
    await c1.loadHtmlString(
      '<!doctype html><html><body>https-origin</body></html>',
      baseUrl: 'https://ppplayer.com/chromium/verify.html',
    );
    await loadHttps;
    await c1.executeJavaScript(
      "document.cookie = 'pp_https_cookie=https_ok_77; max-age=3600; path=/';"
      "localStorage.setItem('yt_session_marker', 'yt_ok_1');",
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    report['browser1Https'] = await _queryJs(
      c1,
      "{cookie: document.cookie, ls: localStorage.getItem('yt_session_marker')}",
    );

    await _setWebView(null);
    await c1.dispose();

    // 2. Second browser with SAME profileName after first browser disposal
    final c2 = _makeController(
      port: port,
      profileName: 'ppplayer_youtube_session',
      requiresGesture: false,
    );
    await _setWebView(c2);
    await c2.createBrowser();
    final load2 = _waitForLoad(c2);
    await c2.loadRequest('http://127.0.0.1:$port/read');
    await load2;
    report['browser2AfterDispose'] = await _queryJs(
      c2,
      "{cookie: document.cookie, ls: localStorage.getItem('pp_ls_key')}",
    );
    await _setWebView(null);
    await c2.dispose();

    // 3. Incognito autoplay browser (profileName: null) must NOT see named profile storage
    final c3 = _makeController(
      port: port,
      profileName: null,
      requiresGesture: false,
    );
    await _setWebView(c3);
    await c3.createBrowser();
    final load3 = _waitForLoad(c3);
    await c3.loadRequest('http://127.0.0.1:$port/read');
    await load3;
    report['browser3IncognitoIsolation'] = await _queryJs(
      c3,
      "{cookie: document.cookie, ls: localStorage.getItem('pp_ls_key')}",
    );
    await _setWebView(null);
    await c3.dispose();

    // 4. Real YouTube playback + pause/resume rendering throttling verification
    final yt = ChromiumYoutubePlayerController(
      documentUrl: 'https://ppplayer.com/chromium/player.html',
      profileName: 'ppplayer_youtube_session',
    );
    final states = <int>[];
    final playingCompleter = Completer<void>();
    final pausedCompleter = Completer<void>();
    final resumedCompleter = Completer<void>();
    var sawPause = false;
    final sub = yt.events.listen((event) {
      final s = event['StateChange'];
      if (s is int) {
        states.add(s);
        if (s == 1 && !playingCompleter.isCompleted) {
          playingCompleter.complete();
        } else if (s == 2 &&
            playingCompleter.isCompleted &&
            !pausedCompleter.isCompleted) {
          sawPause = true;
          pausedCompleter.complete();
        } else if (s == 1 && sawPause && !resumedCompleter.isCompleted) {
          resumedCompleter.complete();
        }
      }
    });
    await _setWebView(yt.webViewController);
    final sw = Stopwatch()..start();
    await yt.initialize();
    await yt.setVolume(0);
    await yt.loadVideoById(videoId: 'M7lc1UVf-VE');
    await playingCompleter.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () {},
    );
    final firstPlayMs = sw.elapsedMilliseconds;
    await Future<void>.delayed(const Duration(seconds: 2));
    final tBeforePause = await yt.currentTime;

    // Pause + throttle rendering to 1 fps
    await yt.pauseVideo();
    await yt.webViewController.setRenderingActive(false);
    await pausedCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    await Future<void>.delayed(const Duration(seconds: 2));

    // Resume + restore 60 fps rendering + Invalidate
    await yt.webViewController.setRenderingActive(true);
    await yt.playVideo();
    await resumedCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
    await Future<void>.delayed(const Duration(seconds: 3));
    final tAfterResume = await yt.currentTime;

    report['youtubePlayback'] = {
      'firstPlayMs': firstPlayMs,
      'states': states,
      'playingReached': playingCompleter.isCompleted,
      'pausedReached': pausedCompleter.isCompleted,
      'resumedReached': resumedCompleter.isCompleted,
      'timeBeforePause': tBeforePause,
      'timeAfterResume': tAfterResume,
      'advancedAfterResume': tAfterResume > tBeforePause + 0.5,
    };

    await sub.cancel();
    await _setWebView(null);
    await yt.dispose();
  }

  Future<void> _runReadPhase(
    int port,
    String cachePath,
    Map<String, Object?> report,
  ) async {
    final profileDir = Directory(
      '$cachePath\\profile_ppplayer_youtube_session',
    );
    report['profileDirExists'] = profileDir.existsSync();
    if (profileDir.existsSync()) {
      report['profileEntries'] =
          profileDir
              .listSync()
              .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
              .toList()
            ..sort();
    }

    final c1 = _makeController(
      port: port,
      profileName: 'ppplayer_youtube_session',
      requiresGesture: false,
    );
    await _setWebView(c1);
    await c1.createBrowser();
    final load1 = _waitForLoad(c1);
    await c1.loadRequest('http://127.0.0.1:$port/read');
    await load1;
    report['afterRestartHttp'] = await _queryJs(
      c1,
      "{cookie: document.cookie, ls: localStorage.getItem('pp_ls_key')}",
    );

    final load2 = _waitForLoad(c1);
    await c1.loadHtmlString(
      '<!doctype html><html><body>https-read</body></html>',
      baseUrl: 'https://ppplayer.com/chromium/verify.html',
    );
    await load2;
    report['afterRestartHttps'] = await _queryJs(
      c1,
      "{cookie: document.cookie, ls: localStorage.getItem('yt_session_marker')}",
    );

    await _setWebView(null);
    await c1.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text(_status),
            Expanded(
              child: _activeWebView == null
                  ? const SizedBox.shrink()
                  : ChromiumWebView(
                      controller: _activeWebView!,
                      disposeController: false,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
