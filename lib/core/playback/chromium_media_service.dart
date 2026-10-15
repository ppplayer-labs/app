import 'package:flutter/services.dart';

/// A serialized service lease for the single Flutter-owned Android WebView.
/// AudioService owns media controls; this service never creates another player.
class ChromiumMediaService {
  static const channel = MethodChannel('com.ppplayer.app/headless_webview');
  static Future<void> _pending = Future.value();
  static bool _running = false;

  static Future<void> _enqueue(Future<void> Function() action) {
    final operation = _pending.then((_) => action());
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  static Future<void> start() => _enqueue(() async {
    if (_running) return;
    await channel.invokeMethod<void>('startChromiumService');
    _running = true;
  });
  static Future<void> stop() => _enqueue(() async {
    if (!_running) return;
    await channel.invokeMethod<void>('stopChromiumService');
    _running = false;
  });
}
