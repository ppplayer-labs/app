import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/network_outputs/cast/cast_output_backend.dart';
import 'package:ppplayer/core/network_outputs/cast/desktop_cast_platform_client.dart';
import 'package:ppplayer/core/network_outputs/cast/desktop_cast_transport.dart';
import 'package:ppplayer/core/network_outputs/local_media_server.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/network_outputs/network_media_factory.dart';
import 'package:ppplayer/core/network_outputs/network_output_controller.dart';

import 'network_output_controller_test.dart' show FakePlaybackController;

class ReceiverTransport implements DesktopCastTransport {
  final input = StreamController<DesktopCastMessage>.broadcast();
  final sent =
      <
        ({String namespace, String destination, Map<String, dynamic> payload})
      >[];
  String? host;
  int? port;
  String? reject;
  int mediaId = 0;
  Map<String, dynamic>? currentMedia;
  double position = 0;
  String playerState = 'PAUSED';
  Future<void> Function(String)? readMedia;
  bool closed = false;

  @override
  Stream<DesktopCastMessage> get messages => input.stream;
  @override
  Future<void> connect(String host, int port) async {
    this.host = host;
    this.port = port;
  }

  void emit(String namespace, String source, Map<String, dynamic> payload) {
    input.add(DesktopCastMessage(namespace, source, payload));
  }

  Map<String, dynamic> status() => {
    'mediaSessionId': mediaId,
    'playerState': playerState,
    'currentTime': position,
    'media': currentMedia,
  };

  @override
  void send(
    String namespace,
    String destination,
    Map<String, dynamic> payload,
  ) {
    sent.add((
      namespace: namespace,
      destination: destination,
      payload: payload,
    ));
    unawaited(
      Future<void>(() async {
        final type = payload['type'];
        if (type == 'CONNECT' || type == 'CLOSE' || type == 'PONG') return;
        if (type == 'PING') {
          emit(namespace, destination, {'type': 'PONG'});
          return;
        }
        if (type == reject) {
          emit(namespace, destination, {
            'type': type == 'LAUNCH' ? 'LAUNCH_ERROR' : 'LOAD_FAILED',
            'requestId': payload['requestId'],
          });
          return;
        }
        if (namespace == DesktopCastPlatformClient.receiver) {
          emit(namespace, destination, {
            'type': 'RECEIVER_STATUS',
            'requestId': payload['requestId'],
            'status': {
              'volume': payload['volume'] ?? {'level': 0.6, 'muted': false},
              'applications': [
                {
                  'appId': DesktopCastPlatformClient.appId,
                  'transportId': 'receiver-transport',
                  'sessionId': 'receiver-session',
                },
              ],
            },
          });
          return;
        }
        if (type == 'LOAD') {
          currentMedia = Map<String, dynamic>.from(payload['media'] as Map);
          ++mediaId;
          position = (payload['currentTime'] as num).toDouble();
          playerState = payload['autoplay'] == true ? 'PLAYING' : 'PAUSED';
          await readMedia?.call(currentMedia!['contentId'] as String);
        } else if (type == 'PLAY') {
          playerState = 'PLAYING';
        } else if (type == 'PAUSE') {
          playerState = 'PAUSED';
        } else if (type == 'STOP') {
          playerState = 'IDLE';
        } else if (type == 'SEEK') {
          position = (payload['currentTime'] as num).toDouble();
        }
        emit(namespace, destination, {
          'type': 'MEDIA_STATUS',
          'requestId': payload['requestId'],
          'status': [status()],
        });
      }),
    );
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!input.isClosed) await input.close();
  }
}

Map<String, dynamic> loadArguments(
  String itemId, {
  String uri = 'http://192.168.1.2/song.mp3',
}) => {
  'sessionId': 'session',
  'itemId': itemId,
  'autoplay': false,
  'positionMs': 12000,
  'item': {
    'uri': uri,
    'mimeType': 'audio/mpeg',
    'title': 'Local song',
    'artist': 'Artist',
    'durationMs': 60000,
    'isLive': false,
    'artworkUri': 'file:///private/artwork.jpg',
  },
};

