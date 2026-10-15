import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  testWidgets('real macOS JavaScript IPC, document lifetime and process loss', (
    tester,
  ) async {
    if (!Platform.isMacOS) return;
    const channel = MethodChannel('flutter_chromium_webview');
    final events = <Map<String, dynamic>>[];
    final messages = <String, List<JavaScriptMessage>>{
      'first': [],
      'second': [],
    };
    final allowed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final denied = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${allowed.port}';
    void serve(HttpServer server) {
      server.listen((request) async {
        if (request.method == 'POST') {
          events.add(
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>,
          );
          request.response.statusCode = 204;
        } else {
          request.response.headers.contentType = ContentType.html;
          if (request.uri.path == '/sandbox')
            request.response.headers.set(
              'Content-Security-Policy',
              'sandbox allow-scripts',
            );
          request.response.write(
            '''<!doctype html><meta charset="utf-8"><title>JS IPC fixture</title><script>
            if(typeof chromiumPostMessage==='function') {
              chromiumPostMessage('unknown','must not arrive');
              chromiumPostMessage('player','ready:'+location.pathname);
            }
            fetch('/ready',{method:'POST',body:JSON.stringify({path:location.pathname,bridge:typeof chromiumPostMessage})});
          </script>''',
          );
        }
        await request.response.close();
      });
    }

    serve(allowed);
    serve(denied);
    ChromiumWebViewController controller(String path) =>
        ChromiumWebViewController(
          initialUrl: '$origin/$path',
          javaScriptChannels: [
            JavaScriptChannel(name: 'player', allowedOrigins: {origin}),
          ],
        );
    final first = controller('first');
    final second = controller('second');
    var streamClosed = false;
    final subscriptions = [
      first.onMessage.listen(
        messages['first']!.add,
        onDone: () => streamClosed = true,
      ),
      second.onMessage.listen(messages['second']!.add),
    ];
    Future<void> waitFor(bool Function() check, String reason) async {
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (!check() && DateTime.now().isBefore(deadline))
        await tester.pump(const Duration(milliseconds: 25));
      expect(check(), isTrue, reason: '$reason; events=$events');
    }

    Future<T> finish<T>(Future<T> future) async {
      T? value;
      Object? failure;
      var done = false;
      future.then(
        (v) {
          value = v;
          done = true;
        },
        onError: (Object error) {
          failure = error;
          done = true;
        },
      );
      await waitFor(() => done, 'asynchronous native operation completes');
      if (failure != null) throw failure!;
      return value as T;
    }

    Future<JavaScriptException> failureOf(Future<Object?> future) async {
      try {
        await future;
      } on JavaScriptException catch (error) {
        return error;
      }
      throw TestFailure('Expected a structured JavaScript failure');
    }

    Future<void> expectError(Future<Object?> future, String code) async {
      expect((await finish(failureOf(future))).code, code);
    }

    Future<void> pending(int count) async {
      final state = await finish(
        channel.invokeMapMethod<String, dynamic>('getJavaScriptDiagnostics', {
          'browserId': first.browserId,
        }),
      );
      expect(state?['pendingJavaScript'], count);
    }

    Future<List<int>> children(int parent, String marker) async {
      final listed = await finish(
        Process.run('/usr/bin/pgrep', ['-P', '$parent']),
      );
      final result = <int>[];
      for (final child in (listed.stdout as String).trim().split('\n')) {
        final childPid = int.tryParse(child);
        if (childPid == null) continue;
        final command = await finish(
          Process.run('/bin/ps', ['-p', child, '-o', 'args=']),
        );
        if ((command.stdout as String).contains(marker)) result.add(childPid);
      }
      return result;
    }

    Future<void> ready(String path) => waitFor(
      () => messages['first']!.any((m) => m.message == 'ready:$path'),
      'new main context ready: $path',
    );
    try {
      expect(
        await finish(
          ChromiumWebViewController.initialize(
            cachePath: Directory.systemTemp
                .createTempSync('cef-js-integration-')
                .path,
          ),
        ),
        isTrue,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              SizedBox(
                width: 300,
                height: 250,
                child: ChromiumWebView(
                  controller: first,
                  disposeController: false,
                ),
              ),
              SizedBox(
                width: 300,
                height: 250,
                child: ChromiumWebView(
                  controller: second,
                  disposeController: false,
                ),
              ),
            ],
          ),
        ),
      );
      await ready('/first');
      await waitFor(
        () => messages['second']!.any((m) => m.message == 'ready:/second'),
        'second browser ready',
      );
      expect(first.browserId, isNot(second.browserId));
      expect(messages['first']!.single.channel, 'player');
      expect(messages['first']!.single.origin, origin);
      for (final entry in <String, Object?>{
        '42': 42,
        'true': true,
        'null': null,
        'undefined': null,
        '"hello 🌍"': 'hello 🌍',
        '"a\\u0000b"': 'a\u0000b',
        '[1,"two",null]': [1, 'two', null],
        '({nested:{a:1},flag:false})': {
          'nested': {'a': 1},
          'flag': false,
        },
        'document.title': 'JS IPC fixture',
      }.entries) {
        expect(await finish(first.evaluateJavaScript(entry.key)), entry.value);
      }
      await finish(first.executeJavaScript('window.executed=7'));
      expect(await finish(first.evaluateJavaScript('window.executed')), 7);
      final exception = await finish(
        failureOf(
          first.evaluateJavaScript('throw new TypeError("fixture boom")'),
        ),
      );
      expect(exception.code, 'javascript_exception');
      expect(exception.name, 'TypeError');
      expect(exception.message, 'fixture boom');
      expect(exception.stack, contains('TypeError'));
      await expectError(
        first.evaluateJavaScript('Promise.reject(new Error("promise boom"))'),
        'javascript_exception',
      );
      await expectError(
        first.evaluateJavaScript('const cyclic={};cyclic.self=cyclic;cyclic'),
        'serialization_error',
      );
      await expectError(first.evaluateJavaScript('1n'), 'serialization_error');
      await expectError(
        first.evaluateJavaScript('"x".repeat(1048577)'),
        'result_too_large',
      );
      final concurrent = [
        for (var n = 0; n < 12; n++)
          first.evaluateJavaScript(
            'new Promise(r=>setTimeout(()=>r($n),${(12 - n) * 5}))',
          ),
      ];
      expect(
        await finish(Future.wait(concurrent)),
        List.generate(12, (n) => n),
      );
      await finish(first.evaluateJavaScript('window.counter=0'));
      final ordered = [
        for (var n = 0; n < 6; n++)
          first.evaluateJavaScript('++window.counter'),
      ];
      expect(await finish(Future.wait(ordered)), [1, 2, 3, 4, 5, 6]);
      expect(
        await finish(second.evaluateJavaScript('typeof window.counter')),
        'undefined',
      );
      print('JS_IPC_FLUTTER_RESULTS_CORRELATION_PASS');

      await expectError(
        first.evaluateJavaScript(
          'new Promise(()=>{})',
          timeout: const Duration(milliseconds: 50),
        ),
        'timeout',
      );
      final cancellation = JavaScriptCancellationToken();
      final cancelled = failureOf(
        first.evaluateJavaScript(
          'new Promise(()=>{})',
          cancellationToken: cancellation,
        ),
      );
      await finish(first.evaluateJavaScript('1'));
      await pending(1);
      cancellation.cancel();
      expect((await finish(cancelled)).code, 'cancelled');
      await pending(0);
      final stale = failureOf(
        first.evaluateJavaScript(
          'new Promise(r=>setTimeout(()=>r("old"),500))',
        ),
      );
      await finish(first.evaluateJavaScript('1'));
      await finish(first.loadRequest('$origin/new'));
      expect((await finish(stale)).code, anyOf('navigation', 'stale_context'));
      await ready('/new');
      expect(
        await finish(first.evaluateJavaScript('location.pathname')),
        '/new',
      );
      await pending(0);
      await finish(
        first.executeJavaScript(
          "chromiumPostMessage('player','hello 🌍\\u0000end')",
        ),
      );
      await waitFor(
        () => messages['first']!.any((m) => m.message == 'hello 🌍\u0000end'),
        'JS message stream preserves Unicode and NUL',
      );
      expect(messages['second']!.map((m) => m.message), ['ready:/second']);
      await finish(first.loadRequest('http://127.0.0.1:${denied.port}/denied'));
      await waitFor(
        () => first.currentUrl.endsWith('/denied') && !first.isLoading,
        'denied origin navigation finishes',
      );
      expect(await finish(first.evaluateJavaScript('1')), 1);
      expect(
        messages['first']!.any((m) => m.message == 'ready:/denied'),
        isFalse,
      );
      await finish(first.loadRequest('$origin/sandbox'));
      await waitFor(
        () => first.currentUrl.endsWith('/sandbox') && !first.isLoading,
        'sandbox navigation finishes',
      );
      expect(
        await finish(first.evaluateJavaScript('typeof chromiumPostMessage')),
        'undefined',
      );
      await finish(first.loadRequest('$origin/after'));
      await ready('/after');
      expect(
        await finish(
          first.evaluateJavaScript('''new Promise(resolve=>{
        const f=document.createElement('iframe');f.srcdoc='<script>parent.postMessage(typeof chromiumPostMessage,"*")</script>';
        addEventListener('message',e=>resolve(e.data),{once:true});document.body.append(f);
      })'''),
        ),
        'undefined',
      );
      print('JS_IPC_FLUTTER_LIFECYCLE_POLICY_PASS');

      final closed = failureOf(
        second.evaluateJavaScript('new Promise(()=>{})'),
      );
      await finish(second.evaluateJavaScript('1'));
      await pending(1);
      await finish(second.dispose());
      expect((await finish(closed)).code, 'browser_closed');
      await pending(0);
      await expectError(second.evaluateJavaScript('1'), 'browser_closed');
      final host = await children(pid, '/ChromiumWebViewHost');
      expect(host, hasLength(1), reason: 'Kill only this app process\'s host');
      final rendererFailure = failureOf(
        first.evaluateJavaScript('new Promise(()=>{})'),
      );
      await finish(first.evaluateJavaScript('1'));
      await pending(1);
      final renderers = await children(host.single, '--type=renderer');
      expect(renderers, isNotEmpty);
      for (final renderer in renderers)
        expect(Process.killPid(renderer, ProcessSignal.sigkill), isTrue);
      expect((await finish(rendererFailure)).code, 'renderer_gone');
      await pending(0);
      await expectError(first.evaluateJavaScript('1'), 'renderer_gone');
      await finish(first.loadRequest('$origin/recovered'));
      await ready('/recovered');
      expect(await finish(first.evaluateJavaScript('2')), 2);
      print('JS_IPC_FLUTTER_RENDERER_DEATH_PASS');

      final hostFailures = [
        for (var n = 0; n < 10; n++)
          failureOf(first.evaluateJavaScript('new Promise(()=>{})')),
      ];
      await finish(first.evaluateJavaScript('1'));
      await pending(10);
      expect(Process.killPid(host.single, ProcessSignal.sigkill), isTrue);
      expect(
        (await finish(Future.wait(hostFailures))).map((e) => e.code),
        everyElement('disconnected'),
      );
      var released = false;
      await waitFor(() {
        channel
            .invokeMapMethod<String, dynamic>('getDiagnostics')
            .then((state) => released = state?['browsers'] == 0);
        return released;
      }, 'host disconnect releases browsers');
      await tester.pumpWidget(
        const MaterialApp(home: Text('Flutter survived JS host death')),
      );
      expect(find.text('Flutter survived JS host death'), findsOneWidget);
      expect(tester.takeException(), isNull);
      print('JS_IPC_FLUTTER_HOST_DEATH_PASS');
    } finally {
      await tester.pumpWidget(const SizedBox());
      await finish(first.dispose());
      await finish(second.dispose());
      await waitFor(() => streamClosed, 'message stream closes on disposal');
      for (final subscription in subscriptions) await subscription.cancel();
      await allowed.close(force: true);
      await denied.close(force: true);
    }
  });
}
