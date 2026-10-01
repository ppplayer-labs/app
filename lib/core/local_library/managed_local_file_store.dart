import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// App-owned imports use a relative locator so a new iOS sandbox path does not
/// invalidate the library or a persisted playback queue.
class ManagedLocalFileStore {
  ManagedLocalFileStore({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;
  final Future<Directory> Function() _documentsDirectory;

  Future<String> importFile(String source, String name) async {
    final documents = await _documentsDirectory();
    final relative = p.join('local_music', const Uuid().v4(), p.basename(name));
    final target = File(p.join(documents.path, relative));
    await target.parent.create(recursive: true);
    try {
      await File(source).copy(target.path);
      return Uri(
        scheme: 'pp-local',
        path: '/${p.posix.joinAll(p.split(relative))}',
      ).toString();
    } catch (_) {
      await target.parent.delete(recursive: true);
      rethrow;
    }
  }

  Future<String> resolve(String locator) async {
    final uri = Uri.parse(locator);
    if (uri.scheme != 'pp-local' ||
        uri.host.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.path.startsWith('/local_music/') ||
        uri.pathSegments.any(
          (part) =>
              part == '..' ||
              part == '.' ||
              part.contains('\\') ||
              part.contains('/'),
        )) {
      throw const FormatException('Invalid managed media locator');
    }
    final relative = p.joinAll(uri.pathSegments);
    final documents = await _documentsDirectory();
    return p.join(documents.path, relative);
  }
}
