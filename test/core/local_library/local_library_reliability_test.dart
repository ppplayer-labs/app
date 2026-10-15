import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/local_library/local_library_service.dart';
import 'package:ppplayer/core/network_outputs/local_media_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ppplayer_reliability_');
    dbFile = File('${tempDir.path}/library.sqlite');
    db = AppDatabase.forTesting(
      drift.DatabaseConnection(NativeDatabase(dbFile)),
    );
  });

  tearDown(() async {
    await db.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Local Library Reliability — Folder Deduplication & Listing', () {
    test(
      'Reimporting the same folder uses canonical identity and prevents duplicate roots',
      () async {
        final folder = Directory('${tempDir.path}/MusicFolder');
        await folder.create();
        final song1 = File('${folder.path}/song1.mp3');
        await song1.writeAsString('audio-data-1');
        final song2 = File('${folder.path}/song2.mp3');
        await song2.writeAsString('audio-data-2');

        final service = LocalLibraryService(db);

        // First import
        await service.importFolderAtPath(folder.path);

        final initialRoots = await db.getAllImportRoots();
        expect(initialRoots, hasLength(1));
        final initialFiles = await db.getLocalFilesByImportRoot(
          initialRoots.first.rootLocator,
        );
        expect(initialFiles, hasLength(2));

        // Reimport using identical path
        await service.importFolderAtPath(folder.path);
        final afterRoots = await db.getAllImportRoots();
        expect(afterRoots, hasLength(1), reason: 'Duplicate root was created');

        // Reimport using trailing slash
        await service.importFolderAtPath('${folder.path}/');
        final afterTrailingSlash = await db.getAllImportRoots();
        expect(
          afterTrailingSlash,
          hasLength(1),
          reason: 'Trailing slash caused duplicate root',
        );

        final folders = await db.watchLocalFolders().first;
        expect(folders, hasLength(1));
        expect(folders.first.name, 'MusicFolder');
        expect(folders.first.trackCount, 2);
      },
    );

    test(
      'Existing duplicated roots in database are gracefully merged and can be deleted together',
      () async {
        final folder = Directory('${tempDir.path}/DuplicatesFolder');
        await folder.create();

        // Simulate 2 duplicate historical roots pointing to the same displayPath
        await db.upsertImportRoot(
          ImportRootsCompanion.insert(
            id: 'root-id-1',
            mechanism: 'absolutePath',
            rootLocator: '${folder.path}_loc1',
            displayPath: folder.path,
            addedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        );
        await db.upsertImportRoot(
          ImportRootsCompanion.insert(
            id: 'root-id-2',
            mechanism: 'absolutePath',
            rootLocator: '${folder.path}_loc2',
            displayPath: folder.path,
            addedAt: DateTime.now(),
          ),
        );

        final now = DateTime.now();

        // Add 1 file to loc1, 1 file to loc2
        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:file1',
            mechanism: 'absolutePath',
            locator: '${folder.path}/file1.mp3',
            displayPath: '${folder.path}/file1.mp3',
            deduplicationKey: 'key1',
            lastScannedAt: now,
            importRootLocator: drift.Value('${folder.path}_loc1'),
          ),
        );
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                spotifyId: 'local:file1',
                name: 'File 1',
                artistId: 'local',
                artistName: 'Artist',
              ),
            );

        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:file2',
            mechanism: 'absolutePath',
            locator: '${folder.path}/file2.mp3',
            displayPath: '${folder.path}/file2.mp3',
            deduplicationKey: 'key2',
            lastScannedAt: now,
            importRootLocator: drift.Value('${folder.path}_loc2'),
          ),
        );
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                spotifyId: 'local:file2',
                name: 'File 2',
                artistId: 'local',
                artistName: 'Artist',
              ),
            );

        // watchLocalFolders must merge them into a single folder with total count = 2
        final folders = await db.watchLocalFolders().first;
        expect(folders, hasLength(1));
        expect(folders.first.trackCount, 2);

        // getFolderAppTracks must retrieve tracks from both duplicate locators
        final tracksLoc1 = await db.getFolderAppTracks('${folder.path}_loc1');
        expect(tracksLoc1, hasLength(2));
        final tracksLoc2 = await db.getFolderAppTracks('${folder.path}_loc2');
        expect(tracksLoc2, hasLength(2));

        // Deleting either locator deletes both historical duplicates and their child files
        await db.deleteLocalFolder('${folder.path}_loc1');
        final rootsAfter = await db.getAllImportRoots();
        expect(rootsAfter, isEmpty);
        final filesAfter = await db.select(db.localFiles).get();
        expect(filesAfter, isEmpty);
      },
    );

    test(
      'watchLocalFolders displays audio-only, video-only, mixed, and empty folders',
      () async {
        final now = DateTime.now();

        // 1. Audio-only folder
        final audioDir = Directory('${tempDir.path}/AudioOnly');
        await audioDir.create();
        await db.upsertImportRoot(
          ImportRootsCompanion.insert(
            id: 'root-audio',
            mechanism: 'absolutePath',
            rootLocator: audioDir.path,
            displayPath: audioDir.path,
            addedAt: now,
          ),
        );
        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:audio1',
            mechanism: 'absolutePath',
            locator: '${audioDir.path}/song.mp3',
            displayPath: '${audioDir.path}/song.mp3',
            deduplicationKey: 'dedupe-audio',
            lastScannedAt: now,
            importRootLocator: drift.Value(audioDir.path),
            isVideo: const drift.Value(false),
          ),
        );

        // 2. Video-only folder
        final videoDir = Directory('${tempDir.path}/VideoOnly');
        await videoDir.create();
        await db.upsertImportRoot(
          ImportRootsCompanion.insert(
            id: 'root-video',
            mechanism: 'absolutePath',
            rootLocator: videoDir.path,
            displayPath: videoDir.path,
            addedAt: now,
          ),
        );
        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:video1',
            mechanism: 'absolutePath',
            locator: '${videoDir.path}/clip.mp4',
            displayPath: '${videoDir.path}/clip.mp4',
            deduplicationKey: 'dedupe-video1',
            lastScannedAt: now,
            importRootLocator: drift.Value(videoDir.path),
            isVideo: const drift.Value(true),
          ),
        );
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                spotifyId: 'local:video1',
                name: 'Clip',
                artistId: 'local',
                artistName: 'Director',
              ),
            );

        // 3. Mixed folder
        final mixedDir = Directory('${tempDir.path}/MixedMedia');
        await mixedDir.create();
        await db.upsertImportRoot(
          ImportRootsCompanion.insert(
            id: 'root-mixed',
            mechanism: 'absolutePath',
            rootLocator: mixedDir.path,
            displayPath: mixedDir.path,
            addedAt: now,
          ),
        );
        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:mixed-audio',
            mechanism: 'absolutePath',
            locator: '${mixedDir.path}/track.flac',
            displayPath: '${mixedDir.path}/track.flac',
            deduplicationKey: 'dedupe-flac',
            lastScannedAt: now,
            importRootLocator: drift.Value(mixedDir.path),
            isVideo: const drift.Value(false),
          ),
        );
        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:mixed-video',
            mechanism: 'absolutePath',
            locator: '${mixedDir.path}/concert.mkv',
            displayPath: '${mixedDir.path}/concert.mkv',
            deduplicationKey: 'dedupe-mkv',
            lastScannedAt: now,
            importRootLocator: drift.Value(mixedDir.path),
            isVideo: const drift.Value(true),
          ),
        );

        // 4. Empty folder
        final emptyDir = Directory('${tempDir.path}/EmptyFolder');
        await emptyDir.create();
        await db.upsertImportRoot(
          ImportRootsCompanion.insert(
            id: 'root-empty',
            mechanism: 'absolutePath',
            rootLocator: emptyDir.path,
            displayPath: emptyDir.path,
            addedAt: now,
          ),
        );

        // 5. Standalone imported file (importRootLocator is null)
        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:standalone',
            mechanism: 'absolutePath',
            locator: '${tempDir.path}/standalone.mp3',
            displayPath: 'standalone.mp3',
            deduplicationKey: 'dedupe-standalone',
            lastScannedAt: now,
            importRootLocator: const drift.Value(null),
          ),
        );
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                spotifyId: 'local:standalone',
                name: 'Standalone',
                artistId: 'local',
                artistName: 'Artist',
              ),
            );

        final folders = await db.watchLocalFolders().first;
        expect(folders, hasLength(5));

        final names = folders.map((f) => f.name).toSet();
        expect(names, contains('Imported Files'));
        expect(names, contains('AudioOnly'));
        expect(names, contains('VideoOnly'));
        expect(names, contains('MixedMedia'));
        expect(names, contains('EmptyFolder'));

        final videoFolder = folders.firstWhere((f) => f.name == 'VideoOnly');
        expect(videoFolder.trackCount, 1);

        final mixedFolder = folders.firstWhere((f) => f.name == 'MixedMedia');
        expect(mixedFolder.trackCount, 2);

        final emptyFolder = folders.firstWhere((f) => f.name == 'EmptyFolder');
        expect(emptyFolder.trackCount, 0);

        final importedFolder = folders.firstWhere(
          (f) => f.name == 'Imported Files',
        );
        expect(importedFolder.trackCount, 1);
        expect(importedFolder.path, 'imported');

        // Verify getFolderAppTracks returns video tracks
        final videoTracks = await db.getFolderAppTracks(videoDir.path);
        expect(videoTracks, hasLength(1));
        expect(videoTracks.first.name, 'Clip');

        // Verify getFolderAppTracks('imported') returns standalone track
        final standaloneTracks = await db.getFolderAppTracks('imported');
        expect(standaloneTracks, hasLength(1));
        expect(standaloneTracks.first.name, 'Standalone');
      },
    );
  });

  group('Local Library Reliability — Safe Stale-File Pruning', () {
    test(
      'Two-phase pruning: First scan marks missing, second scan confirms and removes from library',
      () async {
        final folder = Directory('${tempDir.path}/PruningFolder');
        await folder.create();
        final fileA = File('${folder.path}/fileA.mp3');
        await fileA.writeAsString('audio-a');
        final fileB = File('${folder.path}/fileB.mp3');
        await fileB.writeAsString('audio-b');

        final service = LocalLibraryService(db);
        await service.importFolderAtPath(folder.path);

        var files = await db.getLocalFilesByImportRoot(folder.path);
        expect(files, hasLength(2));
        final idB = files
            .firstWhere((f) => f.locator.endsWith('fileB.mp3'))
            .libraryId;

        // Add fileB to a playlist to test cascading cleanup
        final playlistId = await db.createPlaylist('Test Playlist');
        await db.addToPlaylist(playlistId, idB);
        final playlistEntriesBefore = await db.getPlaylistTracks(playlistId);
        expect(playlistEntriesBefore, hasLength(1));

        // Now delete fileB from disk
        await fileB.delete();
        expect(await fileB.exists(), isFalse);

        // Phase 1: First rescan
        await service.rescanLibrary();

        // fileB should still exist in DB, but marked as missing
        final fileBAfterScan1 = await db.getLocalFile(idB);
        expect(
          fileBAfterScan1,
          isNotNull,
          reason: 'File was pruned prematurely on scan 1',
        );
        expect(fileBAfterScan1!.availabilityStatus, 'missing');

        // Playlist entry should still exist in Phase 1
        final playlistEntriesScan1 = await db.getPlaylistTracks(playlistId);
        expect(playlistEntriesScan1, hasLength(1));

        // Phase 2: Second rescan
        await service.rescanLibrary();

        // fileB was confirmed missing across scans: pruned from DB transactionally
        final fileBAfterScan2 = await db.getLocalFile(idB);
        expect(
          fileBAfterScan2,
          isNull,
          reason: 'Confirmed deleted file was not pruned on scan 2',
        );

        // Playlist entry is removed
        final playlistEntriesScan2 = await db.getPlaylistTracks(playlistId);
        expect(playlistEntriesScan2, isEmpty);

        // FileA remains intact and available
        final fileAInDb = files.firstWhere(
          (f) => f.locator.endsWith('fileA.mp3'),
        );
        final fileAAfter = await db.getLocalFile(fileAInDb.libraryId);
        expect(fileAAfter, isNotNull);
        expect(fileAAfter!.availabilityStatus, 'available');
      },
    );

    test(
      'Reappearance: A missing file that reappears on disk before second scan is restored to available',
      () async {
        final folder = Directory('${tempDir.path}/ReappearFolder');
        await folder.create();
        final fileA = File('${folder.path}/song.mp3');
        await fileA.writeAsString('audio');

        final service = LocalLibraryService(db);
        await service.importFolderAtPath(folder.path);

        var fileRecord = (await db.getLocalFilesByImportRoot(
          folder.path,
        )).first;
        expect(fileRecord.availabilityStatus, 'available');

        // Temporarily delete file
        await fileA.delete();

        // Scan 1 marks missing
        await service.rescanLibrary();
        fileRecord = (await db.getLocalFile(fileRecord.libraryId))!;
        expect(fileRecord.availabilityStatus, 'missing');

        // File reappears!
        await fileA.writeAsString('audio-restored');

        // Scan 2 rediscovers file
        await service.rescanLibrary();
        fileRecord = (await db.getLocalFile(fileRecord.libraryId))!;
        expect(
          fileRecord.availabilityStatus,
          'available',
          reason: 'File availability was not restored',
        );
      },
    );

    test(
      'Disconnected storage / inaccessible root preserves all files without pruning',
      () async {
        final folder = Directory('${tempDir.path}/ExternalDriveFolder');
        await folder.create();
        final fileA = File('${folder.path}/track.mp3');
        await fileA.writeAsString('audio');

        final service = LocalLibraryService(db);
        await service.importFolderAtPath(folder.path);

        final initialFiles = await db.getLocalFilesByImportRoot(folder.path);
        expect(initialFiles, hasLength(1));

        // Simulate disconnecting external drive by removing entire directory
        await folder.delete(recursive: true);

        // Rescan should detect folder does not exist and NEVER prune files
        await service.rescanLibrary();

        final afterFiles = await db.getLocalFilesByImportRoot(folder.path);
        expect(
          afterFiles,
          hasLength(1),
          reason: 'Records were lost when storage was disconnected',
        );
        expect(afterFiles.first.availabilityStatus, 'available');
      },
    );
  });

  group('Local Library Reliability — Removal Without Filesystem Deletion', () {
    test(
      'deleteLocalFile removes DB records but never deletes file on filesystem',
      () async {
        final file = File('${tempDir.path}/keep_me.mp3');
        await file.writeAsString('audio-content');

        await db.upsertLocalFile(
          LocalFilesCompanion.insert(
            libraryId: 'local:keep',
            mechanism: 'absolutePath',
            locator: file.path,
            displayPath: file.path,
            deduplicationKey: 'dedupe-keep',
            lastScannedAt: DateTime.now(),
          ),
        );
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                spotifyId: 'local:keep',
                name: 'Keep Me',
                artistId: 'local',
                artistName: 'Artist',
              ),
            );

        final playlistId = await db.createPlaylist('Playlist');
        await db.addToPlaylist(playlistId, 'local:keep');

        // Remove from library
        await db.deleteLocalFile('local:keep');

        // Verify DB records are gone
        expect(await db.getLocalFile('local:keep'), isNull);
        final trackInDb = await (db.select(
          db.tracks,
        )..where((t) => t.spotifyId.equals('local:keep'))).getSingleOrNull();
        expect(trackInDb, isNull);
        expect(await db.getPlaylistTracks(playlistId), isEmpty);

        // Verify file is STILL on disk!
        expect(
          await file.exists(),
          isTrue,
          reason: 'Physical file was deleted from disk',
        );
      },
    );

    test(
      'deleteLocalFolder removes folder records from DB but leaves disk files untouched',
      () async {
        final folder = Directory('${tempDir.path}/PhysicalFolder');
        await folder.create();
        final file = File('${folder.path}/song.mp3');
        await file.writeAsString('audio');

        final service = LocalLibraryService(db);
        await service.importFolderAtPath(folder.path);

        expect((await db.getAllImportRoots()), hasLength(1));
        expect((await db.getLocalFilesByImportRoot(folder.path)), hasLength(1));

        // Delete local folder from library
        await db.deleteLocalFolder(folder.path);

        // DB records gone
        expect(await db.getAllImportRoots(), isEmpty);
        expect(await db.getLocalFilesByImportRoot(folder.path), isEmpty);

        // Disk files still exist
        expect(await folder.exists(), isTrue);
        expect(await file.exists(), isTrue);
      },
    );
  });

  group('Local Library Reliability — Persistence & Lease Cleanup', () {
    test(
      'Restart persistence: closing and reopening SQLite DB preserves library state',
      () async {
        final folder = Directory('${tempDir.path}/PersistentFolder');
        await folder.create();
        final file = File('${folder.path}/persistent.mp3');
        await file.writeAsString('audio');

        final service = LocalLibraryService(db);
        await service.importFolderAtPath(folder.path);

        final initialRoots = await db.getAllImportRoots();
        final initialFiles = await db.getLocalFilesByImportRoot(folder.path);
        expect(initialRoots, hasLength(1));
        expect(initialFiles, hasLength(1));

        // Close DB (simulate app termination)
        await db.close();

        // Reopen DB from the same SQLite file (simulate app restart)
        db = AppDatabase.forTesting(
          drift.DatabaseConnection(NativeDatabase(dbFile)),
        );

        final restoredRoots = await db.getAllImportRoots();
        final restoredFiles = await db.getLocalFilesByImportRoot(folder.path);
        expect(restoredRoots, hasLength(1));
        expect(restoredFiles, hasLength(1));
        expect(restoredRoots.first.displayPath, folder.path);
        expect(restoredFiles.first.displayPath, file.path);
      },
    );

    test('AuthorizedFileLease invokes onRelease callback properly', () async {
      bool leaseReleased = false;
      final lease = AuthorizedFileLease(
        canonicalPath: '/test/path',
        onRelease: () async {
          leaseReleased = true;
        },
      );

      expect(leaseReleased, isFalse);
      await lease.release();
      expect(leaseReleased, isTrue);
    });
  });
}
