import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Verifies that repeatedly creating/disposing [MediaKitPlayerAdapter]s does
/// not accumulate MPV log observers on the shared native player: one native
/// event must be printed by a bounded number of observers regardless of how
/// many adapters were created and disposed before.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MPV log observers do not accumulate across adapter lifecycles',
    (tester) async {
      MediaKit.ensureInitialized();
      final warm = MediaKitPlayerAdapter();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 240,
            child: Video(controller: warm.videoController!),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.runAsync(() async {
        final temp = await Directory.systemTemp.createTemp('listener_');
        final f = File('${temp.path}/tone.wav');
        // 0.2s silent 8 kHz mono PCM WAV (no audible output, no assets needed).
        final samples = 1600;
        final data = BytesBuilderWav.build(samples);
        await f.writeAsBytes(data);

        Future<int> countLinesFor(String marker, {required int cycles}) async {
          var lines = 0;
          final spec = ZoneSpecification(
            print: (self, parent, zone, line) {
              if (line.startsWith('MPV_LOG:') && line.contains(marker)) {
                lines++;
              }
              parent.print(zone, line);
            },
          );
          await runZoned(() async {
            for (var i = 0; i < cycles; i++) {
              final a = MediaKitPlayerAdapter();
              await a.dispose();
            }
            final live = MediaKitPlayerAdapter();
            await live.open(Uri.file(f.path).toString(), play: false);
            await Future<void>.delayed(const Duration(milliseconds: 800));
            await live.stop();
            await Future<void>.delayed(const Duration(milliseconds: 300));
            await live.dispose();
          }, zoneSpecification: spec);
          return lines;
        }

        const marker = 'Opening'; // emitted once per loadfile by mpv
        final few = await countLinesFor(marker, cycles: 1);
        final many = await countLinesFor(marker, cycles: 25);
        print(
          '[Verification] listener lines: cycles=1 -> $few, cycles=25 -> $many',
        );
        expect(few, greaterThan(0), reason: 'no MPV log observed at all');
        expect(
          many,
          lessThanOrEqualTo(few * 2),
          reason: 'log callbacks grew with adapter count (listener leak)',
        );
        await temp.delete(recursive: true);
      });
    },
    skip: !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

class BytesBuilderWav {
  static List<int> build(int samples) {
    final dataLen = samples * 2;
    final b = <int>[];
    void s(String t) => b.addAll(t.codeUnits);
    void u32(int v) =>
        b.addAll([v & 255, (v >> 8) & 255, (v >> 16) & 255, (v >> 24) & 255]);
    void u16(int v) => b.addAll([v & 255, (v >> 8) & 255]);
    s('RIFF');
    u32(36 + dataLen);
    s('WAVEfmt ');
    u32(16);
    u16(1);
    u16(1);
    u32(8000);
    u32(16000);
    u16(2);
    u16(16);
    s('data');
    u32(dataLen);
    b.addAll(List.filled(dataLen, 0));
    return b;
  }
}
