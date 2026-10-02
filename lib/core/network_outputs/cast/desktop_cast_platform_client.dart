import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cast_platform_client.dart';
import 'desktop_cast_transport.dart';

/// macOS Cast sender. Native Bonjour discovers endpoints; CASTV2 controls the
/// default media receiver. File acquisition remains in NetworkMediaFactory.
class DesktopCastPlatformClient implements CastPlatformClient {
  DesktopCastPlatformClient({
    Stream<dynamic>? discoveryEvents,
    Future<void> Function(bool)? discoveryControl,
    DesktopCastTransport Function()? transportFactory,
    this.requestTimeout = const Duration(seconds: 8),
    this.pollInterval = const Duration(seconds: 2),
  }) : _discoveryEvents =
           discoveryEvents ??
           const EventChannel(
             'com.ppplayer.app/cast_discovery_events',
           ).receiveBroadcastStream(),
       _discoveryControl = discoveryControl ?? _controlDiscovery,
       _transportFactory = transportFactory ?? CastV2DesktopTransport.new;

  static const connection = 'urn:x-cast:com.google.cast.tp.connection';
  static const heartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
  static const receiver = 'urn:x-cast:com.google.cast.receiver';
  static const media = 'urn:x-cast:com.google.cast.media';
  static const appId = 'CC1AD845';
  static const _methods = MethodChannel('com.ppplayer.app/cast_discovery');
  static Future<void> _controlDiscovery(bool start) =>
      _methods.invokeMethod(start ? 'startDiscovery' : 'stopDiscovery');

  final Duration requestTimeout;
  final Duration pollInterval;
  final Stream<dynamic> _discoveryEvents;
  final Future<void> Function(bool) _discoveryControl;
  final DesktopCastTransport Function() _transportFactory;
  final _events = StreamController<dynamic>.broadcast();
  final _devices = <String, Map<String, dynamic>>{};
  final _requests = <int, Completer<DesktopCastMessage>>{};
  final _requestNamespaces = <int, String>{};
  StreamSubscription<dynamic>? _discoverySubscription;
  StreamSubscription<DesktopCastMessage>? _messages;
  DesktopCastTransport? _transport;
  Timer? _timer;
  String? _endpointId, _sessionId, _itemId, _transportId, _receiverSessionId;
  String? _contentId;
  int? _mediaSessionId;
  int _requestId = 0, _generation = 0;
  int? _loadingRequest;
  bool _disposed = false;
  bool _isLive = false;
  double _volume = 1;
  bool _muted = false;
  DateTime _lastMessage = DateTime.now();
  Map<String, dynamic>? _lastStatus;

  @override
  Stream<dynamic> get events => _events.stream;

  void _emit(Map<String, dynamic> event) {
    if (!_disposed) _events.add({'kind': 'googleCast', ...event});
  }

  void _session(String state, {String? error}) => _emit({
    'event': 'session',
    'endpointId': _endpointId,
    'sessionId': _sessionId,
    'itemId': _itemId ?? '',
    'state': state,
    if (error != null) 'error': error,
  });

  @override
  Future<void> startDiscovery() async {
    _discoverySubscription ??= _discoveryEvents.listen(
      (event) {
        if (event is! Map) return;
        if (event['error'] != null) {
          _events.addError(
            PlatformException(
              code: 'CAST_DISCOVERY',
              message: event['error'].toString(),
            ),
          );
          return;
        }
        final devices = event['devices'] as List?;
        if (devices == null) return;
        _devices.clear();
        for (final raw in devices.whereType<Map>()) {
          final device = Map<String, dynamic>.from(raw);
          if (device['id'] is String &&
              device['host'] is String &&
              device['port'] is int)
            _devices[device['id']] = device;
        }
        _emit({'event': 'devices', 'devices': _devices.values.toList()});
        debugPrint('[DesktopCast] discovery devices=${_devices.length}');
      },
      onError: (Object error) {
        if (!_disposed) _events.addError(error);
      },
    );
    await _discoveryControl(true);
  }

