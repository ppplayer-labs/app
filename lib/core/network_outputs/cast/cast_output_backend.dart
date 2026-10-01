import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import '../models.dart';
import '../network_output_backend.dart';
import 'cast_platform_client.dart';

class CastOutputBackend implements NetworkOutputBackend {
  final CastPlatformClient _client;
  final _outputsController = StreamController<List<PlaybackOutput>>.broadcast();
  final _sessionController =
      StreamController<NetworkOutputSessionState>.broadcast();
  StreamSubscription<dynamic>? _eventSubscription;

  CastOutputBackend({CastPlatformClient? client}) 
      : _client = client ?? NativeCastPlatformClient() {
    _eventSubscription = _client.events.listen(_onEvent);
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final type = event['event'];
    if (type == 'devices' && event['kind'] == 'googleCast') {
      final devices = event['devices'] as List?;
      if (devices == null) return;
      final outputs = devices.map((d) {
        final map = d as Map;
        return PlaybackOutput(
          id: map['id'],
          name: map['name'] ?? 'Unknown Cast Device',
          kind: OutputKind.googleCast,
          model: map['model'],
          capabilities: OutputCapabilities(
            audio: map['audio'] == true,
            video: map['video'] == true,
            play: true,
            pause: true,
            stop: true,
            seek: true,
            volume: true,
            mute: true,
            queue: false,
            subtitles: false,
            live: true,
            mimeTypes: {'*/*'},
          ),
        );
      }).toList();
      _outputsController.add(outputs);
    } else if (type == 'session' && event['kind'] == 'googleCast') {
      final stateStr = event['state'];
      final state = _parseSessionState(stateStr);
      _sessionController.add(
        NetworkOutputSessionState(
          sessionId: event['sessionId'] ?? '',
          endpointId: event['endpointId'] ?? '',
          state: state,
          itemId: event['itemId'] ?? '',
          error: event['error'],
        ),
      );
    } else if (type == 'status' && event['kind'] == 'googleCast') {
      final stateStr = event['state'];
      final state = _parseSessionState(stateStr);
      final bool seek = event['seek'] ?? true;
      final bool pause = event['pause'] ?? true;
      _sessionController.add(
        NetworkOutputSessionState(
          sessionId: event['sessionId'] ?? '',
          endpointId: event['endpointId'] ?? '',
          state: state,
          itemId: event['itemId'] ?? '',
          position: Duration(milliseconds: event['positionMs'] ?? 0),
          duration: Duration(milliseconds: event['durationMs'] ?? 0),
          isLive: event['isLive'] ?? false,
          volume: (event['volume'] as num?)?.toDouble() ?? 1.0,
          muted: event['muted'] ?? false,
          capabilities: OutputCapabilities(
            audio: true,
            video: true,
            play: true,
            pause: pause,
            stop: true,
            seek: seek,
            volume: true,
            mute: true,
            queue: false, // DLNA supports this, cast depends on sender queue
            subtitles: false,
            live: true,
            mimeTypes: {'*/*'},
          ),
        ),
      );
    }
  }

  PlaybackState _parseSessionState(String? state) {
    switch (state) {
      case 'connecting':
        return PlaybackState.buffering; // Closest match
      case 'connected':
        return PlaybackState.idle;
      case 'disconnecting':
        return PlaybackState.idle;
      case 'disconnected':
        return PlaybackState.idle;
      case 'playing':
        return PlaybackState.playing;
      case 'paused':
        return PlaybackState.paused;
      case 'buffering':
        return PlaybackState.buffering;
      case 'stopped':
        return PlaybackState.idle;
      case 'ended':
        return PlaybackState.ended;
      case 'idle':
      default:
        return PlaybackState.idle;
    }
  }

  @override
  OutputKind get kind => OutputKind.googleCast;

  @override
  Stream<List<PlaybackOutput>> get outputs => _outputsController.stream;

  @override
  Stream<NetworkOutputSessionState> get sessionState =>
      _sessionController.stream;

  @override
  Future<void> startDiscovery() async {
    debugPrint('[Output] google_cast discovery.start');
    await _client.startDiscovery();
  }

  @override
  Future<void> stopDiscovery() async {
    debugPrint('[Output] google_cast discovery.stop');
    await _client.stopDiscovery();
  }

  @override
  Future<void> connect(
    PlaybackOutput output, {
    required String sessionId,
  }) async {
    debugPrint(
      '[Output] google_cast connect.start id=${output.id} session=$sessionId',
    );
    await _client.connect(endpointId: output.id, sessionId: sessionId);
  }

  @override
  Future<void> disconnect({
    required String sessionId,
    required bool stopPlayback,
  }) async {
    debugPrint(
      '[Output] google_cast disconnect.start session=$sessionId stop=$stopPlayback',
    );
    await _client.disconnect(sessionId: sessionId, stopPlayback: stopPlayback);
  }

  @override
  Future<RemoteLoadResult> load(
    NetworkMediaItem item, {
    required String sessionId,
    required String itemId,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async {
    debugPrint(
      '[Output] google_cast load.start mime=${item.mimeType} session=$sessionId item=$itemId',
    );
    try {
      final result = await _client.load( {
        'sessionId': sessionId,
        'itemId': itemId,
        'autoplay': autoplay,
        'positionMs': position.inMilliseconds,
        'item': {
          'uri': item.uri.toString(),
          'mimeType': item.mimeType,
          'title': item.title,
          'artist': item.artist,
          'album': item.album,
          'artworkUri': item.artworkUri?.toString(),
          'isVideo': item.isVideo,
          'isLive': item.isLive,
          'durationMs': item.duration?.inMilliseconds,
        },
      });
      final map = result as Map?;
      if (map?['success'] == true) {
        return const RemoteLoadResult(success: true);
      }
      return RemoteLoadResult(
        success: false,
        error: map?['error']?.toString() ?? 'Load failed',
      );
    } on PlatformException catch (e) {
      return RemoteLoadResult(
        success: false,
        error: e.message ?? 'Platform error',
      );
    }
  }

  @override
  Future<void> play({required String sessionId, required String itemId}) async {
    await _client.play(sessionId: sessionId, itemId: itemId);
  }

  @override
  Future<void> pause({
    required String sessionId,
    required String itemId,
  }) async {
    await _client.pause(sessionId: sessionId, itemId: itemId);
  }

  @override
  Future<void> stop({required String sessionId, required String itemId}) async {
    await _client.stop(sessionId: sessionId, itemId: itemId);
  }

  @override
  Future<void> seek(
    Duration position, {
    required String sessionId,
    required String itemId,
  }) async {
    await _client.seek(position: position, sessionId: sessionId, itemId: itemId);
  }

  @override
  Future<void> setVolume(
    double volume, {
    required String sessionId,
    required String itemId,
  }) async {
    await _client.setVolume(volume: volume, sessionId: sessionId, itemId: itemId);
  }

  @override
  Future<void> setMute(
    bool muted, {
    required String sessionId,
    required String itemId,
  }) async {
    await _client.setMuted(muted: muted, sessionId: sessionId, itemId: itemId);
  }

  @override
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _outputsController.close();
    await _sessionController.close();
  }
}
