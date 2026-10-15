import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets('CEF presents new surface pixels after repeated resizes', (
    tester,
  ) async {
    if (!Platform.isMacOS) return;
    final cache = Directory.systemTemp.createTempSync('cef-texture-resize-');
    expect(
      await ChromiumWebViewController.initialize(cachePath: cache.path),
      isTrue,
    );
    final controller = ChromiumWebViewController();
    final key = GlobalKey();
    try {
      await controller.loadHtmlString(
        '<!doctype html><style>html,body{margin:0;background:rgb(255,0,0)}'
        '@media(min-width:350px){html,body{background:rgb(0,0,255)}}</style>',
        baseUrl: 'https://ppplayer.com/texture-resize-test',
      );
      for (final width in [240.0, 480.0, 160.0, 400.0, 240.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: width,
                  height: 180,
                  child: ChromiumWebView(
                    controller: controller,
                    disposeController: false,
                  ),
                ),
              ),
            ),
          ),
        );
        final expected = width >= 350 ? [0, 0, 255, 255] : [255, 0, 0, 255];
        List<int>? pixel;
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final offset =
              ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
          pixel = bytes!.buffer
              .asUint8List(bytes.offsetInBytes + offset, 4)
              .toList();
          image.dispose();
          if (pixel[0] == expected[0] && pixel[2] == expected[2]) break;
        }
        expect(pixel, expected, reason: 'Presented pixels at width $width');
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.dispose();
    }
  });
}
