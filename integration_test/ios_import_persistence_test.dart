import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/local_library/local_library_service.dart';
import 'package:ppplayer/core/local_library/managed_local_file_store.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';
import 'package:ppplayer/core/playback/local_file_playback_controller.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'iOS managed import survives picker deletion and DB reopen; native engine plays',
    (tester) async {
      await tester.runAsync(() async {
        final temp = await Directory.systemTemp.createTemp(
          'persistence_native_',
        );
        final fixture = await rootBundle.load('assets/test_fixtures/test.wav');
        final picked = await File('${temp.path}/persisted song.wav')
            .writeAsBytes(
              fixture.buffer.asUint8List(
                fixture.offsetInBytes,
                fixture.lengthInBytes,
              ),
            );
        final dbFile = File('${temp.path}/library.sqlite');
        var db = AppDatabase.forTesting(
          drift.DatabaseConnection(NativeDatabase(dbFile)),
        );
        String? locator;
        LocalFilePlaybackController? controller;
        try {
          final tracks = await LocalLibraryService(
            db,
          ).importFilesByPaths([picked.path]);
          expect(tracks, hasLength(1));
          final savedQueue = tracks.single.toJson();
          locator = tracks.single.localFilePath!;
          expect(locator, startsWith('pp-local:'));
          await picked.delete();
          await db.close();
          db = AppDatabase.forTesting(
            drift.DatabaseConnection(NativeDatabase(dbFile)),
          );
          final restored = Track.fromJson(savedQueue);
          expect((await db.getLocalFile(restored.spotifyId))!.locator, locator);
          controller = LocalFilePlaybackController(
            MediaKitPlaybackEngine(),
            acquireFileLease: acquireAppleOutputFileLease,
          );
          final playing = controller.statusStream
              .firstWhere((status) => status.state == PlaybackState.playing)
              .timeout(const Duration(seconds: 15));
          await controller.play(restored.toPlaybackTrack());
          final status = await playing;
          expect(status.track!.localMediaUri, locator);
          print(
            '[Verification] physical iOS import -> durable copy -> picker deleted -> DB/queue reopened -> native playback playing',
          );
          await controller.stop();
        } finally {
          await controller?.dispose();
          await db.close();
          if (locator != null) {
            final path = await ManagedLocalFileStore().resolve(locator);
            await File(path).parent.delete(recursive: true);
          }
          await temp.delete(recursive: true);
        }
      });
    },
    skip: !Platform.isIOS,
  );
}
