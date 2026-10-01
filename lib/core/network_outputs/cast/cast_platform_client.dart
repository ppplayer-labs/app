import 'dart:async';
import 'package:flutter/services.dart';

abstract class CastPlatformClient {
  Stream<dynamic> get events;
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> connect({required String endpointId, required String sessionId});
  Future<void> disconnect({required String sessionId, required bool stopPlayback});
  Future<Map<String, dynamic>> load(Map<String, dynamic> arguments);
  Future<void> play({required String sessionId, required String itemId});
  Future<void> pause({required String sessionId, required String itemId});
  Future<void> stop({required String sessionId, required String itemId});
  Future<void> seek({required String sessionId, required String itemId, required Duration position});
  Future<void> setVolume({required String sessionId, required String itemId, required double volume});
  Future<void> setMuted({required String sessionId, required String itemId, required bool muted});
}

class NativeCastPlatformClient implements CastPlatformClient {
  static const _methods = MethodChannel('com.ppplayer.app/network_outputs');
  static const _events = EventChannel('com.ppplayer.app/network_output_events');

  @override
  Stream<dynamic> get events => _events.receiveBroadcastStream();

  @override
  Future<void> startDiscovery() => _methods.invokeMethod('startDiscovery');

  @override
  Future<void> stopDiscovery() => _methods.invokeMethod('stopDiscovery');

  @override
  Future<void> connect({required String endpointId, required String sessionId}) {
    return _methods.invokeMethod('connect', {
      'endpointId': endpointId,
      'sessionId': sessionId,
    });
  }

  @override
  Future<void> disconnect({required String sessionId, required bool stopPlayback}) {
    return _methods.invokeMethod('disconnect', {
      'sessionId': sessionId,
      'stopPlayback': stopPlayback,
    });
  }

  @override
  Future<Map<String, dynamic>> load(Map<String, dynamic> arguments) async {
    final result = await _methods.invokeMethod('load', arguments);
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> play({required String sessionId, required String itemId}) {
    return _methods.invokeMethod('play', {'sessionId': sessionId, 'itemId': itemId});
  }

  @override
  Future<void> pause({required String sessionId, required String itemId}) {
    return _methods.invokeMethod('pause', {'sessionId': sessionId, 'itemId': itemId});
  }

  @override
  Future<void> stop({required String sessionId, required String itemId}) {
    return _methods.invokeMethod('stop', {'sessionId': sessionId, 'itemId': itemId});
  }

  @override
  Future<void> seek({required String sessionId, required String itemId, required Duration position}) {
    return _methods.invokeMethod('seek', {
      'sessionId': sessionId,
      'itemId': itemId,
      'positionMs': position.inMilliseconds,
    });
  }

  @override
  Future<void> setVolume({required String sessionId, required String itemId, required double volume}) {
    return _methods.invokeMethod('setVolume', {
      'sessionId': sessionId,
      'itemId': itemId,
      'volume': volume,
    });
  }

  @override
  Future<void> setMuted({required String sessionId, required String itemId, required bool muted}) {
    return _methods.invokeMethod('setMute', {
      'sessionId': sessionId,
      'itemId': itemId,
      'muted': muted,
    });
  }
}
