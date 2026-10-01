import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/local_library/local_file_resolver.dart';
import 'package:ppplayer/core/network_outputs/cast/cast_output_backend.dart';
import 'package:ppplayer/core/network_outputs/cast/fake_cast_platform_client.dart';
import 'package:ppplayer/core/network_outputs/local_media_server.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/network_outputs/network_media_factory.dart';
import 'package:ppplayer/core/network_outputs/network_output_controller.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';

import '../test/core/network_outputs/network_output_controller_test.dart'
    show FakePlaybackController;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native iOS bookmark -> Fake Cast -> HTTP receiver', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('output_bookmark_');
      final file = await File(
        '${temp.path}/track.mp3',
      ).writeAsString('native iOS audio');
      final server = LocalMediaServer(
        allowLoopbackForTests: true,
        routeResolver: (_) async => InternetAddress.loopbackIPv4,
      );
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
      final client = HttpClient();
      try {
        final bookmark = await createSecurityScopedBookmark(file.path);
        expect(bookmark, isNotNull);
        expect(bookmark, isNot(startsWith('file:')));
        await local.play(
          PlaybackTrack(
            id: 'ios-native',
            title: 'Native bookmark audio',
            sourceType: PlaybackSourceType.local,
            localMediaUri: bookmark,
            duration: const Duration(minutes: 1),
          ),
        );
        await controller.selectOutput(
          PlaybackOutput(
            id: 'fake-ios',
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
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.currentStatus.state, PlaybackState.playing);
        expect(local.paused, isTrue);
        expect(server.authorizedResourceCount, 1);
        final uri = server.debugActiveUrls.single;
        expect(uri.scheme, 'http');
        final response = await (await client.getUrl(uri)).close();
        expect(response.statusCode, HttpStatus.ok);
        expect(
          await response.transform(const SystemEncoding().decoder).join(),
          'native iOS audio',
        );
        print(
          '[Verification] native iOS bookmark resolved -> lease created -> HTTP 200 -> Fake Cast playing',
        );
        await controller.disconnect(stopPlayback: true);
        expect(server.authorizedResourceCount, 0);
        expect(server.isListening, isFalse);
        print('[Verification] receiver disconnected -> lease released');
      } finally {
        client.close(force: true);
        await controller.dispose();
        await backend.dispose();
        await fake.dispose();
        await local.dispose();
        await server.dispose();
        await temp.delete(recursive: true);
      }
    });
  }, skip: !Platform.isIOS);
}
