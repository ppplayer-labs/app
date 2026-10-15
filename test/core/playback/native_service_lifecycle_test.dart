import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ppplayer.app/headless_webview');
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'unused lazy fallback never starts or stops another player service',
    () async {
      final engine = NativeServicePlaybackEngine(startAutomatically: false);
      await engine.stop();
      await engine.dispose();
      expect(calls, isNot(contains('startService')));
      expect(calls, isNot(contains('stopService')));
    },
  );
  test('lazy fallback starts once before its first playback command', () async {
    final engine = NativeServicePlaybackEngine(startAutomatically: false);
    const track = PlaybackTrack(id: 'M7lc1UVf-VE', title: 'Probe');
    await engine.prepare(track);
    await engine.play(track);
    await engine.dispose();
    expect(calls.first, 'startService');
    expect(calls.where((call) => call == 'startService'), hasLength(1));
    expect(calls.last, 'stopService');
  });
  test('stop invalidates playback waiting for service creation', () async {
    final ready = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'startService') await ready.future;
          return null;
        });
    final engine = NativeServicePlaybackEngine(startAutomatically: false);
    final playing = engine.play(
      const PlaybackTrack(id: 'M7lc1UVf-VE', title: 'Probe'),
    );
    await Future<void>.delayed(Duration.zero);
    await engine.stop();
    ready.complete();
    await playing;
    expect(calls, isNot(contains('loadVideo')));
    expect(engine.currentStatus.state, PlaybackState.idle);
    await engine.dispose();
  });
  test(
    'service creation failure propagates instead of silently loading',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            throw PlatformException(code: 'SERVICE_START_FAILED');
          });
      final engine = NativeServicePlaybackEngine(startAutomatically: false);
      await expectLater(
        engine.play(const PlaybackTrack(id: 'M7lc1UVf-VE', title: 'Probe')),
        throwsA(isA<PlatformException>()),
      );
      expect(calls, ['startService']);
      await engine.dispose();
    },
  );
}
