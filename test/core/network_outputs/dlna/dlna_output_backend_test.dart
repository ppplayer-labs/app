import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/dlna/dlna_device.dart';
import 'package:ppplayer/core/network_outputs/dlna/dlna_discovery.dart';
import 'package:ppplayer/core/network_outputs/dlna/dlna_output_backend.dart';
import 'package:ppplayer/core/network_outputs/dlna/dlna_soap_client.dart';
import 'package:ppplayer/core/network_outputs/models.dart';

// ── Stub doubles ──────────────────────────────────────────────────────────

class _StubDiscovery extends DlnaDiscovery {
  final _ctrl = StreamController<List<DlnaDevice>>.broadcast();
  bool started = false;
  bool stopped = false;
  final _knownDevices = <String, DlnaDevice>{};

  @override
  Stream<List<DlnaDevice>> get devices => _ctrl.stream;
  @override
  List<DlnaDevice> get current => _knownDevices.values.toList();
  @override
  DlnaDevice? device(String id) => _knownDevices[id];

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> dispose() async {
    await _ctrl.close();
    await super.dispose();
  }

  void emit(List<DlnaDevice> devices) {
    for (final d in devices) {
      _knownDevices[d.id] = d;
    }
    _ctrl.add(List.unmodifiable(_knownDevices.values));
  }
}

class _StubSoapClient extends DlnaSoapClient {
  final List<String> invokedActions = [];
  Exception? failWith;

  @override
  Future<Map<String, String>> invoke(
    DlnaService service,
    String action,
    Map<String, Object> arguments,
  ) async {
    if (failWith != null) throw failWith!;
    invokedActions.add(action);
    return const {};
  }

  @override
  void dispose() {}
}

// ── Helpers ───────────────────────────────────────────────────────────────

DlnaDevice _fakeRenderer() {
  const xml = '''<?xml version="1.0"?>
<root>
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>FakeRenderer</friendlyName>
    <UDN>urn:uuid:fake-0001</UDN>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <controlURL>/AVTransport/ctrl</controlURL>
        <SCPDURL>/AVTransport/scpd</SCPDURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
        <controlURL>/RenderingControl/ctrl</controlURL>
        <SCPDURL>/RenderingControl/scpd</SCPDURL>
      </service>
    </serviceList>
  </device>
</root>''';
  return DlnaDevice.fromDescription(
    xml,
    Uri.parse('http://192.168.1.100:1234/desc.xml'),
  ).first;
}