  @override
  Future<void> stopDiscovery() async {
    await _discoveryControl(false);
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    // Keep resolved endpoints for outputs already selected by the controller.
  }

  Future<DesktopCastMessage> _request(
    String namespace,
    String destination,
    Map<String, dynamic> payload, {
    int? requestId,
  }) async {
    final id = requestId ?? ++_requestId;
    final completer = Completer<DesktopCastMessage>();
    _requests[id] = completer;
    _requestNamespaces[id] = namespace;
    try {
      _transport!.send(namespace, destination, {...payload, 'requestId': id});
      final response = await completer.future.timeout(requestTimeout);
      if (const {
        'LOAD_FAILED',
        'LOAD_CANCELLED',
        'INVALID_REQUEST',
        'INVALID_PLAYER_STATE',
        'LAUNCH_ERROR',
      }.contains(response.payload['type'])) {
        throw StateError(
          'Receiver rejected ${payload['type']}: ${response.payload['type']}',
        );
      }
      return response;
    } finally {
      _requests.remove(id);
      _requestNamespaces.remove(id);
    }
  }

  @override
  Future<void> connect({
    required String endpointId,
    required String sessionId,
  }) async {
    final device = _devices[endpointId];
    if (device == null)
      throw StateError('Chromecast is no longer available. Refresh devices.');
    await _close();
    final generation = ++_generation;
    _endpointId = endpointId;
    _sessionId = sessionId;
    _itemId = null;
    _session('connecting');
    final transport = _transportFactory();
    _transport = transport;
    try {
      await transport.connect(device['host'] as String, device['port'] as int);
      if (_disposed || generation != _generation) {
        await transport.close();
        throw StateError('Cast connection was cancelled.');
      }
      _lastMessage = DateTime.now();
      _messages = transport.messages.listen(
        (message) {
          if (generation == _generation) _onMessage(message);
        },
        onError: (Object error) {
          if (generation == _generation) _lost('Cast connection failed.');
        },
        onDone: () {
          if (generation == _generation) _lost('Chromecast disconnected.');
        },
      );
      transport.send(connection, 'receiver-0', {
        'type': 'CONNECT',
        'origin': {},
      });
      final response = await _request(receiver, 'receiver-0', {
        'type': 'LAUNCH',
        'appId': appId,
      });
      final apps =
          (response.payload['status'] as Map?)?['applications'] as List?;
      final app = apps
          ?.whereType<Map>()
          .where((app) => app['appId'] == appId)
          .firstOrNull;
      if (app == null ||
          app['transportId'] is! String ||
          app['sessionId'] is! String) {
        throw StateError('Chromecast did not launch the media receiver.');
      }
      _transportId = app['transportId'];
      _receiverSessionId = app['sessionId'];
      transport.send(connection, _transportId!, {
        'type': 'CONNECT',
        'origin': {},
      });
      _session('connected');
      debugPrint('[DesktopCast] receiver connected endpoint=$endpointId');
      _timer = Timer.periodic(pollInterval, (_) {
        if (DateTime.now().difference(_lastMessage) >
            const Duration(seconds: 15)) {
          _lost('Chromecast heartbeat timed out.');
          return;
        }
        transport.send(heartbeat, 'receiver-0', {'type': 'PING'});
        if (_mediaSessionId != null && _loadingRequest == null) {
          transport.send(media, _transportId!, {
            'type': 'GET_STATUS',
            'requestId': ++_requestId,
          });
        }
      });
    } catch (_) {
      if (generation == _generation) await _close();
      rethrow;
    }
  }

