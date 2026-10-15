import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets('macOS input IPC and host death keep Flutter alive', (
    tester,
  ) async {
    if (!Platform.isMacOS) return;
    const channel = MethodChannel('flutter_chromium_webview');
    final telemetry = <Map<String, dynamic>>[];
    final errors = <Object>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.method == 'POST') {
        telemetry.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        request.response.statusCode = 204;
      } else {
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '''<!doctype html><style>body{margin:0;height:2000px}input{position:absolute;left:20px;top:20px;width:180px;height:30px}</style><input id="field"><script>
const id=location.pathname;
function report(e){fetch('/event',{method:'POST',body:JSON.stringify({id,type:e.type,value:field.value,x:e.clientX,y:e.clientY,target:e.target?.id,width:innerWidth,dpr:devicePixelRatio})})}
for(const t of ['focus','click','input','resize','keydown','keyup','mousedown','mouseup','mouseover','mousemove'])addEventListener(t,report,true);
report({type:'ready'});
</script>''',
        );
      }
      await request.response.close();
    });
    final origin = 'http://127.0.0.1:${server.port}';
    final first = ChromiumWebViewController(initialUrl: '$origin/first');
    final second = ChromiumWebViewController(initialUrl: '$origin/second');
    Future<void> waitFor(bool Function() check, String reason) async {
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (!check() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        check(),
        isTrue,
        reason: '$reason; telemetry=$telemetry; errors=$errors',
      );
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
        onError: (Object e) {
          failure = e;
          done = true;
        },
      );
      await waitFor(() => done, 'native operation completes');
      if (failure != null) throw failure!;
      return value as T;
    }

    bool seen(String id, String type, [String? value]) => telemetry.any(
      (e) =>
          e['id'] == id &&
          e['type'] == type &&
          (value == null || e['value'] == value),
    );
    try {
      expect(
        await finish(
          ChromiumWebViewController.initialize(
            cachePath: Directory.systemTemp
                .createTempSync('cef-input-integration-')
                .path,
          ),
        ),
        isTrue,
      );
      var width = 300.0;
      late StateSetter resize;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                resize = setState;
                return Row(
                  children: [
                    SizedBox(
                      width: width,
                      height: 250,
                      child: ChromiumWebView(
                        controller: first,
                        disposeController: false,
                        onError: errors.add,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      height: 250,
                      child: ChromiumWebView(
                        controller: second,
                        disposeController: false,
                        onError: errors.add,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await waitFor(
        () => seen('/first', 'ready') && seen('/second', 'ready'),
        'both CEF pages load',
      );
      expect(first.browserId, isNot(second.browserId));
      await waitFor(
        () =>
            telemetry.any((e) => e['id'] == '/first' && e['width'] == 300) &&
            telemetry.any((e) => e['id'] == '/second' && e['width'] == 300),
        'initial Flutter layout reaches CEF',
      );
      // Navigation telemetry precedes Chromium's compositor hit-test surface.
      // Let the first rendered page settle before injecting physical input.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump();
      final a =
          tester.getTopLeft(find.byType(Texture).at(0)) + const Offset(40, 35);
      final b =
          tester.getTopLeft(find.byType(Texture).at(1)) + const Offset(40, 35);
      Future<void> click(Offset position, String pageId) async {
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: position - const Offset(5, 0));
        await mouse.moveTo(position);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await mouse.down(position);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await mouse.up();
        await tester.pump();
        await waitFor(
          () => seen(pageId, 'click'),
          'CEF receives the Flutter click',
        );
        await mouse.removePointer();
        await tester.pump();
      }

      Future<void> type(ChromiumWebViewController controller, int char) async {
        for (final type in [0, 3, 2]) {
          await finish(
            channel.invokeMethod<void>('sendKeyEvent', {
              'browserId': controller.browserId,
              'type': type,
              'windows_key_code': char,
              'native_key_code': char == 65 ? 0 : 11,
              'character': char,
              'unmodified_character': char,
              'modifiers': 0,
            }),
          );
        }
      }

      await click(a, '/first');
      await waitFor(
        () => seen('/first', 'click'),
        'first field clicked from Flutter pointer',
      );
      await type(first, 65);
      await waitFor(
        () => seen('/first', 'input', 'A'),
        'first browser typed text',
      );
      await click(b, '/second');
      await type(second, 66);
      await waitFor(
        () => seen('/second', 'input', 'B'),
        'second browser typed text',
      );
      expect(seen('/first', 'input', 'AB'), isFalse);
      resize(() => width = 350);
      await tester.pump();
      await waitFor(
        () => telemetry.any(
          (e) =>
              e['id'] == '/first' && e['type'] == 'resize' && e['width'] == 350,
        ),
        'Flutter resize reaches CEF',
      );
      print('INPUT_IPC_FLUTTER_ROUTING_PASS');

      // Restrict the kill to this Flutter process's own CEF child.
      final children = await finish(
        Process.run('/usr/bin/pgrep', ['-P', '$pid']),
      );
      int? hostPid;
      for (final child in (children.stdout as String).trim().split('\n')) {
        if (int.tryParse(child) == null) continue;
        final name = await finish(
          Process.run('/bin/ps', ['-p', child, '-o', 'comm=']),
        );
        if ((name.stdout as String).trim().endsWith('/ChromiumWebViewHost'))
          hostPid = int.parse(child);
      }
      expect(hostPid, isNotNull, reason: 'Find only our CEF host child');
      final pending = <Future<void>>[];
      for (var n = 0; n < 100; n++) {
        pending.add(
          first
              .sendPointerInput(type: PointerInputType.move, x: n, y: 35)
              .catchError((Object error) => errors.add(error)),
        );
      }
      expect(Process.killPid(hostPid!, ProcessSignal.sigkill), isTrue);
      await finish(Future.wait(pending));
      var released = false;
      await waitFor(() {
        if (!released) {
          channel
              .invokeMapMethod<String, dynamic>('getDiagnostics')
              .then((state) => released = state?['browsers'] == 0);
        }
        return released;
      }, 'host disconnect releases native browsers');
      await tester.pumpWidget(
        const MaterialApp(home: Text('Flutter survived host death')),
      );
      await tester.pump();
      expect(find.text('Flutter survived host death'), findsOneWidget);
      expect(tester.takeException(), isNull);
      print('INPUT_IPC_FLUTTER_HOST_DEATH_PASS');
    } finally {
      await tester.pumpWidget(const SizedBox());
      await finish(first.dispose());
      await finish(second.dispose());
      await server.close(force: true);
    }
  });
}
