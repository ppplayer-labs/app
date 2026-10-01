import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/local_library/local_library_service.dart';
import 'package:ppplayer/core/local_library/managed_local_file_store.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/network_outputs/local_media_server.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';
import 'package:ppplayer/core/playback/local_file_playback_controller.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import '../network_outputs/network_output_controller_test.dart'
    show FakePlaybackController;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory documents;
  late ManagedLocalFileStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ios_persistence_');
    documents = await Directory('${root.path}/Documents').create();
    store = ManagedLocalFileStore(documentsDirectory: () async => documents);
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'iOS import -> delete picker copy -> reopen DB and queue -> play; survives sandbox relocation',
    () async {
      final picker = await File(
        '${root.path}/picked song ç.mp3',
      ).writeAsString('audio');
      final databaseFile = File('${root.path}/library.sqlite');
      var db = AppDatabase.forTesting(
        drift.DatabaseConnection(NativeDatabase(databaseFile)),
      );
      final imported = await LocalLibraryService(
        db,
        platform: TargetPlatform.iOS,
        managedStore: store,
      ).importFilesByPaths([picker.path]);
      expect(imported, hasLength(1));
      final serializedQueueTrack = imported.single.toJson();
      final originalLocator = imported.single.localFilePath!;
      expect(originalLocator, startsWith('pp-local:'));
      expect(
        (await db.getLocalFile(imported.single.spotifyId))!.mechanism,
        'managedCopy',
      );
      expect(imported.single.name, 'picked song ç');
      await picker.delete();
      await db.close();
      // The persisted library survives a process restart and sandbox relocation.
      documents = await documents.rename('${root.path}/relocatedDocuments');
      db = AppDatabase.forTesting(
        drift.DatabaseConnection(NativeDatabase(databaseFile)),
      );
      final restored = Track.fromJson(serializedQueueTrack);
      expect(
        (await db.getLocalFile(restored.spotifyId))!.locator,
        originalLocator,
      );
      final engine = FakePlaybackController();
      final controller = LocalFilePlaybackController(
        engine,
        acquireFileLease: (track) async {
          final path = await store.resolve(track.localMediaUri!);
          return AuthorizedFileLease(
            canonicalPath: await File(path).resolveSymbolicLinks(),
          );
        },
      );
      try {
        await controller.prepare(
          restored.toPlaybackTrack(),
          position: const Duration(seconds: 5),
        );
        expect(engine.loadedTrack!.localMediaUri, startsWith('file:'));
        expect(
          await File.fromUri(
            Uri.parse(engine.loadedTrack!.localMediaUri!),
          ).readAsString(),
          'audio',
        );
        expect(controller.currentStatus.track!.localMediaUri, originalLocator);
        await controller.play(restored.toPlaybackTrack());
        expect(controller.currentStatus.state, PlaybackState.playing);
      } finally {
        await controller.dispose();
        await db.close();
      }
    },
  );

  test('imports with the same name never overwrite one another', () async {
    final first = await File('${root.path}/a.mp3').writeAsString('first');
    final second = await File('${root.path}/b.mp3').writeAsString('second');
    final a = await store.importFile(first.path, 'song.mp3');
    final b = await store.importFile(second.path, 'song.mp3');
    expect(a, isNot(b));
    expect(await File(await store.resolve(a)).readAsString(), 'first');
    expect(await File(await store.resolve(b)).readAsString(), 'second');
  });

  test('managed locator rejects traversal', () async {
    await expectLater(
      store.resolve('pp-local:/local_music/%2E%2E/secrets'),
      throwsFormatException,
    );
  });

  test(
    'external bookmark opens resolved URI; pause retains scope, stop releases after reader stops',
    () async {
      const bookmark = 'Ym9va21hcms=';
      final file = await File(
        '${root.path}/external.mp3',
      ).writeAsString('audio');
      final engine = FakePlaybackController();
      final calls = <String>[];
      const channel = MethodChannel('com.ppplayer.app/local_files');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'resolveBookmark') return file.path;
            expect(engine.stopped, isTrue);
            return null;
          });
      final controller = LocalFilePlaybackController(
        engine,
        acquireFileLease: acquireAppleOutputFileLease,
      );
      try {
        await controller.play(
          const PlaybackTrack(
            id: 'local:external',
            title: 'External',
            sourceType: PlaybackSourceType.local,
            localMediaUri: bookmark,
          ),
        );
        expect(
          engine.loadedTrack!.localMediaUri,
          Uri.file(await file.resolveSymbolicLinks()).toString(),
        );
        expect(controller.currentStatus.track!.localMediaUri, bookmark);
        await controller.pause();
        expect(calls, ['resolveBookmark']);
        engine.stopped = false;
        await controller.stop();
        expect(calls, ['resolveBookmark', 'stopBookmarkAccess']);
      } finally {
        await controller.dispose();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
}
