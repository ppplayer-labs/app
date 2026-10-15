import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert';

import '../playback/playback_providers.dart';
import 'package:flutter/foundation.dart';
import 'cast/cast_output_backend.dart';
import 'cast/cast_platform_client.dart';
import 'cast/fake_cast_platform_client.dart';
import 'cast/desktop_cast_platform_client.dart';
import 'dlna/dlna_discovery.dart';
import 'dlna/dlna_output_backend.dart';
import 'local_media_server.dart';
import 'models.dart';
import 'network_media_factory.dart';
import 'network_output_capabilities.dart';
import 'network_output_controller.dart';
import '../local_library/local_file_resolver.dart';
import '../local_library/managed_local_file_store.dart';

/// The shared [LocalMediaServer] instance. Disposed automatically on provider
/// teardown; callers must never shut it down manually.
final localMediaServerProvider = Provider<LocalMediaServer>((ref) {
  final server = LocalMediaServer();
  ref.onDispose(() => server.dispose());
  return server;
});

/// Platform capabilities for Network Outputs.
final networkOutputCapabilitiesProvider =
    FutureProvider<NetworkOutputsCapabilities>((ref) async {
      return NetworkOutputsCapabilities.resolve();
    });

/// The DLNA discovery instance.
final dlnaDiscoveryProvider = Provider<DlnaDiscovery>((ref) {
  // Owned by DlnaOutputBackend below; we expose it for diagnostics only.
  return ref.watch(dlnaOutputBackendProvider).discovery;
});

/// The DLNA [NetworkOutputBackend].
final dlnaOutputBackendProvider = Provider<DlnaOutputBackend>((ref) {
  final backend = DlnaOutputBackend();
  ref.onDispose(() => backend.dispose());
  return backend;
});

/// The Cast [NetworkOutputBackend].
final castOutputBackendProvider = Provider<CastOutputBackend>((ref) {
  CastPlatformClient? client;
  if (kDebugMode && const bool.fromEnvironment('PP_FAKE_CAST_DEVICE')) {
    final fake = FakeCastPlatformClient();
    client = fake;
    ref.onDispose(() => fake.dispose());
  } else if (Platform.isMacOS) {
    final desktop = DesktopCastPlatformClient();
    client = desktop;
    ref.onDispose(() => desktop.dispose());
  }
  final backend = CastOutputBackend(client: client);
  ref.onDispose(() => backend.dispose());
  return backend;
});