void main() {
  late ReceiverTransport transport;
  late DesktopCastPlatformClient client;
  late StreamController<dynamic> discovery;
  late List<Map> events;

  setUp(() async {
    HttpOverrides.global = null;
    transport = ReceiverTransport();
    discovery = StreamController<dynamic>.broadcast();
    client = DesktopCastPlatformClient(
      discoveryEvents: discovery.stream,
      discoveryControl: (_) async {},
      transportFactory: () => transport,
      requestTimeout: const Duration(milliseconds: 500),
      pollInterval: const Duration(hours: 1),
    );
    events = [];
    final sub = client.events.listen((event) => events.add(event as Map));
    addTearDown(() async {
      await sub.cancel();
      await client.dispose();
      await discovery.close();
    });
    await client.startDiscovery();
    discovery.add({
      'devices': [
        {
          'id': 'cast-device',
          'name': 'Living Room',
          'host': 'living-room.local.',
          'port': 8009,
          'audio': true,
          'video': true,
        },
      ],
    });
    await Future<void>.delayed(Duration.zero);
  });

  Future<void> connect() =>
      client.connect(endpointId: 'cast-device', sessionId: 'session');

  test(
    'Bonjour endpoint launches default receiver and opens app transport',
    () async {
      await connect();
      expect(transport.host, 'living-room.local.');
      expect(transport.port, 8009);
      expect(transport.sent.first.payload['type'], 'CONNECT');
      expect(transport.sent[1].payload['appId'], 'CC1AD845');
      expect(transport.sent.last.destination, 'receiver-transport');
      await Future<void>.delayed(Duration.zero);
      expect(
        events.where((e) => e['event'] == 'session').map((e) => e['state']),
        ['connecting', 'connected'],
      );
    },
  );

  test(
    'LOAD confirms receiver media session, metadata, paused state and resume position',
    () async {
      await connect();
      expect((await client.load(loadArguments('item')))['success'], true);
      final load = transport.sent
          .firstWhere((m) => m.payload['type'] == 'LOAD')
          .payload;
      expect(load['currentTime'], 12);
      expect(load['autoplay'], false);
      final media = load['media'] as Map;
      expect(media['contentType'], 'audio/mpeg');
      expect((media['metadata'] as Map)['metadataType'], 3);
      expect((media['metadata'] as Map).containsKey('images'), false);
      await Future<void>.delayed(Duration.zero);
      final event = events.lastWhere((e) => e['event'] == 'status');
      expect(event['state'], 'paused');
      expect(event['positionMs'], 12000);
      expect(event['endpointId'], 'cast-device');
      expect(event['sessionId'], 'session');
      expect(event['itemId'], 'item');
    },
  );

  test(
    'play pause seek mute and volume use correct media and receiver channels',
    () async {
      await connect();
      await client.load(loadArguments('item'));
      await client.play(sessionId: 'session', itemId: 'item');
      await client.pause(sessionId: 'session', itemId: 'item');
      await client.seek(
        sessionId: 'session',
        itemId: 'item',
        position: const Duration(seconds: 25),
      );
      await client.setVolume(sessionId: 'session', itemId: 'item', volume: 0.4);
      await client.setMuted(sessionId: 'session', itemId: 'item', muted: true);
      final commands = transport.sent.where(
        (m) => const {'PLAY', 'PAUSE', 'SEEK'}.contains(m.payload['type']),
      );
      expect(
        commands.every(
          (m) =>
              m.destination == 'receiver-transport' &&
              m.payload['mediaSessionId'] == 1,
        ),
        true,
      );
      expect(transport.sent.last.namespace, DesktopCastPlatformClient.receiver);
      expect((transport.sent.last.payload['volume'] as Map)['muted'], true);
    },
  );

  test(
    'stale command identities and old receiver media statuses are rejected',
    () async {
      await connect();
      await client.load(loadArguments('first'));
      final old = transport.status();
      await client.load(
        loadArguments('second', uri: 'http://192.168.1.2/other.mp3'),
      );
      await expectLater(
        client.pause(sessionId: 'session', itemId: 'first'),
        throwsStateError,
      );
      await expectLater(
        client.play(sessionId: 'wrong-session', itemId: 'second'),
        throwsStateError,
      );
      await Future<void>.delayed(Duration.zero);
      final count = events.length;
      transport.emit(DesktopCastPlatformClient.media, 'receiver-transport', {
        'type': 'MEDIA_STATUS',
        'status': [old],
      });
      transport.emit(DesktopCastPlatformClient.media, 'different-receiver', {
        'type': 'MEDIA_STATUS',
        'status': [transport.status()],
      });
      await Future<void>.delayed(Duration.zero);
      expect(events.length, count);
    },
  );

  test(
    'invalid locator and rejected LOAD fail without reporting remote playback',
    () async {
      await connect();
      expect(
        (await client.load(
          loadArguments('item', uri: 'file:///song.mp3'),
        ))['success'],
        false,
      );
      transport.reject = 'LOAD';
      expect((await client.load(loadArguments('item')))['success'], false);
      expect(events.where((e) => e['event'] == 'status'), isEmpty);
    },
  );

  test(
    'launch failure closes transport and unavailable endpoint does not connect',
    () async {
      await expectLater(
        client.connect(endpointId: 'missing', sessionId: 'session'),
        throwsStateError,
      );
      transport.reject = 'LAUNCH';
      await expectLater(connect(), throwsStateError);
      expect(transport.closed, true);
    },
  );

  test(
    'socket loss carries active endpoint/session/item and marks backend disconnected',
    () async {
      final backend = CastOutputBackend(client: client);
      final states = <NetworkOutputSessionState>[];
      final sub = backend.sessionState.listen(states.add);
      addTearDown(() async {
        await sub.cancel();
        await backend.dispose();
      });
      await connect();
      await client.load(loadArguments('item'));
      await transport.input.close();
      await Future<void>.delayed(Duration.zero);
      final lost = states.last;
      expect(lost.connected, false);
      expect(lost.error, isNotNull);
      expect(lost.endpointId, 'cast-device');
      expect(lost.sessionId, 'session');
      expect(lost.itemId, 'item');
    },
  );

  test(
    'disconnect without stopping leaves receiver playback running',
    () async {
      await connect();
      await client.load(loadArguments('item'));
      await client.disconnect(sessionId: 'session', stopPlayback: false);
      expect(transport.sent.any((m) => m.payload['type'] == 'STOP'), false);
      expect(transport.closed, true);
    },
  );

  test(
    'local macOS file handoff serves HTTP bytes to receiver and pauses/resumes remotely',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'ppplayer-desktop-cast-',
      );
      final file = File('${dir.path}/song.mp3');
      await file.writeAsBytes([1, 2, 3, 4]);
      final server = LocalMediaServer(
        routeResolver: (_) async => InternetAddress.loopbackIPv4,
        allowLoopbackForTests: true,
      );
      final local = FakePlaybackController();
      final backend = CastOutputBackend(client: client);
      final controller = NetworkOutputController(
        localController: local,
        backends: [backend],
        mediaFactory: DefaultNetworkMediaFactory(server: server),
      );
      addTearDown(() async {
        await controller.dispose();
        await backend.dispose();
        await server.dispose();
        await dir.delete(recursive: true);
      });
      var served = false;
      transport.readMedia = (url) async {
        final http = HttpClient();
        try {
          final response = await (await http.getUrl(Uri.parse(url))).close();
          expect(response.statusCode, 200);
          expect(await response.expand((chunk) => chunk).toList(), [
            1,
            2,
            3,
            4,
          ]);
          served = true;
        } finally {
          http.close(force: true);
        }
      };
      await controller.play(
        PlaybackTrack(
          id: 'local-song',
          title: 'Local song',
          sourceType: PlaybackSourceType.local,
          localMediaUri: file.uri.toString(),
          duration: const Duration(minutes: 1),
        ),
      );
      await controller.selectOutput(
        const PlaybackOutput(
          id: 'cast-device',
          name: 'Living Room',
          kind: OutputKind.googleCast,
          capabilities: OutputCapabilities(
            audio: true,
            video: true,
            pause: true,
            seek: true,
            volume: true,
            mute: true,
            mimeTypes: {'*/*'},
          ),
        ),
      );
      expect(served, true);
      expect(local.paused, true);
      await Future<void>.delayed(Duration.zero);
      expect(controller.currentStatus.state, PlaybackState.playing);
      await controller.pause();
      await Future<void>.delayed(Duration.zero);
      expect(controller.currentStatus.state, PlaybackState.paused);
      await controller.resume();
      await Future<void>.delayed(Duration.zero);
      expect(controller.currentStatus.state, PlaybackState.playing);
      // Explicitly returning locally stops the receiver before lease release.
      await controller.selectOutput(PlaybackOutput.local);
      expect(transport.closed, true);
    },
  );
}
