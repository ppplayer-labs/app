import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show GlobalKey, ScaffoldMessengerState, SnackBar, Text;
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/models/track.dart' show Track;
import 'local_track_source.dart' hide ImportRoot;
import 'metadata_extractor.dart';
import 'local_file_resolver.dart';
import 'managed_local_file_store.dart';
import 'audio_format_registry.dart';
import 'video_probe_service.dart';
import 'm3u_handler.dart';
import 'package:path/path.dart' as p;
import '../../features/library/video_thumbnail_generator.dart';
import 'package:ppplayer/l10n/app_localizations.dart';

String _canonicalPath(String rawPath) {
  final clean = rawPath.trim();
  if (clean.isEmpty) return clean;
  try {
    return Directory(clean).resolveSymbolicLinksSync();
  } catch (_) {
    return p.canonicalize(clean);
  }
}

class _DirectoryScanResult {
  final List<String> files;
  final bool isComplete;
  const _DirectoryScanResult(this.files, this.isComplete);
}

final localLibraryServiceProvider = Provider<LocalLibraryService>((ref) {
  return LocalLibraryService(ref.watch(appDatabaseProvider));
});

class LocalLibraryService {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  LocalLibraryService(
    this._db, {
    TargetPlatform? platform,
    ManagedLocalFileStore? managedStore,
  }) : _platform = platform ?? defaultTargetPlatform,
       _managedStore = managedStore ?? ManagedLocalFileStore();
  final TargetPlatform _platform;
  final ManagedLocalFileStore _managedStore;
  bool get _isIOS => _platform == TargetPlatform.iOS;

  /// Root messenger used to surface import notices from non-UI code.
  /// Attach to `MaterialApp.scaffoldMessengerKey`.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showNotice(String message) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _notify(String message) => showNotice(message);

  /// True when a file at the raw [path] is already in the library (matches
  /// individually imported files and children of imported folders).
  Future<bool> _alreadyImported(String path) async =>
      await _db.getLocalFileByDeduplicationKey(_hashLocator(path)) != null;

  void _notifySkipped(List<String> names) {
    if (names.isEmpty) return;
    final context = messengerKey.currentContext;
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (l10n != null) {
      _notify(
        names.length == 1
            ? l10n.fileAlreadyImported(names.first)
            : l10n.filesAlreadyImported(names.length),
      );
    } else {
      _notify(
        names.length == 1
            ? '"${names.first}" is already in your library'
            : '${names.length} files were already in your library',
      );
    }
  }

  void _notifyFolderAlreadyImported() {
    final context = messengerKey.currentContext;
    final l10n = context != null ? AppLocalizations.of(context) : null;
    _notify(
      l10n?.folderAlreadyImported ??
          'This folder is already imported — checking for new files',
    );
  }