/// The central [NetworkOutputController]. This wraps the local playback engine
/// and routes commands to whichever output is currently selected.
///
/// The local engine is kept alive independently — [NetworkOutputController]
/// orchestrates it; it does not own the engine's lifecycle.
final networkOutputControllerProvider = Provider<NetworkOutputController>((
  ref,
) {
  final localEngine = ref.watch(localPlaybackControllerProvider);
  final server = ref.watch(localMediaServerProvider);
  final dlnaBackend = ref.watch(dlnaOutputBackendProvider);
  final castBackend = ref.watch(castOutputBackendProvider);
  final factory = DefaultNetworkMediaFactory(
    server: server,
    acquireFileLease: (Platform.isIOS || Platform.isMacOS)
        ? acquireAppleOutputFileLease
        : null, // uses acquireDirectFile on other platforms
  );
  final controller = NetworkOutputController(
    localController: localEngine,
    backends: [],
    mediaFactory: factory,
  );

  ref.listen<AsyncValue<NetworkOutputsCapabilities>>(
    networkOutputCapabilitiesProvider,
    (previous, next) {
      next.whenData((capabilities) {
        if (capabilities.googleCastAvailable) {
          controller.registerBackend(castBackend);
        }
        if (capabilities.dlnaAvailable) {
          controller.registerBackend(dlnaBackend);
        }
      });
    },
    fireImmediately: true,
  );

  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Exposes the full [NetworkOutputState] stream for UI consumption.
final networkOutputStateProvider = StreamProvider<NetworkOutputState>((ref) {
  final controller = ref.watch(networkOutputControllerProvider);
  return controller.outputStateStream;
});

/// Synchronous snapshot of the current output state — safe to read without
/// async. Falls back to the default (local, no outputs) on cold start.
final networkOutputSnapshotProvider = Provider<NetworkOutputState>((ref) {
  return ref.watch(networkOutputStateProvider).asData?.value ??
      ref.watch(networkOutputControllerProvider).currentOutputState;
});

/// iOS/macOS-aware [AcquireOutputFileLease] injected into [DefaultNetworkMediaFactory].
///
/// The lifetime contract:
///
///   1. bookmark resolved → `startAccessingSecurityScopedResource()` active
///   2. [AuthorizedFileLease] created, held by [LocalMediaServer]
///   3. HTTP server streams the file to the remote receiver
///   4. [LocalMediaServer] calls [AuthorizedFileLease.release]
///   5. [onRelease] calls `stopAccessingSecurityScopedResource()`
///
/// On non-bookmark inputs (file:// URIs, absolute paths) no native call is
/// needed and [onRelease] is null.
Future<AuthorizedFileLease> acquireAppleOutputFileLease(
  PlaybackTrack track, {
  Future<String?> Function(String path)? rootLocatorFor,
}) async {
  final locator = track.localMediaUri ?? '';
  if (locator.isEmpty) {
    throw UnsupportedError(
      'No localMediaUri for local track "${track.title}" (id=${track.id})',
    );
  }

  if (Uri.tryParse(locator)?.scheme == 'pp-local') {
    final path = await ManagedLocalFileStore().resolve(locator);
    return AuthorizedFileLease(
      canonicalPath: await File(path).resolveSymbolicLinks(),
    );
  }

  // ── Plain path or file:// URI (folder children / managed copies) ─────────
  // Folder imports persist children as plain paths plus the bookmark of their
  // root. In a sandboxed build the plain path is unreadable after restart, so
  // on macOS first re-acquire the root bookmark and hold it for the lease's
  // lifetime. Unsandboxed builds (or a stale root) fall back to the path.
  final uri = Uri.tryParse(locator);
  final plainPath = (uri != null && uri.scheme == 'file')
      ? File.fromUri(uri).path
      : (locator.startsWith('/') ? locator : null);
  if (plainPath != null) {
    if (Platform.isMacOS && rootLocatorFor != null) {
      final rootLocator = await rootLocatorFor(plainPath);
      if (rootLocator != null) {
        final rootPath = await resolveSecurityScopedBookmark(rootLocator);
        if (rootPath != null) {
          try {
            final canonicalRoot = await Directory(
              rootPath,
            ).resolveSymbolicLinks();
            final canonicalPath = await File(plainPath).resolveSymbolicLinks();
            if (p.isWithin(canonicalRoot, canonicalPath)) {
              debugPrint('[Output] file_lease.root_bookmark access=active');
              return AuthorizedFileLease(
                canonicalPath: canonicalPath,
                onRelease: () async {
                  await stopAccessingSecurityScopedBookmark(rootLocator);
                  debugPrint('[Output] file_lease.released access=stopped');
                },
              );
            }
          } catch (_) {
            // Fall through to the plain-path attempt below after releasing.
          }
          await stopAccessingSecurityScopedBookmark(rootLocator);
        }
      }
    }
    return AuthorizedFileLease(
      canonicalPath: await File(plainPath).resolveSymbolicLinks(),
      // No security-scoped resource; no release action needed.
    );
  }

  // ── iOS security-scoped bookmark (base64 NSData) ─────────────────────────
  // resolveSecurityScopedBookmark calls startAccessingSecurityScopedResource
  // on the native side and returns the resolved absolute path.
  try {
    if (base64.decode(locator).isEmpty) throw const FormatException();
  } on FormatException {
    throw UnsupportedError('Invalid security-scoped bookmark');
  }
  final path = await resolveSecurityScopedBookmark(locator);
  if (path == null) {
    throw UnsupportedError(
      'Could not resolve iOS security-scoped bookmark for '
      '"${track.title}" — the file may have been moved or access revoked.',
    );
  }
  late String canonicalPath;
  try {
    canonicalPath = await File(path).resolveSymbolicLinks();
  } catch (_) {
    await stopAccessingSecurityScopedBookmark(locator);
    rethrow;
  }
  debugPrint('[Output] file_lease.bookmark_resolved access=active');
  return AuthorizedFileLease(
    canonicalPath: canonicalPath,
    // stopAccessingSecurityScopedResource() is called when the LocalMediaServer
    // has finished streaming the file (or on error). This prevents resource
    // exhaustion from too many concurrent security-scoped accesses.
    onRelease: () async {
      await stopAccessingSecurityScopedBookmark(locator);
      debugPrint('[Output] file_lease.released access=stopped');
    },
  );
}