  void _onMessage(DesktopCastMessage message) {
    final payload = message.payload;
    final validSource = message.namespace == media
        ? message.sourceId == _transportId
        : message.sourceId == 'receiver-0' ||
              (message.namespace == connection &&
                  message.sourceId == _transportId);
    if (!validSource) return;
    _lastMessage = DateTime.now();
    if (message.namespace == heartbeat && payload['type'] == 'PING') {
      _transport?.send(heartbeat, 'receiver-0', {'type': 'PONG'});
    }
    if (message.namespace == connection && payload['type'] == 'CLOSE') {
      _lost('Chromecast closed the connection.');
      return;
    }
    if (message.namespace == receiver) {
      final volume = (payload['status'] as Map?)?['volume'] as Map?;
      _volume = (volume?['level'] as num?)?.toDouble() ?? _volume;
      _muted = volume?['muted'] as bool? ?? _muted;
      if (_lastStatus != null) _publishStatus(_lastStatus!);
    }
    if (message.namespace == media && payload['type'] == 'MEDIA_STATUS') {
      final statuses = payload['status'] as List?;
      for (final status in statuses?.whereType<Map>() ?? const <Map>[]) {
        final mediaInfo = status['media'] as Map?;
        final custom = mediaInfo?['customData'] as Map?;
        final loading = _loadingRequest;
        if (loading != null) {
          if (payload['requestId'] != loading ||
              status['mediaSessionId'] is! int)
            continue;
          if (mediaInfo?['contentId'] != null &&
              mediaInfo?['contentId'] != _contentId)
            continue;
          _mediaSessionId = status['mediaSessionId'];
        } else if (status['mediaSessionId'] != _mediaSessionId) {
          continue;
        }
        if (custom?['ppplayerItemId'] != null &&
            custom?['ppplayerItemId'] != _itemId)
          continue;
        if (mediaInfo?['contentId'] != null &&
            mediaInfo?['contentId'] != _contentId)
          continue;
        _lastStatus = {...?_lastStatus, ...Map<String, dynamic>.from(status)};
        _publishStatus(_lastStatus!);
      }
    }
    final request = _requests[payload['requestId']];
    if (request != null &&
        !request.isCompleted &&
        _requestNamespaces[payload['requestId']] == message.namespace) {
      request.complete(message);
    }
  }

  void _publishStatus(Map<String, dynamic> status) {
    if (_itemId == null || _mediaSessionId == null) return;
    final info = status['media'] as Map?;
    _isLive = info?['streamType'] == 'LIVE' || _isLive;
    final state = switch (status['playerState']) {
      'PLAYING' => 'playing',
      'PAUSED' => 'paused',
      'BUFFERING' => 'buffering',
      'IDLE' when status['idleReason'] == 'FINISHED' => 'ended',
      'IDLE' when status['idleReason'] == 'ERROR' => 'error',
      _ => 'stopped',
    };
    _emit({
      'event': 'status',
      'endpointId': _endpointId,
      'sessionId': _sessionId,
      'itemId': _itemId,
      'state': state,
      'positionMs': ((status['currentTime'] as num? ?? 0) * 1000).round(),
      'durationMs': ((info?['duration'] as num? ?? 0) * 1000).round(),
      'isLive': _isLive,
      'seek': !_isLive,
      'pause': true,
      'volume': _volume,
      'muted': _muted,
      if (state == 'error') 'error': 'Chromecast could not play this media.',
    });
  }

  void _requireSession(String sessionId, [String? itemId]) {
    if (_disposed ||
        _transportId == null ||
        sessionId != _sessionId ||
        (itemId != null && (itemId != _itemId || _mediaSessionId == null))) {
      throw StateError('Stale Chromecast session or item.');
    }
  }

