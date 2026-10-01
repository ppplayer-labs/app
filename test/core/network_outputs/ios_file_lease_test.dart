import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/local_library/local_file_resolver.dart';
import 'package:ppplayer/core/network_outputs/cast/cast_output_backend.dart';
import 'package:ppplayer/core/network_outputs/cast/fake_cast_platform_client.dart';
import 'package:ppplayer/core/network_outputs/local_media_server.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/network_outputs/network_media_factory.dart';
import 'package:ppplayer/core/network_outputs/network_output_controller.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';

import 'network_output_controller_test.dart' show FakePlaybackController;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ppplayer.app/local_files');
  const bookmark = 'Ym9va21hcms=';
  late Directory temp;
  late File file;
  late LocalMediaServer server;
  late List<String> calls;
  String? error;

  PlaybackTrack track(String locator) => PlaybackTrack(
    id: 'ios-track',
    title: 'Local iOS file',
    sourceType: PlaybackSourceType.local,
    localMediaUri: locator,
    duration: const Duration(minutes: 1),
  );
  final output = PlaybackOutput(
    id: 'fake',
    name: 'Fake Cast',
    kind: OutputKind.googleCast,
    capabilities: const OutputCapabilities(
      audio: true,
      play: true,
      pause: true,
      stop: true,
      seek: true,
      mimeTypes: {'audio/mpeg'},
    ),
  );

  setUp(() async {
    HttpOverrides.global = null;
    calls = [];
    error = null;
    temp = await Directory.systemTemp.createTemp('ios_output_');
    file = await File(
      '${temp.path}/track.mp3',
    ).writeAsString('local audio bytes');
    server = LocalMediaServer(
      routeResolver: (_) async => InternetAddress.loopbackIPv4,
      allowLoopbackForTests: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.arguments['bookmark'], bookmark);
          calls.add(call.method);
          if (call.method == 'resolveBookmark') {
            if (error != null) throw PlatformException(code: error!);
            return file.path;
          }
          return null;
        });
  });
  tearDown(() async {
    await server.dispose();
    await temp.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> readMedia(Uri uri) async {
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(uri)).close();
      expect(response.statusCode, HttpStatus.ok);
      expect(
        await response.transform(const SystemEncoding().decoder).join(),
        'local audio bytes',
      );
    } finally {
      client.close(force: true);
    }
  }

  test(
    'production bookmark acquisition creates lease and HTTP URL; holds access until release',
    () async {
      final factory = DefaultNetworkMediaFactory(
        server: server,
        acquireFileLease: acquireAppleOutputFileLease,
      );
      final lease = await factory.prepare(
        track(bookmark),
        output,
        sessionId: 's',
        itemId: 'i',
      );
      expect(calls, ['resolveBookmark']);
      expect(server.isListening, isTrue);
      expect(lease.item.uri.scheme, 'http');
      await readMedia(lease.item.uri);
      await readMedia(lease.item.uri); // Receiver may request the file again.
      expect(calls, ['resolveBookmark']);
      await lease.release();
      await lease.release();
      expect(calls, ['resolveBookmark', 'stopBookmarkAccess']);
      expect(server.authorizedResourceCount, 0);
    },
  );

  test('file URI works unchanged without bookmark calls', () async {
    final lease = await DefaultNetworkMediaFactory(
      server: server,
      acquireFileLease: acquireAppleOutputFileLease,
    ).prepare(track(file.uri.toString()), output, sessionId: 's', itemId: 'i');
    await readMedia(lease.item.uri);
    await lease.release();
    expect(calls, isEmpty);
  });

  test(
    'invalid bookmark fails cleanly without server or native access',
    () async {
      await expectLater(
        acquireAppleOutputFileLease(track('not a bookmark!')),
        throwsUnsupportedError,
      );
      expect(calls, isEmpty);
      expect(server.isListening, isFalse);
    },
  );

  test(
    'revoked bookmark returns null publicly and fails cleanly at acquisition',
    () async {
      error = 'BOOKMARK_REVOKED';
      expect(await resolveSecurityScopedBookmark(bookmark), isNull);
      await expectLater(
        acquireAppleOutputFileLease(track(bookmark)),
        throwsUnsupportedError,
      );
      expect(calls, ['resolveBookmark', 'resolveBookmark']);
      expect(server.isListening, isFalse);
    },
  );

  test('canonicalization failure releases resolved bookmark', () async {
    await file.delete();
    await expectLater(
      acquireAppleOutputFileLease(track(bookmark)),
      throwsA(isA<FileSystemException>()),
    );
    expect(calls, ['resolveBookmark', 'stopBookmarkAccess']);
  });

  test(
    'expiry drains an accepted HTTP read before releasing security scope',
    () async {
      await server.dispose();
      var now = DateTime(2026);
      server = LocalMediaServer(
        routeResolver: (_) async => InternetAddress.loopbackIPv4,
        allowLoopbackForTests: true,
        clock: () => now,
        tokenLifetime: const Duration(seconds: 1),
      );
      await file.writeAsBytes(List.filled(32 * 1024 * 1024, 7));
      final lease = await server.authorizeFile(
        file: await acquireAppleOutputFileLease(track(bookmark)),
        renderer: Uri.parse('http://127.0.0.1'),
        mimeType: 'audio/mpeg',
      );
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(lease.uri)).close();
        now = now.add(const Duration(seconds: 2));
        final expiry = server.expireResources();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(calls, ['resolveBookmark']);
        final bytes = await response.fold<int>(
          0,
          (sum, chunk) => sum + chunk.length,
        );
        expect(bytes, 32 * 1024 * 1024);
        await expiry;
        expect(calls, ['resolveBookmark', 'stopBookmarkAccess']);
      } finally {
        client.close(force: true);
      }
    },
  );

  test('Local iOS bookmark -> Fake Cast -> LocalMediaServer handoff', () async {
    final local = FakePlaybackController();
    final fake = FakeCastPlatformClient();
    final backend = CastOutputBackend(client: fake);
    final controller = NetworkOutputController(
      localController: local,
      backends: [backend],
      mediaFactory: DefaultNetworkMediaFactory(
        server: server,
        acquireFileLease: acquireAppleOutputFileLease,
      ),
    );
    final events = <Map>[];
    final sub = fake.events.listen((event) => events.add(event as Map));
    try {
      await local.play(track(bookmark));
      await controller.selectOutput(output);
      await Future<void>.delayed(Duration.zero);
      expect(local.paused, isTrue);
      expect(controller.currentStatus.state, PlaybackState.playing);
      expect(controller.currentOutputState.selectedOutput.id, output.id);
      final sessions = events.where((e) => e['event'] == 'session').toList();
      expect(sessions.map((e) => e['state']), ['connecting', 'connected']);
      final statuses = events.where((e) => e['event'] == 'status').toList();
      expect(statuses.map((e) => e['state']), ['buffering', 'playing']);
      for (final e in statuses) {
        expect(e['endpointId'], output.id);
        expect(e['sessionId'], sessions.first['sessionId']);
        expect(e['itemId'], isNotEmpty);
        expect(e['itemId'], statuses.first['itemId']);
      }
      await readMedia(server.debugActiveUrls.single);
      expect(calls, ['resolveBookmark']);
      final count = events.length;
      await fake.pause(sessionId: 'stale', itemId: statuses.first['itemId']);
      await fake.stop(
        sessionId: statuses.first['sessionId'],
        itemId: 'wrong-item',
      );
      await Future<void>.delayed(Duration.zero);
      expect(events.length, count);
      expect(
        await fake.load({'sessionId': 'stale', 'itemId': 'i'}),
        containsPair('success', false),
      );
      print(
        '[Verification] bookmark resolved -> lease active -> HTTP 200 -> Fake Cast playing; endpoint/session/item matched',
      );
      await controller.disconnect(stopPlayback: true);
      expect(calls, ['resolveBookmark', 'stopBookmarkAccess']);
    } finally {
      await controller.dispose();
      await backend.dispose();
      await fake.dispose();
      await sub.cancel();
      await local.dispose();
    }
  });
}
