import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dlna_device.dart';
import 'dlna_soap_client.dart';
import 'package:flutter/foundation.dart';

class SsdpMessage {
  SsdpMessage(this.startLine, this.headers);
  final String startLine;
  final Map<String, String> headers;
  static SsdpMessage? parse(List<int> bytes) {
    if (bytes.length > 16384) return null;
    String value;
    try {
      value = utf8.decode(bytes);
    } catch (_) {
      return null;
    }
    final lines = value.split('\r\n');
    if (lines.isEmpty ||
        !(lines.first.startsWith('HTTP/1.1 200 ') ||
            lines.first == 'NOTIFY * HTTP/1.1'))
      return null;
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final separator = line.indexOf(':');
      if (separator < 1) continue;
      headers[line.substring(0, separator).toLowerCase()] = line
          .substring(separator + 1)
          .trim();
    }
    return SsdpMessage(lines.first, headers);
  }
}

/// IPv4 discovery is deliberately explicit. IPv6 needs scoped interface URLs
/// and route/serving support and is not advertised by V1.
class DlnaDiscovery {
  DlnaDiscovery({
    DlnaSoapClient? client,
    DateTime Function()? clock,
    this.searchInterval = const Duration(seconds: 8),
    this.allowLoopbackForTests = false,
  }) : _client = client ?? DlnaSoapClient(),
       _clock = clock ?? DateTime.now;
  final DlnaSoapClient _client;
  final DateTime Function() _clock;
  final Duration searchInterval;
  final bool allowLoopbackForTests;
  final _controller = StreamController<List<DlnaDevice>>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final _devices = <String, DlnaDevice>{};
  final _sourceUsns = <String, String>{};
  final _sockets = <RawDatagramSocket>[];
  final _pending = <String>{};
  final _queue = <(Uri, DateTime, String, int)>[];
  int _inFlight = 0;
  int _generation = 0;
  Timer? _search;
  Timer? _expiry;
  bool _running = false;
  bool _disposed = false;

  Stream<List<DlnaDevice>> get devices => _controller.stream;
  Stream<String> get errors => _errors.stream;
  List<DlnaDevice> get current => List.unmodifiable(_devices.values);
  DlnaDevice? device(String id) => _devices[id];
  bool get isRunning => _running;

