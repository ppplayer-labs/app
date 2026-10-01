import 'dart:io';

import 'package:pp_playback_engine/pp_playback_engine.dart';

import 'capability_resolver.dart';
import 'local_media_server.dart';
import 'models.dart';

typedef AcquireOutputFileLease =
    Future<AuthorizedFileLease> Function(PlaybackTrack track);

class DefaultNetworkMediaFactory implements NetworkMediaFactory {
  DefaultNetworkMediaFactory({
    required this.server,
    AcquireOutputFileLease? acquireFileLease,
  }) : _acquireFileLease = acquireFileLease ?? acquireDirectFile;
  final LocalMediaServer server;
  final AcquireOutputFileLease _acquireFileLease;

  static Future<AuthorizedFileLease> acquireDirectFile(
    PlaybackTrack track,
  ) async {
    var uri = Uri.tryParse(track.localMediaUri ?? '');
    if (uri != null && uri.scheme.isEmpty && uri.path.startsWith('/')) {
      uri = Uri.file(uri.path);
    }
    if (uri == null || uri.scheme != 'file') {
      throw UnsupportedError(
        'This local source needs a native file access lease: ${track.localMediaUri}',
      );
    }
    return AuthorizedFileLease(
      canonicalPath: await File.fromUri(uri).resolveSymbolicLinks(),
    );
  }

  @override
  Future<NetworkMediaLease> prepare(
    PlaybackTrack track,
    PlaybackOutput output, {
    required String sessionId,
    required String itemId,
  }) async {
    if (track.sourceType == PlaybackSourceType.online) {
      throw UnsupportedError(
        "This source can't currently be played on this output.",
      );
    }
    final endpoint = output.endpointUri ?? Uri.parse('http://8.8.8.8');
    var mime = OutputCapabilityResolver.mimeTypeForTrack(track);
    if (mime == 'video/mp4' && !track.isVideo) mime = 'audio/mp4';
    LocalMediaUrl? authorized;
    late Uri uri;
    try {
      if (track.isLocal) {
        final file = await _acquireFileLease(track);
        mime ??= OutputCapabilityResolver.mimeTypeForUri(
          Uri.file(file.canonicalPath),
        );
        if (mime == 'video/mp4' && !track.isVideo) mime = 'audio/mp4';
        if (mime == null) {
          await file.release();
          throw UnsupportedError('This local media format is unknown');
        }
        authorized = await server.authorizeFile(
          file: file,
          renderer: endpoint,
          mimeType: mime,
        );
        uri = authorized.uri;
      } else {
        final upstream = Uri.tryParse(track.networkMediaUri ?? '');
        if (upstream == null ||
            !{'http', 'https'}.contains(upstream.scheme) ||
            upstream.host.isEmpty ||
            upstream.userInfo.isNotEmpty) {
          throw UnsupportedError(
            'Network outputs require an HTTP or HTTPS media URL',
          );
        }
        mime ??= await _probeMime(upstream, track.httpHeaders ?? const {});
        if (mime == null || mime == 'application/octet-stream') {
          throw UnsupportedError(
            'The stream did not identify a supported media format',
          );
        }
        final headers = track.httpHeaders ?? const <String, String>{};
        final senderOnly =
            upstream.host == 'localhost' ||
            InternetAddress.tryParse(upstream.host)?.isLoopback == true;
        if (headers.isNotEmpty || senderOnly) {
          if (mime == 'application/vnd.apple.mpegurl' ||
              mime == 'application/x-mpegurl' ||
              mime == 'application/dash+xml') {
            throw UnsupportedError(
              'Authenticated adaptive streams need a manifest-aware proxy',
            );
          }
          authorized = await server.authorizeProxy(
            upstream: upstream,
            headers: headers,
            renderer: endpoint,
            mimeType: mime,
          );
          uri = authorized.uri;
        } else {
          uri = upstream;
        }
      }
      if (!output.capabilities.supportsMimeType(mime)) {
        throw UnsupportedError(
          'This output has not advertised support for $mime',
        );
      }
      final artwork = Uri.tryParse(track.artworkUrl ?? '');
      final item = NetworkMediaItem(
        uri: uri,
        mimeType: mime,
        title: track.title,
        artist: track.artist,
        album: track.album,
        artworkUri:
            artwork != null && {'http', 'https'}.contains(artwork.scheme)
            ? artwork
            : null,
        duration: track.liveStatus == PlaybackLiveStatus.live
            ? null
            : track.duration,
        isVideo: track.isVideo,
        isLive: track.liveStatus == PlaybackLiveStatus.live,
        protocolInfo: 'http-get:*:$mime:*',
      );
      return NetworkMediaLease(
        item: item,
        requiresSender: authorized != null,
        release: authorized == null ? () async {} : authorized.release,
      );
    } catch (_) {
      await authorized?.release();
      rethrow;
    }
  }

  Future<String?> _probeMime(
    Uri initial,
    Map<String, String> initialHeaders,
  ) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      var uri = initial;
      var headers = initialHeaders;
      for (var redirects = 0; redirects <= 5; redirects++) {
        final request = await client.headUrl(uri);
        request.followRedirects = false;
        headers.forEach((key, value) {
          request.headers.set(key, value);
        });
        final response = await request.close().timeout(
          const Duration(seconds: 6),
        );
        final type = response.headers.contentType?.mimeType.toLowerCase();
        if (![301, 302, 303, 307, 308].contains(response.statusCode)) {
          return response.statusCode >= 200 && response.statusCode < 300
              ? type
              : null;
        }
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) return null;
        final next = uri.resolve(location);
        if (!{'http', 'https'}.contains(next.scheme) ||
            next.userInfo.isNotEmpty)
          return null;
        if (uri.origin != next.origin) headers = const {};
        uri = next;
      }
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
