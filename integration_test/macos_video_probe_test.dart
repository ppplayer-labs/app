import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ppplayer/core/local_library/video_probe_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'probe classifies video vs audio-only (no VideoController)',
    (tester) async {
      await tester.runAsync(() async {
        final temp = await Directory.systemTemp.createTemp('probe_');
        final expected = {
          'test_video.mp4': VideoProbeResult.hasVideo,
          'test.mp3': VideoProbeResult.audioOnly,
          'test.flac': VideoProbeResult.audioOnly,
          'test.m4a': VideoProbeResult.audioOnly,
        };
        for (final e in expected.entries) {
          final d = await rootBundle.load('assets/test_fixtures/${e.key}');
          final f = File('${temp.path}/${e.key}');
          await f.writeAsBytes(
            d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes),
          );
          final sw = Stopwatch()..start();
          final r = await VideoProbeService.probe(Uri.file(f.path).toString());
          print('[DBG] ${e.key} -> $r in ${sw.elapsedMilliseconds}ms');
          expect(r, e.value);
        }
      });
    },
    skip: !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
