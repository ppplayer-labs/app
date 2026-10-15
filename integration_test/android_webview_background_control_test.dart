import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:ppplayer/core/playback/chromium_media_service.dart';
import 'package:ppplayer/core/playback/pip_handler.dart';

// Offline HTML audio control: same Android WebView and support service, no
// YouTube iframe, remote media, recovery loop, visibility spoof or URL extractor.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android WebView offline audio Home/screen-off control', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;
    PipHandler.init();
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    final cache = Directory.systemTemp.createTempSync('webview-control-');
    expect(
      await ChromiumWebViewController.initialize(cachePath: cache.path),
      isTrue,
    );
    const onlineUrl = String.fromEnvironment('PPPLAYER_WEBVIEW_ONLINE_URL');
    final documentOrigin = onlineUrl.startsWith('http://127.0.0.1:')
        ? Uri.parse(onlineUrl).origin
        : 'https://ppplayer.com';
    final controller = ChromiumWebViewController(
      mediaPlaybackRequiresUserGesture: false,
      javaScriptChannels: [
        JavaScriptChannel(name: 'probe', allowedOrigins: {documentOrigin}),
      ],
    );
    const mseSecondUrl = String.fromEnvironment(
      'PPPLAYER_WEBVIEW_MSE_SECOND_URL',
    );
    var position = 0.0;
    var paused = true;
    final subscription = controller.onMessage.listen((message) {
      if (message.channel != 'probe') return;
      final value = jsonDecode(message.message) as Map<String, dynamic>;
      if (value.containsKey('diagnosticError')) {
        print('WEBVIEW_CONTROL_FIXTURE_ERROR ${value['diagnosticError']}');
        return;
      }
      position = (value['time'] as num).toDouble();
      paused = value['paused'] as bool;
      print('WEBVIEW_CONTROL_SAMPLE ${message.message}');
    });
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ChromiumWebView(
            controller: controller,
            disposeController: false,
          ),
        ),
      );
      await ChromiumMediaService.start();
      // 90 seconds of unsigned 8-bit mono silence, small enough for inline HTML.
      final wav = Uint8List(44 + 8000 * 90)..fillRange(44, 44 + 8000 * 90, 128);
      final header = ByteData.sublistView(wav);
      void text(int start, String value) =>
          wav.setRange(start, start + value.length, value.codeUnits);
      text(0, 'RIFF');
      header.setUint32(4, wav.length - 8, Endian.little);
      text(8, 'WAVEfmt ');
      header.setUint32(16, 16, Endian.little);
      header.setUint16(20, 1, Endian.little);
      header.setUint16(22, 1, Endian.little);
      header.setUint32(24, 8000, Endian.little);
      header.setUint32(28, 8000, Endian.little);
      header.setUint16(32, 1, Endian.little);
      header.setUint16(34, 8, Endian.little);
      text(36, 'data');
      header.setUint32(40, wav.length - 44, Endian.little);
      const videoControl = bool.fromEnvironment(
        'PPPLAYER_WEBVIEW_VIDEO_CONTROL',
      );
      final video = videoControl
          ? await rootBundle.load('assets/test_fixtures/test_video.mp4')
          : null;
      final tag = videoControl || onlineUrl.isNotEmpty ? 'video' : 'audio';
      final mime = videoControl ? 'video/mp4' : 'audio/wav';
      final data = video == null
          ? wav
          : video.buffer.asUint8List(video.offsetInBytes, video.lengthInBytes);
      final source = onlineUrl.isNotEmpty
          ? const HtmlEscape(HtmlEscapeMode.attribute).convert(onlineUrl)
          : 'data:$mime;base64,${base64Encode(data)}';
      final mseSetup = mseSecondUrl.isEmpty
          ? ''
          : """
const mediaSource = new MediaSource();
const element = document.getElementById('audio');
element.src = URL.createObjectURL(mediaSource);
mediaSource.addEventListener('sourceopen', async () => {
 try {
  const buffer = mediaSource.addSourceBuffer('video/webm; codecs="vp9"');
  buffer.mode = 'segments';
  for (const url of ${jsonEncode([onlineUrl, mseSecondUrl])}) {
   if (buffer.buffered.length > 0) { const offset=buffer.buffered.end(buffer.buffered.length-1);buffer.abort();buffer.timestampOffset=offset; }
   const response = await fetch(url);
   if (!response.ok) throw new Error('Fixture HTTP '+response.status);
   const bytes = await response.arrayBuffer();
   await new Promise((resolve,reject)=>{buffer.addEventListener('updateend',resolve,{once:true});buffer.addEventListener('error',reject,{once:true});buffer.appendBuffer(bytes);});
  }
  mediaSource.endOfStream();
 } catch(error) { chromiumPostMessage('probe',JSON.stringify({diagnosticError:String(error)})); }
},{once:true});
""";
      await controller.loadHtmlString(
        '''<!doctype html><$tag id="audio" autoplay loop playsinline src="${mseSecondUrl.isEmpty ? source : ''}"></$tag><script>
$mseSetup
let previous=0,total=0;
setInterval(()=>{const a=document.getElementById('audio');let delta=a.currentTime-previous;if(delta<0&&Number.isFinite(a.duration))delta+=a.duration;total+=Math.max(0,delta);previous=a.currentTime;chromiumPostMessage('probe',JSON.stringify({wallMs:Date.now(),perfMs:performance.now(),time:total,rawTime:a.currentTime,buffered:Array.from({length:a.buffered.length},(_,i)=>[a.buffered.start(i),a.buffered.end(i)]),tag:a.tagName,paused:a.paused,readyState:a.readyState,error:a.error?a.error.code:null,hidden:document.hidden}));},500);
</script>''',
        baseUrl: '$documentOrigin/offline-control',
      );
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (position < 2 && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(position, greaterThan(1));
      expect(paused, isFalse);
      final foregroundStart = position;
      const foregroundOnly = bool.fromEnvironment(
        'PPPLAYER_WEBVIEW_FOREGROUND_ONLY',
      );
      for (var i = 0; i < (foregroundOnly ? 9 : 3); i++) {
        final previous = position;
        await tester.pump(const Duration(seconds: 10));
        expect(PipHandler.isActivityStopped, isFalse);
        expect(
          position - previous,
          greaterThan(5),
          reason: 'Foreground control stalled',
        );
      }
      print(
        'WEBVIEW_CONTROL_FOREGROUND_PASS before=$foregroundStart after=$position',
      );
      if (foregroundOnly) {
        print('WEBVIEW_CONTROL_PASS');
        return;
      }
      print('WEBVIEW_CONTROL_HOME_READY');
      final beforeHome = position;
      await Future<void>.delayed(const Duration(seconds: 15));
      expect(PipHandler.isActivityStopped, isTrue);
      expect(position - beforeHome, greaterThan(10));
      print('WEBVIEW_CONTROL_SCREEN_OFF_READY');
      final beforeSleep = position;
      await Future<void>.delayed(const Duration(seconds: 20));
      final state = await ChromiumMediaService.channel
          .invokeMapMethod<String, dynamic>('chromiumServiceState');
      expect(state?['interactive'], isFalse);
      expect(position - beforeSleep, greaterThan(15));
      expect(paused, isFalse);
      print('WEBVIEW_CONTROL_PASS');
    } finally {
      print('WEBVIEW_CONTROL_CLEANUP');
      await controller.dispose();
      await subscription.cancel();
      await ChromiumMediaService.stop();
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
      await tester.pumpWidget(const SizedBox());
    }
  });
}
