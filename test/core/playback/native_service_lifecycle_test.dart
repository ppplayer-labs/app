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
}