PlaybackOutput _fakeOutput(DlnaDevice device) => PlaybackOutput(
  id: device.id,
  name: device.name,
  kind: OutputKind.dlna,
  endpointUri: device.descriptionUri,
  capabilities: device.capabilities,
);

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('DlnaOutputBackend', () {
    late _StubDiscovery discovery;
    late _StubSoapClient soap;
    late DlnaOutputBackend backend;

    setUp(() {
      discovery = _StubDiscovery();
      soap = _StubSoapClient();
      backend = DlnaOutputBackend(discovery: discovery, soapClient: soap);
    });

    tearDown(() async => backend.dispose());

    // ── kind ─────────────────────────────────────────────────────────────

    test('kind is dlna', () => expect(backend.kind, OutputKind.dlna));

    // ── discovery lifecycle ───────────────────────────────────────────────

    test('startDiscovery delegates to DlnaDiscovery.start()', () async {
      await backend.startDiscovery();
      expect(discovery.started, isTrue);
    });

    test('stopDiscovery delegates to DlnaDiscovery.stop()', () async {
      await backend.startDiscovery();
      await backend.stopDiscovery();
      expect(discovery.stopped, isTrue);
    });

    // ── outputs stream ────────────────────────────────────────────────────

    test('outputs stream emits when discovery publishes devices', () async {
      await backend.startDiscovery(); // wires _discoverySub
      final emission = backend.outputs.first;
      discovery.emit([_fakeRenderer()]);
      final list = await emission.timeout(const Duration(seconds: 2));
      expect(list, hasLength(1));
      expect(list.first.name, 'FakeRenderer');
      expect(list.first.kind, OutputKind.dlna);
    });

    // ── connect ───────────────────────────────────────────────────────────

    test('connect succeeds when device is known to discovery', () async {
      final device = _fakeRenderer();
      discovery.emit([device]);

      // connect performs a GetTransportInfo ping — stub returns {}
      await expectLater(
        backend.connect(_fakeOutput(device), sessionId: 'sess-1'),
        completes,
      );
      expect(soap.invokedActions, contains('GetTransportInfo'));
    });

    test('connect throws when device is not in discovery', () async {
      final device = _fakeRenderer();
      final output = _fakeOutput(device);
      // discovery.emit not called → _StubDiscovery.device returns null

      expect(
        () => backend.connect(output, sessionId: 'sess-1'),
        throwsA(
          isA<NetworkOutputException>().having(
            (e) => e.code,
            'code',
            'device_not_found',
          ),
        ),
      );
    });

    test('connect throws when SOAP ping fails with network error', () async {
      final device = _fakeRenderer();
      discovery.emit([device]);
      soap.failWith = Exception('network timeout');

      await expectLater(
        backend.connect(_fakeOutput(device), sessionId: 'sess-1'),
        throwsA(
          isA<NetworkOutputException>().having(
            (e) => e.code,
            'code',
            'connect_failed',
          ),
        ),
      );
    });

    // ── disconnect ────────────────────────────────────────────────────────

    test(
      'disconnect with active sessionId calls Stop when stopPlayback=true',
      () async {
        final device = _fakeRenderer();
        discovery.emit([device]);
        await backend.connect(_fakeOutput(device), sessionId: 'sess-2');
        soap.invokedActions.clear();

        await backend.disconnect(sessionId: 'sess-2', stopPlayback: true);
        expect(soap.invokedActions, contains('Stop'));
      },
    );

    test('disconnect with stale sessionId is silently ignored', () async {
      await expectLater(
        backend.disconnect(sessionId: 'stale', stopPlayback: false),
        completes,
      );
    });

    // ── session guard ─────────────────────────────────────────────────────

    test(
      'play with stale sessionId throws NetworkOutputException(stale_session)',
      () async {
        await expectLater(
          backend.play(sessionId: 'stale', itemId: 'item-1'),
          throwsA(
            isA<NetworkOutputException>().having(
              (e) => e.code,
              'code',
              'stale_session',
            ),
          ),
        );
      },
    );

    test(
      'pause with stale sessionId throws NetworkOutputException(stale_session)',
      () async {
        await expectLater(
          backend.pause(sessionId: 'stale', itemId: 'item-1'),
          throwsA(
            isA<NetworkOutputException>().having(
              (e) => e.code,
              'code',
              'stale_session',
            ),
          ),
        );
      },
    );

    test(
      'stop with stale sessionId throws NetworkOutputException(stale_session)',
      () async {
        await expectLater(
          backend.stop(sessionId: 'stale', itemId: 'item-1'),
          throwsA(
            isA<NetworkOutputException>().having(
              (e) => e.code,
              'code',
              'stale_session',
            ),
          ),
        );
      },
    );

    // ── dispose safety ────────────────────────────────────────────────────

    test('dispose twice does not throw', () async {
      await backend.dispose();
      await expectLater(backend.dispose(), completes);
    });

    test('startDiscovery after dispose is a no-op', () async {
      await backend.dispose();
      await expectLater(backend.startDiscovery(), completes);
    });
  });

  group('DlnaDevice.capabilities', () {
    test('renderer without sinkProtocolInfo reports live=false', () {
      expect(_fakeRenderer().capabilities.live, isFalse);
    });

    test('OutputCapabilities with audio+video+play+pause enabled', () {
      const caps = OutputCapabilities(
        audio: true,
        video: true,
        play: true,
        pause: true,
        stop: true,
      );
      expect(caps.audio, isTrue);
      expect(caps.video, isTrue);
      expect(caps.play, isTrue);
      expect(caps.pause, isTrue);
    });

    test('supportsMimeType wildcard matches any mime', () {
      const caps = OutputCapabilities(mimeTypes: {'*/*'});
      expect(caps.supportsMimeType('audio/mpeg'), isTrue);
      expect(caps.supportsMimeType('video/mp4'), isTrue);
    });

    test('supportsMimeType returns false for unmatched type', () {
      const caps = OutputCapabilities(mimeTypes: {'audio/mpeg'});
      expect(caps.supportsMimeType('video/mp4'), isFalse);
    });
  });

  group('DlnaDevice.fromDescription', () {
    test('parses friendly name and UDN correctly', () {
      final device = _fakeRenderer();
      expect(device.name, 'FakeRenderer');
      expect(device.id, 'urn:uuid:fake-0001');
    });

    test('exposes AVTransport and RenderingControl services', () {
      final device = _fakeRenderer();
      expect(device.transport, isNotNull);
      expect(device.rendering, isNotNull);
    });

    test('rejects URLBase pointing to a different host', () {
      const xml = '''<?xml version="1.0"?>
<root>
  <URLBase>http://evil.host/</URLBase>
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>BadDevice</friendlyName>
    <UDN>urn:uuid:bad</UDN>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <controlURL>/ctrl</controlURL>
        <SCPDURL>/scpd</SCPDURL>
      </service>
    </serviceList>
  </device>
</root>''';
      expect(
        () => DlnaDevice.fromDescription(
          xml,
          Uri.parse('http://192.168.1.100:1234/desc.xml'),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
