import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';

import '../models.dart';
import '../network_output_backend.dart';
import 'dlna_device.dart';
import 'dlna_discovery.dart';
import 'dlna_soap_client.dart';

/// Polling interval while playing / paused.
const _kPollPlaying = Duration(milliseconds: 1000);
const _kPollPaused = Duration(seconds: 5);

/// DLNA implementation of [NetworkOutputBackend].
///
/// Responsibilities:
/// - SSDP discovery via [DlnaDiscovery]
/// - AVTransport load / play / pause / stop / seek
/// - RenderingControl volume / mute where supported
/// - Position polling (~1s while playing; ~5s while paused)
/// - Session + generation guards on every async result
/// - DIDL-Lite metadata construction (with proper XML escaping)
/// - Capability reporting derived from actual device services
class DlnaOutputBackend implements NetworkOutputBackend {
  DlnaOutputBackend({DlnaDiscovery? discovery, DlnaSoapClient? soapClient})
    : _discovery = discovery ?? DlnaDiscovery(),
      _soap = soapClient ?? DlnaSoapClient();

  final DlnaDiscovery _discovery;

  /// Exposed for diagnostics; do not start/stop from outside.
  DlnaDiscovery get discovery => _discovery;
  final DlnaSoapClient _soap;

  final _outputsController = StreamController<List<PlaybackOutput>>.broadcast();
  final _sessionController =
      StreamController<NetworkOutputSessionState>.broadcast();

  DlnaDevice? _device;
  String? _sessionId;
  String? _itemId;
  int _generation = 0;
  Timer? _pollTimer;
  bool _polling = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1;
  bool _muted = false;
  bool _disposed = false;
  StreamSubscription<List<DlnaDevice>>? _discoverySub;
  StreamSubscription<String>? _errorSub;

  void _log(String msg) => debugPrint('[Output] dlna $msg');

  // ── Interface ────────────────────────────────────────────────────────

  @override
  OutputKind get kind => OutputKind.dlna;

  @override
  Stream<List<PlaybackOutput>> get outputs => _outputsController.stream;

  @override
  Stream<NetworkOutputSessionState> get sessionState =>
      _sessionController.stream;

  // ── Discovery ────────────────────────────────────────────────────────

  @override
  Future<void> startDiscovery() async {
    _discoverySub ??= _discovery.devices.listen((devices) {
      if (!_outputsController.isClosed) {
        _outputsController.add(devices.map((d) => d.output).toList());
      }
    });
    _errorSub ??= _discovery.errors.listen(_log);
    await _discovery.start();
    _log('discovery.start');
  }

  @override
  Future<void> stopDiscovery() async {
    await _discovery.stop();
    _discoverySub?.cancel();
    _discoverySub = null;
    _errorSub?.cancel();
    _errorSub = null;
    _log('discovery.stop');
  }

  // ── Connect / Disconnect ─────────────────────────────────────────────

  @override
  Future<void> connect(
    PlaybackOutput output, {
    required String sessionId,
  }) async {
    _stopPolling();
    final device = _discovery.device(output.id);
    if (device == null) {
      throw NetworkOutputException(
        'The device "${output.name}" could not be found on the network.',
        code: 'device_not_found',
      );
    }
    final generation = ++_generation;
    _device = device;
    _sessionId = sessionId;
    _itemId = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _volume = 1;
    _muted = false;
    _log('connect.start id=${output.id} session=$sessionId');

    final transport = device.transport;
    if (transport == null) {
      throw NetworkOutputException(
        '"${output.name}" does not support AVTransport.',
        code: 'no_av_transport',
      );
    }
    // Ping to verify connectivity. Renderers in STOPPED state sometimes
    // return an error code from GetTransportInfo — treat those as OK.
    try {
      await _soap
          .invoke(transport, 'GetTransportInfo', {'InstanceID': '0'})
          .timeout(const Duration(seconds: 8));
    } on DlnaActionException {
      // renderer returned a SOAP fault but is reachable.
    } catch (e) {
      throw NetworkOutputException(
        'Could not connect to "${output.name}": ${_friendlyError(e)}',
        code: 'connect_failed',
      );
    }
    if (_generation != generation) return; // superseded
    _log('connect.ready id=${output.id}');
  }

  @override
  Future<void> disconnect({
    required String sessionId,
    required bool stopPlayback,
  }) async {
    if (_sessionId != sessionId) {
      _log('stale_event_ignored disconnect session=$sessionId');
      return;
    }
    _stopPolling();
    final device = _device;
    ++_generation;
    _device = null;
    _sessionId = null;
    _itemId = null;

    if (stopPlayback && device != null) {
      try {
        final transport = device.transport;
        if (transport != null) {
          await _soap
              .invoke(transport, 'Stop', {'InstanceID': '0'})
              .timeout(const Duration(seconds: 5));
        }
      } catch (_) {}
    }
    _log('disconnect stop=$stopPlayback');
  }