  @override
  Future<Map<String, dynamic>> load(Map<String, dynamic> arguments) async {
    _requireSession(arguments['sessionId'] as String);
    final item = arguments['item'] as Map;
    final uri = Uri.tryParse(item['uri'] as String);
    if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) {
      return {
        'success': false,
        'error': 'Chromecast requires an HTTP media URL.',
      };
    }
    _itemId = arguments['itemId'] as String;
    _contentId = uri.toString();
    _mediaSessionId = null;
    _lastStatus = null;
    _isLive = item['isLive'] == true;
    final id = ++_requestId;
    _loadingRequest = id;
    final artwork = Uri.tryParse(item['artworkUri'] as String? ?? '');
    try {
      final response = await _request(media, _transportId!, {
        'type': 'LOAD',
        'autoplay': arguments['autoplay'] != false,
        'currentTime': (arguments['positionMs'] as num? ?? 0) / 1000,
        'media': {
          'contentId': _contentId,
          'contentType': item['mimeType'],
          'streamType': _isLive ? 'LIVE' : 'BUFFERED',
          if (!_isLive && item['durationMs'] is num)
            'duration': (item['durationMs'] as num) / 1000,
          'customData': {'ppplayerItemId': _itemId},
          'metadata': {
            'metadataType': item['isVideo'] == true ? 1 : 3,
            'title': item['title'] ?? '',
            if (item['artist'] != null) 'artist': item['artist'],
            if (item['album'] != null) 'albumName': item['album'],
            if (artwork != null &&
                const {'http', 'https'}.contains(artwork.scheme))
              'images': [
                {'url': artwork.toString()},
              ],
          },
        },
      }, requestId: id);
      if (response.payload['type'] != 'MEDIA_STATUS' ||
          _mediaSessionId == null ||
          _lastStatus == null ||
          _lastStatus?['idleReason'] == 'ERROR')
        throw StateError('Receiver did not accept the media.');
      debugPrint(
        '[DesktopCast] load accepted item=$_itemId mediaSession=$_mediaSessionId',
      );
      return {'success': true};
    } catch (error) {
      return {'success': false, 'error': error.toString()};
    } finally {
      if (_loadingRequest == id) _loadingRequest = null;
    }
  }

  Future<void> _command(
    String type,
    String sessionId,
    String itemId, [
    Map<String, dynamic> extra = const {},
  ]) async {
    _requireSession(sessionId, itemId);
    await _request(media, _transportId!, {
      'type': type,
      'mediaSessionId': _mediaSessionId,
      ...extra,
    });
  }

  @override
  Future<void> play({required String sessionId, required String itemId}) =>
      _command('PLAY', sessionId, itemId);
  @override
  Future<void> pause({required String sessionId, required String itemId}) =>
      _command('PAUSE', sessionId, itemId);
  @override
  Future<void> stop({required String sessionId, required String itemId}) =>
      _command('STOP', sessionId, itemId);
  @override
  Future<void> seek({
    required String sessionId,
    required String itemId,
    required Duration position,
  }) => _command('SEEK', sessionId, itemId, {
    'currentTime': position.inMilliseconds / 1000,
  });
  @override
  Future<void> setVolume({
    required String sessionId,
    required String itemId,
    required double volume,
  }) async {
    _requireSession(sessionId, itemId);
    await _request(receiver, 'receiver-0', {
      'type': 'SET_VOLUME',
      'volume': {'level': volume.clamp(0, 1)},
    });
  }

  @override
  Future<void> setMuted({
    required String sessionId,
    required String itemId,
    required bool muted,
  }) async {
    _requireSession(sessionId, itemId);
    await _request(receiver, 'receiver-0', {
      'type': 'SET_VOLUME',
      'volume': {'muted': muted},
    });
  }

  void _lost(String error) {
    _session('disconnected', error: error);
    unawaited(_close());
  }

  Future<void> _close() async {
    ++_generation;
    _timer?.cancel();
    _timer = null;
    _transportId = null;
    _receiverSessionId = null;
    _mediaSessionId = null;
    for (final request in _requests.values) {
      if (!request.isCompleted)
        request.completeError(StateError('Cast connection closed.'));
    }
    _requests.clear();
    _requestNamespaces.clear();
    final messages = _messages;
    _messages = null;
    final transport = _transport;
    _transport = null;
    await messages?.cancel();
    await transport?.close();
  }

  @override
  Future<void> disconnect({
    required String sessionId,
    required bool stopPlayback,
  }) async {
    if (sessionId != _sessionId) return;
    try {
      if (stopPlayback && _receiverSessionId != null) {
        await _request(receiver, 'receiver-0', {
          'type': 'STOP',
          'sessionId': _receiverSessionId,
        });
      }
    } finally {
      _session('disconnected');
      await _close();
      _sessionId = null;
      _itemId = null;
      _endpointId = null;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _close();
    await stopDiscovery();
    await _events.close();
  }
}
