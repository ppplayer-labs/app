import 'package:flutter/services.dart';

/// Keeps the Flutter-owned, audio-only Chromium player backed by the app service.
class ChromiumMediaService {
  static const channel = MethodChannel('com.ppplayer.app/headless_webview');
  static Future<void> start() =>
      channel.invokeMethod<void>('startChromiumService');
  static Future<void> stop() =>
      channel.invokeMethod<void>('stopChromiumService');
}