  Future<List<Track>> importFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        ...AudioFormatRegistry.importCandidates,
        ...AudioFormatRegistry.videoImportCandidates,
      ].map((e) => e.replaceAll('.', '')).toSet().toList(),
    );

    if (result.isEmpty) return [];

    final importedTracks = <Track>[];
    final skipped = <String>[];

    for (final file in result) {
      if (await _alreadyImported(file.path!)) {
        skipped.add(file.name);
        continue;
      }
      String locator = file.path!;
      TrackSourceType mechanism = TrackSourceType.absolutePath;

      if (_isIOS || (Platform.isAndroid && locator.contains('/cache/'))) {
        final copyPath = await _moveToManagedCopy(locator, file.name);
        if (copyPath == null) continue;
        locator = copyPath;
        mechanism = TrackSourceType.managedCopy;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final bookmark = await createSecurityScopedBookmark(locator);
        if (bookmark != null) {
          locator = bookmark;
          mechanism = TrackSourceType.iOsSecurityBookmark;
        } else {
          mechanism = TrackSourceType.absolutePath;
        }
      }

      final track = await _processDiscoveredFile(
        locator: locator,
        displayPath: file.name,
        mechanism: mechanism,
        importRootLocator: null,
        scopeHint: ImportMediaScope.both,
      );

      if (track != null) {
        importedTracks.add(track);
      }
    }

    _notifySkipped(skipped);
    return importedTracks;
  }

  /// Prompts the user to pick video files and imports them.
  /// Files are probed for an actual video stream; audio-only containers will
  /// be imported without [isVideo] set and will not appear in the Videos library.
  Future<void> importVideoFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AudioFormatRegistry.videoImportCandidates
          .map((e) => e.replaceAll('.', ''))
          .toList(),
    );

    if (result.isEmpty) return;

    final skipped = <String>[];
    for (final file in result) {
      if (await _alreadyImported(file.path!)) {
        skipped.add(file.name);
        continue;
      }
      String locator = file.path!;
      TrackSourceType mechanism = TrackSourceType.absolutePath;

      if (_isIOS || (Platform.isAndroid && locator.contains('/cache/'))) {
        final copyPath = await _moveToManagedCopy(locator, file.name);
        if (copyPath == null) continue;
        locator = copyPath;
        mechanism = TrackSourceType.managedCopy;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final bookmark = await createSecurityScopedBookmark(locator);
        if (bookmark != null) {
          locator = bookmark;
          mechanism = TrackSourceType.iOsSecurityBookmark;
        } else {
          mechanism = TrackSourceType.absolutePath;
        }
      }

      await _processDiscoveredFile(
        locator: locator,
        displayPath: file.name,
        mechanism: mechanism,
        importRootLocator: null,
        scopeHint: ImportMediaScope.video,
      );
    }
    _notifySkipped(skipped);
  }

  /// Imports files from specific paths (e.g., via macOS Open File command).
  /// [scopeHint] controls whether each file is probed for a video stream.
  /// Pass [ImportMediaScope.audio] for audio paths and [ImportMediaScope.video]
  /// for video paths.  [ImportMediaScope.both] triggers detection by extension.
  /// Returns the imported tracks.
  Future<List<Track>> importFilesByPaths(
    List<String> paths, {
    ImportMediaScope scopeHint = ImportMediaScope.both,
  }) async {
    final importedTracks = <Track>[];
    final skipped = <String>[];
    for (final path in paths) {
      if (await _alreadyImported(path)) {
        skipped.add(path.split('/').last);
        continue;
      }
      String locator = path;
      TrackSourceType mechanism = TrackSourceType.absolutePath;

      if (_isIOS || (Platform.isAndroid && locator.contains('/cache/'))) {
        final copyPath = await _moveToManagedCopy(
          locator,
          path.split('/').last,
        );
        if (copyPath == null) continue;
        locator = copyPath;
        mechanism = TrackSourceType.managedCopy;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final bookmark = await createSecurityScopedBookmark(locator);
        if (bookmark != null) {
          locator = bookmark;
          mechanism = TrackSourceType.iOsSecurityBookmark;
        } else {
          mechanism = TrackSourceType.absolutePath;
        }
      }

      // When scope is 'both', detect by extension.
      final resolvedScope = scopeHint == ImportMediaScope.both
          ? (AudioFormatRegistry.isVideoFormatCandidate(
                  AudioFormatRegistry.extensionOf(path),
                )
                ? ImportMediaScope.video
                : ImportMediaScope.audio)
          : scopeHint;

      final track = await _processDiscoveredFile(
        locator: locator,
        displayPath: path.split('/').last,
        mechanism: mechanism,
        importRootLocator: null,
        scopeHint: resolvedScope,
      );
      if (track != null) {
        importedTracks.add(track);
      }
    }
    _notifySkipped(skipped);
    return importedTracks;
  }

  /// Opens a folder picker and imports all audio files found recursively.
  Future<void> importFolder() async {
    await _pickAndImportFolder(scope: ImportMediaScope.audio);
  }

  /// Opens a folder picker and imports all video candidate files found
  /// recursively.  Each file is probed; audio-only containers are imported
  /// without [isVideo] set.
  Future<void> importVideoFolder() async {
    await _pickAndImportFolder(scope: ImportMediaScope.video);
  }

  Future<void> _pickAndImportFolder({required ImportMediaScope scope}) async {
    debugPrint('Opening FilePicker for directory (scope: ${scope.name})...');
    final rootPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select folder to import',
    );
    debugPrint('FilePicker returned: $rootPath');
    if (rootPath == null) return;
    await importFolderAtPath(rootPath, scope: scope);
  }

  /// Imports a folder that has already been chosen (picker result, or a test
  /// fixture directory). Creates the security-scoped root bookmark on
  /// Apple platforms, persists the import root, and scans it.
  @visibleForTesting
  Future<void> importFolderAtPath(
    String rootPath, {
    ImportMediaScope scope = ImportMediaScope.audio,
  }) async {
    final String rootId = _uuid.v4();
    TrackSourceType rootMechanism = TrackSourceType.absolutePath;
    String rootLocator = rootPath;

    if (Platform.isAndroid) {
      rootMechanism = TrackSourceType.androidContentUri;
      rootLocator = rootPath;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final bookmark = await createSecurityScopedBookmark(rootPath);
      if (bookmark != null) {
        rootLocator = bookmark;
        rootMechanism = TrackSourceType.iOsSecurityBookmark;
      }
    }

    // Check for an existing root at this path to avoid duplicate library records.
    // Ensure duplicate detection uses the resolved canonical folder identity
    // rather than comparing different bookmark strings.
    final targetCanonical = _canonicalPath(rootPath);
    final allRoots = await _db.select(_db.importRoots).get();
    ImportRoot? existing;
    for (final r in allRoots) {
      if (r.rootLocator == rootLocator) {
        existing = r;
        break;
      }
      final display = r.displayPath.trim();
      if (display.isNotEmpty && _canonicalPath(display) == targetCanonical) {
        existing = r;
        break;
      }
    }

    if (existing != null) {
      _notifyFolderAlreadyImported();
      if (rootMechanism == TrackSourceType.iOsSecurityBookmark &&
          existing.rootLocator != rootLocator) {
        final oldLocator = existing.rootLocator;
        await (_db.update(
          _db.localFiles,
        )..where((f) => f.importRootLocator.equals(oldLocator))).write(
          LocalFilesCompanion(importRootLocator: drift.Value(rootLocator)),
        );
      } else {
        rootLocator = existing.rootLocator;
        rootMechanism = TrackSourceType.values.byName(existing.mechanism);
      }
    }

    final String effectiveRootId;
    final ImportMediaScope effectiveScope;

    if (existing != null) {
      effectiveRootId = existing.id;
      final existingScope = ImportMediaScope.values.byName(existing.mediaScope);
      effectiveScope = (existingScope == scope) ? scope : ImportMediaScope.both;
    } else {
      effectiveRootId = rootId;
      effectiveScope = scope;
    }

    final root = ImportRootsCompanion.insert(
      id: effectiveRootId,
      mechanism: rootMechanism.name,
      rootLocator: rootLocator,
      displayPath: rootPath,
      addedAt: existing != null ? existing.addedAt : DateTime.now(),
      mediaScope: drift.Value(effectiveScope.name),
    );
    await _db.upsertImportRoot(root);

    await _scanRoot(
      id: effectiveRootId,
      mechanism: rootMechanism,
      locator: rootLocator,
      scope: effectiveScope,
    );
  }

  Future<void> importPlaylist({void Function(String?)? onProgress}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8'],
    );

    if (result.isEmpty) return;
    final file = result.first;
    await processPlaylistFile(file.path!, file.name, onProgress: onProgress);
  }

  Future<int> processPlaylistFile(
    String filePath,
    String fileName, {
    void Function(String?)? onProgress,
  }) async {
    String locator = filePath;
    TrackSourceType mechanism = TrackSourceType.absolutePath;

    if (_isIOS || (Platform.isAndroid && locator.contains('/cache/'))) {
      final copyPath = await _moveToManagedCopy(locator, fileName);
      if (copyPath == null) throw Exception('Failed to read playlist from URI');
      locator = copyPath;
      mechanism = TrackSourceType.managedCopy;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final bookmark = await createSecurityScopedBookmark(locator);
      if (bookmark != null) {
        locator = bookmark;
        mechanism = TrackSourceType.iOsSecurityBookmark;
      }
    }

    onProgress?.call('Importing playlist...');

    final playlistPath = Uri.tryParse(locator)?.scheme == 'pp-local'
        ? await _managedStore.resolve(locator)
        : locator;
    final bytes = await File(playlistPath).readAsBytes();
    final isTemporary =
        locator.contains('/cache/') ||
        locator.contains('/tmp/') ||
        mechanism == TrackSourceType.managedCopy;
    final sourceLocation = isTemporary ? null : locator;
    final entries = await M3uHandler.parse(
      bytes,
      sourceLocation: sourceLocation,
    );

    onProgress?.call('Scanning ${entries.length} items...');

    final playlistName = fileName.replaceAll(RegExp(r'\.m3u8?$'), '');
    final playlistId = await _db
        .into(_db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            name: playlistName,
            createdAt: drift.Value(DateTime.now()),
          ),
        );

    int processed = 0;
    for (final entry in entries) {
      onProgress?.call('Importing track ${processed + 1}/${entries.length}...');
      final trackMechanism =
          mechanism == TrackSourceType.androidContentUri &&
              entry.pathOrUri.startsWith('content://')
          ? TrackSourceType.androidContentUri
          : TrackSourceType.absolutePath;

      final dedupeKey = _hashLocator(entry.pathOrUri);
      var existingFile = await _db.getLocalFileByDeduplicationKey(dedupeKey);

      if (existingFile == null && isTemporary) {
        final searchPath = entry.pathOrUri.replaceAll('\\', '/');
        final query = _db.select(_db.localFiles)
          ..where((f) => f.locator.like('%$searchPath'));
        final results = await query.get();
        if (results.isNotEmpty) {
          existingFile = results.first;
        }
      }

      String spotifyId;
      if (existingFile != null) {
        spotifyId = existingFile.libraryId;
      } else {
        final track = await _processDiscoveredFile(
          locator: entry.pathOrUri,
          displayPath: entry.pathOrUri.split(Platform.pathSeparator).last,
          mechanism: trackMechanism,
          importRootLocator: null,
        );
        if (track == null) {
          processed++;
          continue;
        }
        spotifyId = track.spotifyId;
      }

      await _db
          .into(_db.playlistTracks)
          .insert(
            PlaylistTracksCompanion.insert(
              playlistId: playlistId,
              trackSpotifyId: spotifyId,
              position: processed,
            ),
          );

      processed++;
    }
    onProgress?.call(null);
    return playlistId;
  }

  Future<M3uExportResult?> exportPlaylist(int playlistId) async {
    final playlistTracks = await _db.getPlaylistAppTracks(playlistId);
    if (playlistTracks.isEmpty) return null;

    final playlist = await (_db.select(
      _db.playlists,
    )..where((p) => p.id.equals(playlistId))).getSingle();

    final outputFileUri = await FilePicker.saveFile(
      dialogTitle: 'Export Playlist',
      fileName: '${playlist.name}.m3u8',
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8'],
      bytes: Uint8List(0),
    );
    if (outputFileUri == null) return null;

    final String outputFile = outputFileUri.toFilePath();
    final destDir = p.dirname(outputFile);

    final result = M3uHandler.generate(
      playlistTracks,
      exportDestinationDir: destDir,
    );

    await File(outputFile).writeAsString(result.content);
    return result;
  }

  Future<M3uExportResult?> exportQueue(List<Track> queueTracks) async {
    if (queueTracks.isEmpty) return null;

    final outputFileUri = await FilePicker.saveFile(
      dialogTitle: 'Export Queue',
      fileName: 'queue.m3u8',
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8'],
      bytes: Uint8List(0),
    );
    if (outputFileUri == null) return null;

    final String outputFile = outputFileUri.toFilePath();
    final destDir = p.dirname(outputFile);

    final result = M3uHandler.generate(
      queueTracks,
      exportDestinationDir: destDir,
    );

    await File(outputFile).writeAsString(result.content);
    return result;
  }

  Future<void> rescanLibrary({void Function(String?)? onProgress}) async {
    try {
      final existingRoots = await _db.select(_db.importRoots).get();
      final existingFiles = await _db.select(_db.localFiles).get();

      for (final root in existingRoots) {
        onProgress?.call('Scanning folder: ${root.displayPath}...');
        final mechanism = TrackSourceType.values.byName(root.mechanism);
        // Restore persisted scope — never re-infer from extensions.
        final scope = ImportMediaScope.values.byName(root.mediaScope);
        await _scanRoot(
          id: root.id,
          mechanism: mechanism,
          locator: root.rootLocator,
          scope: scope,
        );
      }

      // Verify standalone files
      int verified = 0;
      for (final file in existingFiles) {
        if (file.importRootLocator != null) continue; // Handled by folder scan

        onProgress?.call(
          'Verifying standalone files ($verified/${existingFiles.length})...',
        );
        final mechanism = TrackSourceType.values.byName(file.mechanism);

        final source = LocalTrackSource(
          libraryId: file.libraryId,
          locator: file.locator,
          displayPath: file.displayPath,
          mechanism: mechanism,
          deduplicationKey: file.deduplicationKey,
          lastScannedAt: file.lastScannedAt,
          availabilityStatus: TrackAvailabilityStatus.values.firstWhere(
            (e) => e.name == file.availabilityStatus,
            orElse: () => TrackAvailabilityStatus.available,
          ),
          importRootLocator: file.importRootLocator,
        );
        final resolver = LocalFileResolver.forSource(source);
        final status = await resolver.checkAccess(source);

        if (status != TrackAvailabilityStatus.available) {
          if (status == TrackAvailabilityStatus.missing) {
            // Check if parent directory exists to distinguish deleted file from disconnected drive
            bool parentExists = false;
            try {
              final uri = Uri.tryParse(file.locator);
              final rawPath = (uri != null && uri.scheme == 'file')
                  ? File.fromUri(uri).path
                  : file.locator;
              if (rawPath.startsWith('/')) {
                parentExists = await Directory(p.dirname(rawPath)).exists();
              }
            } catch (_) {}

            if (parentExists) {
              if (file.availabilityStatus == 'missing') {
                // Confirmed missing on second scan -> prune transactionally
                await _db.deleteLocalFile(file.libraryId);
              } else {
                // First scan missing -> mark as missing
                await _db.updateLocalFileStatus(
                  file.libraryId,
                  'missing',
                  DateTime.now(),
                );
              }
            } else {
              // Disconnected drive / parent unreachable: preserve record
              if (file.availabilityStatus != 'missing') {
                await _db.updateLocalFileStatus(
                  file.libraryId,
                  'missing',
                  DateTime.now(),
                );
              }
            }
          } else {
            await _db.updateLocalFileStatus(
              file.libraryId,
              status.name,
              DateTime.now(),
            );
          }
        } else {
          // Available: restore
          await _db.updateLocalFileStatus(
            file.libraryId,
            'available',
            DateTime.now(),
          );
        }
        verified++;
      }
      onProgress?.call(null);
    } catch (e) {
      onProgress?.call(null);
      final context = messengerKey.currentContext;
      final l10n = (context != null && context.mounted)
          ? AppLocalizations.of(context)
          : null;
      _notify(
        l10n?.rescanFailed(e.toString()) ?? 'Failed to rescan folder: $e',
      );
      rethrow;
    }
  }

  Future<String?> _moveToManagedCopy(String tempPath, String name) async {
    try {
      if (_isIOS) {
        final locator = await _managedStore.importFile(tempPath, name);
        debugPrint('[LocalLibrary] import.managed_copy persisted=true');
        return locator;
      }
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/local_music');
      await targetDir.create(recursive: true);
      final targetPath = '${targetDir.path}/$name';
      await File(tempPath).copy(targetPath);
      return targetPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _scanRoot({
    required String id,
    required TrackSourceType mechanism,
    required String locator,
    ImportMediaScope scope = ImportMediaScope.audio,
  }) async {
    List<String> files = [];

    if (mechanism == TrackSourceType.androidContentUri) {
      try {
        files = await listAudioFilesInDocumentTree(locator, recursive: true);
        debugPrint('Found ${files.length} media files (scope: ${scope.name})');
        await _importScannedFiles(
          files,
          mechanism: mechanism,
          locator: locator,
        );
        await _pruneStaleFilesInRoot(locator: locator, discoveredFiles: files);
      } catch (e) {
        debugPrint('Android document tree scan failed: $e');
      }
      return;
    }

    String pathToScan = locator;
    var bookmarkAccessStarted = false;
    if (mechanism == TrackSourceType.iOsSecurityBookmark) {
      // The persisted root locator is a base64 bookmark, not a path. Resolve
      // it (which also starts security-scoped access) before enumerating.
      final resolved = await resolveSecurityScopedBookmark(locator);
      if (resolved == null) {
        debugPrint('[LocalLibrary] scan.root_unresolvable bookmark=true');
        // Folder bookmark resolution failed (drive disconnected or permission issue).
        // NEVER prune records when bookmark resolution fails!
        return;
      }
      bookmarkAccessStarted = true;
      pathToScan = resolved;
    }
    try {
      final dir = Directory(pathToScan);
      if (!await dir.exists()) {
        debugPrint(
          '[LocalLibrary] Root directory does not exist: $pathToScan (drive unplugged/moved). Preserving records.',
        );
        return;
      }

      final scanResult = await _enumerateDirectory(pathToScan, scope);
      files = scanResult.files;
      debugPrint('Found ${files.length} media files (scope: ${scope.name})');
      await _importScannedFiles(files, mechanism: mechanism, locator: locator);

      // Safe stale-file pruning only after a confirmed, complete scan
      if (scanResult.isComplete) {
        await _pruneStaleFilesInRoot(locator: locator, discoveredFiles: files);
      } else {
        debugPrint(
          '[LocalLibrary] Skipping prune for $locator: scan encountered directory errors and was incomplete',
        );
      }
    } finally {
      if (bookmarkAccessStarted) {
        await stopAccessingSecurityScopedBookmark(locator);
      }
    }
  }

  Future<void> _pruneStaleFilesInRoot({
    required String locator,
    required List<String> discoveredFiles,
  }) async {
    final roots = await _db.select(_db.importRoots).get();
    final targetRoot = roots.where((r) => r.rootLocator == locator).firstOrNull;
    final locators = <String>{locator};
    if (targetRoot != null && targetRoot.displayPath.trim().isNotEmpty) {
      final targetCanonical = _canonicalPath(targetRoot.displayPath);
      for (final r in roots) {
        if (r.displayPath.trim().isNotEmpty &&
            _canonicalPath(r.displayPath) == targetCanonical) {
          locators.add(r.rootLocator);
        }
      }
    }

    final existingInDb = <LocalFile>[];
    for (final loc in locators) {
      existingInDb.addAll(await _db.getLocalFilesByImportRoot(loc));
    }
    if (existingInDb.isEmpty) return;

    final discoveredSet = discoveredFiles.toSet();
    final now = DateTime.now();

    for (final file in existingInDb) {
      if (discoveredSet.contains(file.locator)) {
        continue;
      }

      bool existsOnDisk = false;
      try {
        existsOnDisk = await File(file.locator).exists();
      } catch (_) {}

      if (existsOnDisk) {
        // Still exists on disk; preserve
        continue;
      }

      // Safe two-phase policy:
      if (file.availabilityStatus == 'missing') {
        // Phase 2: Confirmed missing across multiple scans -> prune transactionally from library
        debugPrint(
          '[LocalLibrary] Pruning confirmed deleted file: ${file.displayPath}',
        );
        await _db.deleteLocalFile(file.libraryId);
      } else {
        // Phase 1: Mark as missing on first complete scan
        debugPrint('[LocalLibrary] Marking missing file: ${file.displayPath}');
        await _db.updateLocalFileStatus(file.libraryId, 'missing', now);
      }
    }
  }

  Future<_DirectoryScanResult> _enumerateDirectory(
    String pathToScan,
    ImportMediaScope scope,
  ) async {
    final files = <String>[];
    bool isComplete = true;
    final dir = Directory(pathToScan);
    debugPrint(
      'Scanning directory: $pathToScan, exists: ${await dir.exists()} scope: ${scope.name}',
    );
    if (!await dir.exists()) {
      return const _DirectoryScanResult([], false);
    }

    final List<Directory> dirsToScan = [dir];
    while (dirsToScan.isNotEmpty) {
      final currentDir = dirsToScan.removeLast();
      try {
        await for (final entity in currentDir.list(
          recursive: false,
          followLinks: false,
        )) {
          if (entity is Directory) {
            dirsToScan.add(entity);
          } else if (entity is File) {
            final ext = AudioFormatRegistry.extensionOf(entity.path);
            final isAudioExt = AudioFormatRegistry.isRecognizedImportCandidate(
              ext,
            );
            final isVideoExt = AudioFormatRegistry.isVideoFormatCandidate(ext);
            final include =
                (scope.includesAudio && isAudioExt) ||
                (scope.includesVideo && isVideoExt);
            if (include) {
              files.add(entity.path);
            }
          }
        }
      } catch (e) {
        debugPrint('Skipping inaccessible directory ${currentDir.path}: $e');
        isComplete = false;
      }
    }
    return _DirectoryScanResult(files, isComplete);
  }

  Future<void> _importScannedFiles(
    List<String> files, {
    required TrackSourceType mechanism,
    required String locator,
  }) async {
    for (final f in files) {
      final fileMechanism = mechanism == TrackSourceType.androidContentUri
          ? TrackSourceType.androidContentUri
          : TrackSourceType.absolutePath;
      final ext = AudioFormatRegistry.extensionOf(f);
      final fileScope = AudioFormatRegistry.isVideoFormatCandidate(ext)
          ? ImportMediaScope.video
          : ImportMediaScope.audio;
      await _processDiscoveredFile(
        locator: f,
        displayPath: f,
        mechanism: fileMechanism,
        importRootLocator: locator,
        scopeHint: fileScope,
      );
    }
  }

  /// Processes a single discovered file: deduplicates, extracts metadata,
  /// probes for video stream (when [scopeHint] is [ImportMediaScope.video] or
  /// the extension is a video candidate), and upserts to DB.
  ///
  /// [scopeHint] drives probing:
  /// - [ImportMediaScope.audio]: skips video probe entirely.
  /// - [ImportMediaScope.video]: always probes regardless of extension.
  /// - [ImportMediaScope.both]: probes only when extension is a video candidate.
  Future<Track?> _processDiscoveredFile({
    required String locator,
    required String displayPath,
    required TrackSourceType mechanism,
    required String? importRootLocator,
    ImportMediaScope scopeHint = ImportMediaScope.audio,
  }) async {
    final dedupeKey = _hashLocator(locator);
    final existing = await _db.getLocalFileByDeduplicationKey(dedupeKey);
    final libraryId = existing?.libraryId ?? 'local:${_uuid.v4()}';

    String extractPath = locator;
    bool isTemp = false;
    bool scopedBookmark = false;
    if (Uri.tryParse(locator)?.scheme == 'pp-local') {
      extractPath = await _managedStore.resolve(locator);
    } else if (mechanism == TrackSourceType.iOsSecurityBookmark) {
      final resolved = await resolveSecurityScopedBookmark(locator);
      if (resolved == null) return null;
      extractPath = resolved;
      scopedBookmark = true;
    }
    try {
      if (mechanism == TrackSourceType.androidContentUri) {
        final temp = await copyContentUriToTempFile(locator, 'temp.audio');
        if (temp != null) {
          extractPath = temp;
          isTemp = true;
        } else {
          return null;
        }
      }

      var metadata = await extractMetadata(extractPath);

      // --- Video probe ---
      // Determine whether to probe based on scope and extension.
      final ext = AudioFormatRegistry.extensionOf(extractPath);
      final shouldProbe =
          scopeHint == ImportMediaScope.video ||
          (scopeHint == ImportMediaScope.both &&
              AudioFormatRegistry.isVideoFormatCandidate(ext));

      bool isVideo = false;
      if (shouldProbe) {
        // Build a URI suitable for media_kit.
        final probeUri = mechanism == TrackSourceType.androidContentUri
            ? locator // content:// URI passed directly
            : Uri.file(extractPath).toString();

        final probeResult = await VideoProbeService.probe(probeUri);
        switch (probeResult) {
          case VideoProbeResult.hasVideo:
            isVideo = true;
            if (metadata.artworkPath == null) {
              final thumbPath =
                  await VideoThumbnailGenerator.generateAndSaveThumbnail(
                    extractPath,
                  );
              if (thumbPath != null) {
                metadata = ExtractedMetadata(
                  title: metadata.title,
                  artistName: metadata.artistName,
                  albumArtist: metadata.albumArtist,
                  albumName: metadata.albumName,
                  albumGroupKey: metadata.albumGroupKey,
                  year: metadata.year,
                  genre: metadata.genre,
                  trackNumber: metadata.trackNumber,
                  trackTotal: metadata.trackTotal,
                  discNumber: metadata.discNumber,
                  discTotal: metadata.discTotal,
                  durationMs: metadata.durationMs,
                  artworkPath: thumbPath,
                  artworkMimeType: 'image/jpeg',
                );
              }
            }
          case VideoProbeResult.audioOnly:
            isVideo = false;
            debugPrint(
              'VideoProbe: $displayPath is audio-only (no video stream)',
            );
          case VideoProbeResult.probeFailed:
            // Failed probe: leave isVideo=false (safe default; will stay in audio
            // library or remain unclassified until a future rescan).
            debugPrint(
              'VideoProbe: $displayPath probe failed/timed out; defaulting to audio',
            );
          case VideoProbeResult.cancelled:
            debugPrint('VideoProbe: $displayPath probe cancelled');
        }
      }

      await _db.upsertLocalFile(
        LocalFilesCompanion.insert(
          libraryId: libraryId,
          mechanism: mechanism.name,
          locator: locator,
          displayPath: displayPath,
          deduplicationKey: dedupeKey,
          availabilityStatus: const drift.Value('available'),
          lastScannedAt: DateTime.now(),
          importRootLocator: drift.Value(importRootLocator),
          albumArtist: drift.Value(metadata.albumArtist),
          albumGroupKey: drift.Value(metadata.albumGroupKey),
          trackNumber: drift.Value(metadata.trackNumber),
          trackTotal: drift.Value(metadata.trackTotal),
          discNumber: drift.Value(metadata.discNumber),
          discTotal: drift.Value(metadata.discTotal),
          genre: drift.Value(metadata.genre),
          releaseYear: drift.Value(metadata.year),
          artworkPath: drift.Value(metadata.artworkPath),
          artworkMimeType: drift.Value(metadata.artworkMimeType),
          isVideo: drift.Value(isVideo),
        ),
      );

      await _db
          .into(_db.tracks)
          .insertOnConflictUpdate(
            TracksCompanion.insert(
              spotifyId: libraryId,
              name: metadata.title,
              artistId: 'local',
              artistName: metadata.artistName,
              albumId: drift.Value(metadata.albumGroupKey),
              albumName: drift.Value(metadata.albumName),
              albumImage: drift.Value(metadata.artworkPath),
              durationMs: drift.Value(metadata.durationMs),
            ),
          );

      return Track.fromLocalFile(
        libraryId: libraryId,
        name: metadata.title,
        artistName: metadata.artistName,
        albumName: metadata.albumName,
        localFilePath: locator,
        localArtworkPath: metadata.artworkPath,
        durationMs: metadata.durationMs,
        isVideoFile: isVideo,
      );
    } finally {
      if (scopedBookmark) await stopAccessingSecurityScopedBookmark(locator);
      if (isTemp) {
        try {
          await File(extractPath).delete();
        } catch (_) {}
      }
    }
  }

  String _hashLocator(String loc) {
    return sha1.convert(utf8.encode(loc)).toString().substring(0, 16);
  }
}
