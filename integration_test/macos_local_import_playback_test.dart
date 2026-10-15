import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/local_library/local_library_service.dart';
import 'package:ppplayer/core/local_library/audio_format_registry.dart';
import 'package:ppplayer/core/local_library/local_track_source.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';
import 'package:ppplayer/core/playback/local_file_playback_controller.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';

Future<void> _fixture(String asset, String destination) async {
  final data = await rootBundle.load('assets/test_fixtures/$asset');
  final file = File(destination);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'macOS folder import (bookmark root) -> rescan -> playback of audio + video',
    (tester) async {
      // The production adapter shares one VideoController. libmpv/media_kit
      // only completes open() once a render target exists, which in the real
      // app is the mounted Video widget. Mount one for the headless test.
      MediaKit.ensureInitialized();
      final warm = MediaKitPlayerAdapter();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 240,
            child: Video(controller: warm.videoController!),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        final temp = await Directory.systemTemp.createTemp('macos_local_');
        final root = '${temp.path}/Biblioteca ñ';
        await _fixture('test.mp3', '$root/Música 日本語 – one.mp3');
        await _fixture('test.flac', '$root/sub dir/two.flac');
        await _fixture('test.m4a', '$root/sub dir/deep/three.m4a');
        await _fixture('test.wav', '$root/four.wav');
        await _fixture('test_video.mp4', '$root/video/clip one.mp4');
        await File('$root/notes.txt').writeAsString('not media');

        final dbFile = File('${temp.path}/library.sqlite');
        AppDatabase open() => AppDatabase.forTesting(
          drift.DatabaseConnection(NativeDatabase(dbFile)),
        );
        var db = open();
        LocalFilePlaybackController? controller;
        try {
          await LocalLibraryService(
            db,
          ).importFolderAtPath(root, scope: ImportMediaScope.both);

          final roots = await db.select(db.importRoots).get();
          expect(roots, hasLength(1));
          expect(
            roots.single.mechanism,
            TrackSourceType.iOsSecurityBookmark.name,
            reason: 'macOS root should be stored as a security-scoped bookmark',
          );

          var files = await db.select(db.localFiles).get();
          print('[Verification] imported ${files.length} files');
          for (final f in files) {
            print(
              '[Verification]   ${f.displayPath} video=${f.isVideo} '
              'status=${f.availabilityStatus}',
            );
          }
          expect(files, hasLength(5), reason: '4 audio + 1 video, no .txt');
          expect(files.where((f) => f.isVideo), hasLength(1));
          expect(
            files.singleWhere((f) => f.isVideo).displayPath,
            endsWith('clip one.mp4'),
          );

          // Rescan after DB reopen must resolve the persisted bookmark root and
          // must not duplicate records.
          await db.close();
          db = open();
          await LocalLibraryService(db).rescanLibrary();
          files = await db.select(db.localFiles).get();
          expect(files, hasLength(5), reason: 'rescan must not duplicate');

          controller = LocalFilePlaybackController(
            MediaKitPlaybackEngine(),
            acquireFileLease: acquireAppleOutputFileLease,
          );
          for (final f in files) {
            final track = (await db.getAppTrack(f.libraryId))!;
            final playing = controller.statusStream
                .firstWhere((s) => s.state == PlaybackState.playing)
                .timeout(const Duration(seconds: 20));
            await controller.play(track.toPlaybackTrack());
            final status = await playing;
            expect(status.track!.id, track.spotifyId);
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            expect(
              controller.currentStatus.position,
              greaterThan(Duration.zero),
              reason: '${f.displayPath} did not advance',
            );
            await controller.seekTo(const Duration(milliseconds: 500));
            await controller.pause();
            await controller.resume();
            print(
              '[Verification] played ${f.displayPath} isVideo=${f.isVideo}',
            );
          }
          await controller.stop();

          // Missing file: playback must fail cleanly, not crash/hang.
          final victim = files.firstWhere(
            (f) => f.displayPath.endsWith('four.wav'),
          );
          await File(victim.locator).delete();
          final victimTrack = (await db.getAppTrack(victim.libraryId))!;
          Object? error;
          try {
            await controller.play(victimTrack.toPlaybackTrack());
          } catch (e) {
            error = e;
          }
          print('[Verification] deleted-file playback -> $error');
          expect(error, isNotNull);
        } finally {
          await controller?.dispose();
          await db.close();
          await temp.delete(recursive: true);
        }
      });
    },
    skip: !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
