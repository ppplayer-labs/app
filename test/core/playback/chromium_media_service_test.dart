import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/playback/chromium_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  Completer<void>? gate;
  bool fail = false;
  setUp(() {
    calls.clear();
    gate = null;
    fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ChromiumMediaService.channel, (call) async {
          calls.add(call.method);
          if (call.method == 'startChromiumService') {
            await gate?.future;
            if (fail) throw PlatformException(code: 'SERVICE_START_FAILED');
          }
          return null;
        });
  });
  tearDown(() async {
    await ChromiumMediaService.stop();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ChromiumMediaService.channel, null);
  });
  test('concurrent leases start once and stop once', () async {
    await Future.wait([
      ChromiumMediaService.start(),
      ChromiumMediaService.start(),
    ]);
    await Future.wait([
      ChromiumMediaService.stop(),
      ChromiumMediaService.stop(),
    ]);
    expect(calls, ['startChromiumService', 'stopChromiumService']);
  });
  test(
    'stop waits for pending start rather than leaking its late completion',
    () async {
      gate = Completer<void>();
      final start = ChromiumMediaService.start();
      await Future<void>.delayed(Duration.zero);
      final stop = ChromiumMediaService.stop();
      expect(calls, ['startChromiumService']);
      gate!.complete();
      await Future.wait([start, stop]);
      expect(calls, ['startChromiumService', 'stopChromiumService']);
    },
  );
  test(
    'failed start does not acquire a lease and a later explicit request retries',
    () async {
      fail = true;
      await expectLater(
        ChromiumMediaService.start(),
        throwsA(isA<PlatformException>()),
      );
      await ChromiumMediaService.stop();
      expect(calls, ['startChromiumService']);
      fail = false;
      await ChromiumMediaService.start();
      expect(calls, ['startChromiumService', 'startChromiumService']);
    },
  );
}
