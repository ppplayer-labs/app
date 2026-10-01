import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cast_platform_client.dart';

class FakeCastPlatformClient implements CastPlatformClient {
  final _events = StreamController<dynamic>.broadcast();
  Timer? _playbackTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  String? _sessionId;
  String? _itemId;
  String? _endpointId;
  int _generation = 0;

  @override
  Stream<dynamic> get events => _events.stream;

  @override
  Future<void> startDiscovery() async {
    debugPrint('[FakeCastPlatformClient] startDiscovery');
    await Future.delayed(const Duration(milliseconds: 300));
    _events.add({
      'event': 'devices',
      'kind': 'googleCast',
      'devices': [
        {
          'id': 'debug-fake-cast-01',
          'name': 'PPPlayer Fake Chromecast',
          'model': 'Debug',
          'audio': true,
          'video': true,
        },
      ],
    });
  }

  @override
  Future<void> stopDiscovery() async {
    debugPrint('[FakeCastPlatformClient] stopDiscovery');
  }

  @override
  Future<void> connect({
    required String endpointId,
    required String sessionId,
  }) async {
    debugPrint(
      '[FakeCastPlatformClient] connect endpoint=$endpointId sessionId=$sessionId',
    );
    final generation = ++_generation;
    _playbackTimer?.cancel();
    _isPlaying = false;
    _itemId = null;
    _sessionId = sessionId;
    _endpointId = endpointId;
    await Future<void>.delayed(Duration.zero);
    if (generation != _generation) return;
    _events.add({
      'event': 'session',
      'kind': 'googleCast',
      'sessionId': sessionId,
      'endpointId': endpointId,
      'state': 'connecting',
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (generation != _generation) return;
    _events.add({
      'event': 'session',
      'kind': 'googleCast',
      'sessionId': sessionId,
      'endpointId': endpointId,
      'state': 'connected',
    });
  }

  @override
  Future<void> disconnect({
    required String sessionId,
    required bool stopPlayback,
  }) async {
    if (_sessionId != sessionId) return;
    ++_generation;
    _isPlaying = false;
    debugPrint(
      '[FakeCastPlatformClient] disconnect sessionId=$sessionId stop=$stopPlayback',
    );
    _playbackTimer?.cancel();
    _events.add({
      'event': 'session',
      'kind': 'googleCast',
      'sessionId': sessionId,
      'endpointId': _endpointId,
      'itemId': _itemId,
      'state': 'disconnected',
    });
    _sessionId = null;
    _itemId = null;
    _endpointId = null;
  }

  @override
  Future<Map<String, dynamic>> load(Map<String, dynamic> arguments) async {
    debugPrint('[FakeCastPlatformClient] load');
    final sessionId = arguments['sessionId'] as String?;
    final itemId = arguments['itemId'] as String?;
    if (sessionId != _sessionId ||
        _endpointId == null ||
        itemId == null ||
        itemId.isEmpty) {
      return {'success': false, 'error': 'Session or item mismatch'};
    }
    final generation = ++_generation;
    _playbackTimer?.cancel();
    final positionMs = arguments['positionMs'] as int? ?? 0;
    final item = arguments['item'] as Map?;
    _duration = Duration(milliseconds: (item?['durationMs'] as int?) ?? 600000);
    _position = Duration(milliseconds: positionMs);
    _itemId = itemId;

    // Emit buffering *after* the delay so _pendingRemote is guaranteed to be
    // set by the time NetworkOutputController._onSession sees this event.
    await Future.delayed(const Duration(milliseconds: 200));
    if (generation != _generation)
      return {'success': false, 'error': 'Load superseded'};

    _events.add({
      'event': 'status',
      'kind': 'googleCast',
      'sessionId': sessionId,
      'endpointId': _endpointId, // required for _matches() in controller
      'itemId': itemId,
      'state': 'buffering',
      'positionMs': _position.inMilliseconds,
      'durationMs': _duration.inMilliseconds,
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (generation != _generation)
      return {'success': false, 'error': 'Load superseded'};

    _isPlaying = (arguments['autoplay'] as bool?) ?? true;
    _emitStatus();
    if (_isPlaying) _startTimer();
    return {'success': true, 'positionMs': positionMs};
  }

  @override
  Future<void> play({required String sessionId, required String itemId}) async {
    if (!_matches(sessionId, itemId)) return;
    _isPlaying = true;
    _startTimer();
    _emitStatus();
  }

  @override
  Future<void> pause({
    required String sessionId,
    required String itemId,
  }) async {
    if (!_matches(sessionId, itemId)) return;
    _isPlaying = false;
    _playbackTimer?.cancel();
    _emitStatus();
  }

  @override
  Future<void> stop({required String sessionId, required String itemId}) async {
    if (!_matches(sessionId, itemId)) return;
    _isPlaying = false;
    _playbackTimer?.cancel();
    _position = Duration.zero;
    _events.add({
      'event': 'status',
      'kind': 'googleCast',
      'sessionId': sessionId,
      'itemId': itemId,
      'endpointId': _endpointId,
      'state': 'idle',
      'positionMs': 0,
      'durationMs': _duration.inMilliseconds,
    });
  }

  @override
  Future<void> seek({
    required String sessionId,
    required String itemId,
    required Duration position,
  }) async {
    if (!_matches(sessionId, itemId)) return;
    _position = position;
    if (_position > _duration) _position = _duration;
    if (_position < Duration.zero) _position = Duration.zero;
    _emitStatus();
  }

  @override
  Future<void> setVolume({
    required String sessionId,
    required String itemId,
    required double volume,
  }) async {
    if (!_matches(sessionId, itemId)) return;
    _emitStatus(volume: volume);
  }

  @override
  Future<void> setMuted({
    required String sessionId,
    required String itemId,
    required bool muted,
  }) async {
    if (!_matches(sessionId, itemId)) return;
    _emitStatus(muted: muted);
  }

  bool _matches(String sessionId, String itemId) =>
      _endpointId != null && _sessionId == sessionId && _itemId == itemId;

  Future<void> dispose() async {
    ++_generation;
    _playbackTimer?.cancel();
    await _events.close();
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;
      _position += const Duration(seconds: 1);
      if (_position >= _duration) {
        _position = _duration;
        _isPlaying = false;
        timer.cancel();
        _events.add({
          'event': 'status',
          'kind': 'googleCast',
          'sessionId': _sessionId,
          'endpointId': _endpointId,
          'itemId': _itemId,
          'state': 'ended',
          'positionMs': _position.inMilliseconds,
          'durationMs': _duration.inMilliseconds,
        });
      } else {
        _emitStatus();
      }
    });
  }

  void _emitStatus({double volume = 1.0, bool muted = false}) {
    if (_sessionId == null || _itemId == null) return;
    _events.add({
      'event': 'status',
      'kind': 'googleCast',
      'sessionId': _sessionId,
      'endpointId':
          _endpointId, // required for _matches() in NetworkOutputController
      'itemId': _itemId,
      'state': _isPlaying ? 'playing' : 'paused',
      'positionMs': _position.inMilliseconds,
      'durationMs': _duration.inMilliseconds,
      'volume': volume,
      'muted': muted,
    });
  }
}