  // ── Load ─────────────────────────────────────────────────────────────

  @override
  Future<RemoteLoadResult> load(
    NetworkMediaItem item, {
    required String sessionId,
    required String itemId,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async {
    _guardSession(sessionId);
    final device = _device!;
    final transport = _requireTransport(device);
    final generation = _generation;

    _itemId = itemId;
    _log('load.start mime=${item.mimeType} session=$sessionId item=$itemId');

    final didl = _buildDidl(item);

    try {
      await _soap
          .invoke(transport, 'SetAVTransportURI', {
            'InstanceID': '0',
            'CurrentURI': item.uri.toString(),
            'CurrentURIMetaData': didl,
          })
          .timeout(const Duration(seconds: 10));
    } on DlnaActionException catch (e) {
      return RemoteLoadResult(
        success: false,
        error: _friendlyDlnaError(e, 'SetAVTransportURI'),
      );
    } catch (e) {
      return RemoteLoadResult(success: false, error: _friendlyError(e));
    }

    _guardGeneration(generation);

    // Seek before play when a non-zero start position was requested.
    if (!item.isLive && position > Duration.zero && device.capabilities.seek) {
      try {
        await _seekInternal(transport, position, generation);
      } catch (_) {
        // Seek failure at load time is non-fatal; start from the beginning.
      }
    }

    _guardGeneration(generation);

    if (autoplay) {
      try {
        await _soap
            .invoke(transport, 'Play', {'InstanceID': '0', 'Speed': '1'})
            .timeout(const Duration(seconds: 8));
      } on DlnaActionException catch (e) {
        return RemoteLoadResult(
          success: false,
          error: _friendlyDlnaError(e, 'Play'),
        );
      } catch (e) {
        return RemoteLoadResult(success: false, error: _friendlyError(e));
      }
    }

    _guardGeneration(generation);

    _playing = autoplay;
    _position = position;
    _duration = item.duration ?? Duration.zero;
    _startPolling(sessionId: sessionId, itemId: itemId);

    _log('load.complete session=$sessionId item=$itemId');
    return RemoteLoadResult(
      success: true,
      position: position,
      duration: item.duration,
      capabilities: device.capabilities,
    );
  }

  // ── Playback controls ────────────────────────────────────────────────

  @override
  Future<void> play({required String sessionId, required String itemId}) async {
    _guardSessionAndItem(sessionId, itemId);
    final transport = _requireTransport(_device!);
    final generation = _generation;
    await _soap
        .invoke(transport, 'Play', {'InstanceID': '0', 'Speed': '1'})
        .timeout(const Duration(seconds: 8));
    _guardGeneration(generation);
    _playing = true;
    _restartPollTimer(sessionId: sessionId, itemId: itemId);
    _log('remote.state playing');
  }

  @override
  Future<void> pause({
    required String sessionId,
    required String itemId,
  }) async {
    _guardSessionAndItem(sessionId, itemId);
    final transport = _requireTransport(_device!);
    final generation = _generation;
    await _soap
        .invoke(transport, 'Pause', {'InstanceID': '0'})
        .timeout(const Duration(seconds: 8));
    _guardGeneration(generation);
    _playing = false;
    _restartPollTimer(sessionId: sessionId, itemId: itemId);
    _log('remote.state paused');
  }

  @override
  Future<void> stop({required String sessionId, required String itemId}) async {
    _guardSessionAndItem(sessionId, itemId);
    final transport = _requireTransport(_device!);
    _stopPolling();
    await _soap
        .invoke(transport, 'Stop', {'InstanceID': '0'})
        .timeout(const Duration(seconds: 8));
    _playing = false;
    _log('remote.state stopped');
  }

  @override
  Future<void> seek(
    Duration position, {
    required String sessionId,
    required String itemId,
  }) async {
    _guardSessionAndItem(sessionId, itemId);
    final transport = _requireTransport(_device!);
    await _seekInternal(transport, position, _generation);
    _position = position;
    _log('seek position=${position.inSeconds}s');
  }

  Future<void> _seekInternal(
    DlnaService transport,
    Duration position,
    int generation,
  ) async {
    final hms = _formatHms(position);
    try {
      await _soap
          .invoke(transport, 'Seek', {
            'InstanceID': '0',
            'Unit': 'REL_TIME',
            'Target': hms,
          })
          .timeout(const Duration(seconds: 8));
    } on DlnaActionException catch (e) {
      if (e.code == 701 || e.code == 710 || e.code == 711) {
        throw NetworkOutputException(
          'This device does not support seeking: ${e.description}',
          code: 'unsupported_operation',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> setVolume(
    double volume, {
    required String sessionId,
    required String itemId,
  }) async {
    _guardSessionAndItem(sessionId, itemId);
    final rendering = _device?.rendering;
    if (rendering == null || !rendering.supports('SetVolume')) {
      throw NetworkOutputException(
        'This device does not support volume control.',
        code: 'unsupported_operation',
      );
    }
    final pct = (volume * 100).round().clamp(0, 100).toString();
    await _soap
        .invoke(rendering, 'SetVolume', {
          'InstanceID': '0',
          'Channel': 'Master',
          'DesiredVolume': pct,
        })
        .timeout(const Duration(seconds: 5));
    _volume = volume;
    _log('volume=$pct%');
  }

  @override
  Future<void> setMute(
    bool muted, {
    required String sessionId,
    required String itemId,
  }) async {
    _guardSessionAndItem(sessionId, itemId);
    final rendering = _device?.rendering;
    if (rendering == null || !rendering.supports('SetMute')) {
      throw NetworkOutputException(
        'This device does not support mute control.',
        code: 'unsupported_operation',
      );
    }
    await _soap
        .invoke(rendering, 'SetMute', {
          'InstanceID': '0',
          'Channel': 'Master',
          'DesiredMute': muted ? '1' : '0',
        })
        .timeout(const Duration(seconds: 5));
    _muted = muted;
    _log('muted=$muted');
  }

  // ── Polling ───────────────────────────────────────────────────────────

  void _startPolling({required String sessionId, required String itemId}) {
    _stopPolling();
    _scheduleNextPoll(sessionId: sessionId, itemId: itemId);
  }

  void _restartPollTimer({required String sessionId, required String itemId}) {
    _stopPolling();
    _scheduleNextPoll(sessionId: sessionId, itemId: itemId);
  }

  void _scheduleNextPoll({required String sessionId, required String itemId}) {
    final interval = _playing ? _kPollPlaying : _kPollPaused;
    _pollTimer = Timer(interval, () {
      _executePoll(sessionId: sessionId, itemId: itemId);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _executePoll({
    required String sessionId,
    required String itemId,
  }) async {
    if (_polling || _disposed) return;
    if (_sessionId != sessionId || _itemId != itemId) return;
    final device = _device;
    final transport = device?.transport;
    if (device == null || transport == null) return;

    _polling = true;
    final generation = _generation;
    try {
      // ── GetTransportInfo ──────────────────────────────────────────
      Map<String, String> transportInfo;
      try {
        transportInfo = await _soap
            .invoke(transport, 'GetTransportInfo', {'InstanceID': '0'})
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        return; // network hiccup; retry on next interval
      }
      if (_generation != generation ||
          _sessionId != sessionId ||
          _itemId != itemId)
        return;

      final dlnaState = _parseTransportState(
        transportInfo['CurrentTransportState'] ?? '',
      );

      // ── GetPositionInfo ───────────────────────────────────────────
      Duration position = _position;
      Duration duration = _duration;
      try {
        final posInfo = await _soap
            .invoke(transport, 'GetPositionInfo', {'InstanceID': '0'})
            .timeout(const Duration(seconds: 6));
        if (_generation == generation &&
            _sessionId == sessionId &&
            _itemId == itemId) {
          position = _parseDlnaTime(posInfo['RelTime'] ?? '') ?? _position;
          duration =
              _parseDlnaTime(posInfo['TrackDuration'] ?? '') ?? _duration;
        }
      } catch (_) {}

      if (_generation != generation ||
          _sessionId != sessionId ||
          _itemId != itemId)
        return;

      _position = position;
      _duration = duration;
      _playing = dlnaState == PlaybackState.playing;

      _emitState(sessionId: sessionId, itemId: itemId, state: dlnaState);
    } finally {
      _polling = false;
      if (!_disposed &&
          _sessionId == sessionId &&
          _itemId == itemId &&
          _generation == generation) {
        _scheduleNextPoll(sessionId: sessionId, itemId: itemId);
      }
    }
  }

  void _emitState({
    required String sessionId,
    required String itemId,
    required PlaybackState state,
  }) {
    if (_sessionController.isClosed) return;
    final device = _device;
    if (device == null) return;
    _sessionController.add(
      NetworkOutputSessionState(
        endpointId: device.id,
        sessionId: sessionId,
        itemId: itemId,
        state: state,
        connected: true,
        position: _position,
        duration: _duration,
        volume: _volume,
        muted: _muted,
        capabilities: device.capabilities,
      ),
    );
  }

  // ── DIDL-Lite ─────────────────────────────────────────────────────────

  /// Escapes XML special characters to prevent metadata injection.
  static String _xmlEscape(String raw) => raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static String _buildDidl(NetworkMediaItem item) {
    final e = _xmlEscape;
    final sb = StringBuffer()
      ..write(
        '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">',
      )
      ..write('<item id="1" parentID="0" restricted="1">')
      ..write('<dc:title>${e(item.title)}</dc:title>');
    if (item.artist != null) {
      sb.write('<dc:creator>${e(item.artist!)}</dc:creator>');
    }
    if (item.album != null) {
      sb.write('<upnp:album>${e(item.album!)}</upnp:album>');
    }
    sb.write(
      '<upnp:class>'
      '${item.isVideo ? 'object.item.videoItem' : 'object.item.audioItem.musicTrack'}'
      '</upnp:class>',
    );
    if (item.artworkUri != null) {
      sb.write(
        '<upnp:albumArtURI dlna:profileID="JPEG_TN" '
        'xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">'
        '${e(item.artworkUri.toString())}</upnp:albumArtURI>',
      );
    }
    final proto = item.protocolInfo ?? 'http-get:*:${item.mimeType}:*';
    final durStr = item.duration != null && !item.isLive
        ? _formatHms(item.duration!)
        : '';
    sb.write('<res protocolInfo="${e(proto)}"');
    if (durStr.isNotEmpty) sb.write(' duration="$durStr"');
    sb.write('>${e(item.uri.toString())}</res>');
    sb.write('</item></DIDL-Lite>');
    return sb.toString();
  }

  // ── Time helpers ──────────────────────────────────────────────────────

  static String _formatHms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}'
        ':${m.toString().padLeft(2, '0')}'
        ':${s.toString().padLeft(2, '0')}';
  }

  /// Parses: HH:MM:SS, HH:MM:SS.fff, NOT_IMPLEMENTED, empty → null.
  static Duration? _parseDlnaTime(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == 'NOT_IMPLEMENTED') return null;
    final m = RegExp(r'^(\d+):(\d{2}):(\d{2})(?:[.,](\d+))?$').firstMatch(s);
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final sec = int.parse(m.group(3)!);
    final ms = m.group(4) != null
        ? int.parse(m.group(4)!.padRight(3, '0').substring(0, 3))
        : 0;
    return Duration(hours: h, minutes: min, seconds: sec, milliseconds: ms);
  }

  static PlaybackState _parseTransportState(String raw) =>
      switch (raw.toUpperCase()) {
        'PLAYING' => PlaybackState.playing,
        'PAUSED_PLAYBACK' => PlaybackState.paused,
        'TRANSITIONING' => PlaybackState.buffering,
        _ => PlaybackState.idle,
      };

  // ── Guards ────────────────────────────────────────────────────────────

  void _guardSession(String sessionId) {
    if (_sessionId != sessionId) {
      _log('stale_event_ignored session=$sessionId');
      throw NetworkOutputException(
        'Playback session is no longer active.',
        code: 'stale_session',
      );
    }
  }

  void _guardSessionAndItem(String sessionId, String itemId) {
    _guardSession(sessionId);
    if (_itemId != itemId) {
      _log('stale_event_ignored item=$itemId');
      throw NetworkOutputException(
        'Playback item is no longer active.',
        code: 'stale_item',
      );
    }
  }

  void _guardGeneration(int generation) {
    if (_generation != generation) throw _DlnaSuperseded();
  }

  DlnaService _requireTransport(DlnaDevice device) {
    final t = device.transport;
    if (t == null) {
      throw NetworkOutputException(
        'This device does not support AVTransport.',
        code: 'no_av_transport',
      );
    }
    return t;
  }

  // ── Error helpers ─────────────────────────────────────────────────────

  static String _friendlyDlnaError(DlnaActionException e, String action) {
    if (e.unsupported) return 'This device does not support "$action".';
    return 'The device rejected "$action" (code ${e.code}): ${e.description}';
  }

  static String _friendlyError(Object e) {
    if (e is DlnaActionException) return _friendlyDlnaError(e, e.action);
    if (e is NetworkOutputException) return e.message;
    if (e is TimeoutException) return 'The device did not respond in time.';
    return 'A network error occurred.';
  }

  // ── Dispose ───────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopPolling();
    _discoverySub?.cancel();
    _errorSub?.cancel();
    await _discovery.dispose();
    _soap.dispose();
    await _outputsController.close();
    await _sessionController.close();
    _log('disposed');
  }
}

class _DlnaSuperseded implements Exception {}