  Future<void> start() async {
    if (_disposed) throw StateError('Discovery is disposed');
    if (_running) {
      search();
      return;
    }
    _running = true;
    debugPrint('[Output] discovery.start backend=dlna');
    final generation = ++_generation;
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    var opened = 0;
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (address.isLoopback || address.address == '0.0.0.0') continue;
        try {
          final socket = await RawDatagramSocket.bind(address, 0);
          if (!_running || generation != _generation) {
            socket.close();
            return;
          }
          socket.multicastHops = 2;
          // multicastInterface is deprecated (not implemented); binding to the
          // specific interface address already scopes multicast to this NIC.
          _listen(socket, generation);
          opened++;
        } catch (_) {
          _report(
            'Unable to scan a network interface. Check local network access and firewall.',
          );
        }
      }
    }
    if (!_running || generation != _generation) return;
    if (opened == 0) {
      _running = false;
      _report('DLNA discovery isn\'t available on this device.');
      return;
    }
    // NOTIFY/byebye is optional monitoring; M-SEARCH replies do not need this
    // shared port, so a firewall/another control point can only degrade updates.
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        1900,
        reuseAddress: true,
        reusePort: true,
      );
      if (!_running || generation != _generation) {
        socket.close();
        return;
      }
      for (final interface in interfaces) {
        try {
          socket.joinMulticast(InternetAddress('239.255.255.250'), interface);
        } catch (_) {}
      }
      _listen(socket, generation);
    } catch (_) {
      _report(
        'SSDP announcements unavailable; devices will expire or be detected by playback monitoring.',
      );
    }
    _expiry ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => expireDevices(),
    );
    search();
    _search = Timer.periodic(searchInterval, (_) => search());
  }

  void _listen(RawDatagramSocket socket, int generation) {
    _sockets.add(socket);
    socket.listen(
      (event) {
        if (event != RawSocketEvent.read || generation != _generation) return;
        Datagram? packet;
        while ((packet = socket.receive()) != null) {
          final current = packet!;
          final message = SsdpMessage.parse(current.data);
          if (message != null)
            ingest(message, sender: current.address, generation: generation);
        }
      },
      onError: (Object _) {
        _report('SSDP network socket failed. Reopen Output to scan again.');
      },
    );
  }

  void search() {
    if (!_running) return;
    final bytes = utf8.encode(
      'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\nMX: 2\r\nST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
      'USER-AGENT: PPPlayer/2 UPnP/1.1 PPPlayer/2\r\n\r\n',
    );
    for (final socket in _sockets.where((socket) => socket.port != 1900)) {
      for (var repeat = 0; repeat < 2; repeat++) {
        try {
          socket.send(bytes, InternetAddress('239.255.255.250'), 1900);
        } catch (_) {
          _report('SSDP search failed. Check network permission or firewall.');
        }
      }
    }
  }

  /// Public for deterministic packet/expiry tests. Production calls require the
  /// advertiser's address so LOCATION cannot point outside the responder host.
  void ingest(
    SsdpMessage message, {
    required InternetAddress sender,
    int? generation,
  }) {
    final activeGeneration = generation ?? _generation;
    if (_disposed || (generation != null && activeGeneration != _generation))
      return;
    final usn = (message.headers['usn'] ?? '').split('::').first;
    if (message.headers['nts'] == 'ssdp:byebye') {
      final gone = _devices.keys
          .where((id) => id == usn || _sourceUsns[id] == usn)
          .toList();
      for (final id in gone) {
        _devices.remove(id);
        _sourceUsns.remove(id);
      }
      if (gone.isNotEmpty) _publish();
      return;
    }
    final raw = message.headers['location'];
    if (raw == null || _pending.length >= 128) return;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.host != sender.address ||
        (sender.isLoopback && !allowLoopbackForTests))
      return;
    final ageMatch = RegExp(
      r'max-age\s*=\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(message.headers['cache-control'] ?? '');
    final age = (int.tryParse(ageMatch?.group(1) ?? '') ?? 180).clamp(1, 3600);
    final expires = _clock().add(Duration(seconds: age));
    final existing = _devices.values
        .where((device) => device.descriptionUri == uri)
        .toList();
    if (existing.isNotEmpty) {
      for (final device in existing) {
        device.expires = expires;
      }
      return;
    }
    if (!_pending.add(uri.toString())) return;
    _queue.add((uri, expires, usn, activeGeneration));
    _pump();
  }

  void _pump() {
    while (!_disposed && _inFlight < 4 && _queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      _inFlight++;
      unawaited(_fetch(job));
    }
  }

  Future<void> _fetch((Uri, DateTime, String, int) job) async {
    try {
      final discovered = DlnaDevice.fromDescription(
        await _client.getXml(job.$1),
        job.$1,
        expires: job.$2,
      );
      for (final device in discovered) {
        await _client.inspect(device);
        if (_disposed ||
            job.$4 != _generation ||
            !device.expires.isAfter(_clock()))
          return;
        if (_devices.length >= 128 && !_devices.containsKey(device.id)) return;
        _devices[device.id] = device;
        _sourceUsns[device.id] = job.$3;
      }
      if (job.$4 == _generation && !_disposed) _publish();
    } catch (_) {
      if (job.$4 == _generation)
        _report(
          'A renderer returned an invalid description or failed capability inspection.',
        );
    } finally {
      _pending.remove(job.$1.toString());
      _inFlight--;
      _pump();
    }
  }

  void expireDevices() {
    final gone = _devices.values
        .where((device) => !device.expires.isAfter(_clock()))
        .map((device) => device.id)
        .toList();
    for (final id in gone) {
      _devices.remove(id);
      _sourceUsns.remove(id);
    }
    if (gone.isNotEmpty) _publish();
  }

  void markUnavailable(String id) {
    if (_devices.remove(id) != null) {
      _sourceUsns.remove(id);
      _publish();
    }
  }

  void _publish() {
    if (!_controller.isClosed) _controller.add(current);
  }

  void _report(String error) {
    if (!_errors.isClosed) _errors.add(error);
  }

  Future<void> stop() async {
    if (_running) debugPrint('[Output] discovery.stop backend=dlna');
    _running = false;
    ++_generation;
    _search?.cancel();
    _search = null;
    for (final socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
    _queue.clear();
    _pending.clear();
    _client.cancelPending();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    _expiry?.cancel();
    _client.dispose();
    await _controller.close();
    await _errors.close();
  }
}
