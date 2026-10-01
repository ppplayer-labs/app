import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Access is acquired before authorization and retained for the entire URL lease.
/// Native implementations retain security-scoped resources or a temporary copy.
class AuthorizedFileLease {
  AuthorizedFileLease({required this.canonicalPath, this.onRelease});
  final String canonicalPath;
  final Future<void> Function()? onRelease;
  Future<void>? _release;
  Future<void> release() => _release ??= Future.sync(() async {
    await onRelease?.call();
  });
}

class LocalMediaUrl {
  LocalMediaUrl._(this.uri, this._revoke);
  final Uri uri;
  final Future<void> Function() _revoke;
  Future<void>? _release;
  Future<void> release() => _release ??= _revoke();
  // Never print the bearer token contained in uri.
  @override
  String toString() => 'LocalMediaUrl(authorized)';
}

typedef RendererRouteResolver = Future<InternetAddress> Function(Uri renderer);

/// A session-scoped allowlist, never a directory or arbitrary proxy endpoint.
class LocalMediaServer {
  LocalMediaServer({
    RendererRouteResolver? routeResolver,
    DateTime Function()? clock,
    this.tokenLifetime = const Duration(hours: 12),
    this.allowLoopbackForTests = false,
  }) : _routeResolver = routeResolver ?? routeToRenderer,
       _clock = clock ?? DateTime.now;

  final RendererRouteResolver _routeResolver;
  final DateTime Function() _clock;
  final Duration tokenLifetime;
  final bool allowLoopbackForTests;
  final _resources = <String, _AuthorizedResource>{};
  final _random = Random.secure();
  HttpServer? _server;
  Future<void>? _starting;
  Timer? _expiry;
  bool _disposed = false;

  int get authorizedResourceCount => _resources.length;
  bool get isListening => _server != null;

  /// Returns the currently active URLs for debugging purposes.
  List<Uri> get debugActiveUrls {
    if (_server == null) return const [];
    return _resources.keys.map((token) {
      return Uri(
        scheme: 'http',
        host: _server!.address.address,
        port: _server!.port,
        path: '/media/$token',
      );
    }).toList();
  }

  /// Ask the OS route to the selected renderer, rather than choosing the first
  /// Wi-Fi/VPN/virtual interface returned by NetworkInterface.list().
  static Future<InternetAddress> routeToRenderer(Uri renderer) async {
    if (!{'http', 'https'}.contains(renderer.scheme) || renderer.host.isEmpty) {
      throw const FormatException('Renderer has no HTTP endpoint');
    }

    final targetHost = renderer.host;
    InternetAddress? targetAddr;
    try {
      final lookup = await InternetAddress.lookup(targetHost);
      targetAddr = lookup.firstWhere(
        (a) => a.type == InternetAddressType.IPv4,
        orElse: () => lookup.first,
      );
    } catch (_) {
      targetAddr = InternetAddress.tryParse(targetHost);
    }

    if (targetAddr == null) {
      throw const FormatException('Renderer hostname could not be resolved');
    }

    try {
      final port = renderer.hasPort ? renderer.port : 80;
      final socket = await Socket.connect(
        targetAddr,
        port,
        timeout: const Duration(seconds: 2),
      );
      final localAddress = socket.address;
      socket.destroy();

      if (kDebugMode) {
        debugPrint(
          '[Output] local_server.route renderer=${targetAddr.address} local=${localAddress.address} source=os_route',
        );
      }
      return localAddress;
    } catch (_) {
      // Fallback interface scoring
    }

    final interfaces = await NetworkInterface.list(
      includeLoopback: true,
      type: InternetAddressType.IPv4,
    );
    if (interfaces.isEmpty) {
      throw StateError('No active network interfaces found');
    }

    final local = selectBestInterface(targetAddr, interfaces);
    if (kDebugMode) {
      debugPrint(
        '[Output] local_server.route renderer=${targetAddr.address} local=${local.address} source=fallback',
      );
    }
    return local;
  }

  @visibleForTesting
  static InternetAddress selectBestInterface(
    InternetAddress targetAddr,
    List<NetworkInterface> interfaces,
  ) {
    bool isLinkLocal(InternetAddress a) => a.address.startsWith('169.254.');
    bool isPrivate(InternetAddress a) =>
        a.address.startsWith('10.') ||
        a.address.startsWith('192.168.') ||
        (a.address.startsWith('172.') &&
            (int.tryParse(a.address.split('.')[1]) ?? 0) >= 16 &&
            (int.tryParse(a.address.split('.')[1]) ?? 0) <= 31);

    final targetIsLinkLocal = isLinkLocal(targetAddr);
    final targetIsPrivate = isPrivate(targetAddr);

    InternetAddress? bestAddr;
    int bestScore = -1;

    for (final interface in interfaces) {
      final isVpn =
          interface.name.toLowerCase().contains('tun') ||
          interface.name.toLowerCase().contains('tap') ||
          interface.name.toLowerCase().contains('tailscale') ||
          interface.name.toLowerCase().contains('docker') ||
          interface.name.toLowerCase().contains('vbox') ||
          interface.name.toLowerCase().contains('vmware');

      for (final addr in interface.addresses) {
        if (addr.type != InternetAddressType.IPv4) continue;
        if (addr.isLoopback && !targetAddr.isLoopback) continue;
        if (isLinkLocal(addr) && !targetIsLinkLocal) continue;

        int score = 0;

        // Exact subnet match (leading 3 octets)
        final targetRaw = targetAddr.rawAddress;
        final localRaw = addr.rawAddress;
        if (targetRaw[0] == localRaw[0] &&
            targetRaw[1] == localRaw[1] &&
            targetRaw[2] == localRaw[2]) {
          score += 100;
        }

        if (isPrivate(addr) && targetIsPrivate) score += 50;
        if (!isVpn) score += 20;

        if (score > bestScore) {
          bestScore = score;
          bestAddr = addr;
        }
      }
    }

    return bestAddr ?? interfaces.first.addresses.first;
  }

  Future<void> _ensureStarted(Uri renderer) {
    final previous = _starting;
    final start = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      await _startForRoute(renderer);
    }();
    _starting = start;
    return start.whenComplete(() {
      if (identical(_starting, start)) _starting = null;
    });
  }

  Future<void> _startForRoute(Uri renderer) async {
    if (_disposed) throw StateError('Media server is disposed');
    final address = await _routeResolver(renderer);
    if (address.type != InternetAddressType.IPv4) {
      throw UnsupportedError('Local serving currently requires an IPv4 route');
    }
    if (address.address == '0.0.0.0' ||
        (address.isLoopback && !allowLoopbackForTests)) {
      throw StateError('No LAN-reachable route to the renderer');
    }
    if (_server?.address.address == address.address) return;
    if (_resources.isNotEmpty) {
      throw StateError(
        'Release the previous media session before changing LAN',
      );
    }
    await _server?.close(force: true);
    _server = null;
    await HttpServer.bind(address, 0).then((server) {
      if (_disposed) {
        server.close(force: true);
        throw StateError('Media server is disposed');
      }
      server.idleTimeout = const Duration(seconds: 30);
      _server = server;
      debugPrint(
        '[Output] local_server.start interface=${address.address} port=${server.port}',
      );
      server.listen((request) {
        unawaited(_handle(request));
      }, onError: (Object _) {});
    });
  }

  Future<LocalMediaUrl> authorizeFile({
    required AuthorizedFileLease file,
    required Uri renderer,
    required String mimeType,
  }) async {
    try {
      final canonical = await File(file.canonicalPath).resolveSymbolicLinks();
      if (canonical != file.canonicalPath ||
          await FileSystemEntity.type(canonical) != FileSystemEntityType.file) {
        throw StateError('Media lease must authorize a canonical regular file');
      }
      await _ensureStarted(renderer);
      return _authorize(
        _AuthorizedResource(
          expires: _clock().add(tokenLifetime),
          mimeType: mimeType,
          file: file,
        ),
      );
    } catch (_) {
      await file.release();
      rethrow;
    }
  }

  /// Explicit upstream authorization; request parameters can never choose a URL
  /// or headers. Authentication is stripped on cross-origin redirects.
  Future<LocalMediaUrl> authorizeProxy({
    required Uri upstream,
    required Map<String, String> headers,
    required Uri renderer,
    required String mimeType,
  }) async {
    if (!{'http', 'https'}.contains(upstream.scheme) ||
        upstream.host.isEmpty ||
        upstream.userInfo.isNotEmpty) {
      throw const FormatException('Proxy requires an explicit HTTP media URL');
    }
    await _ensureStarted(renderer);
    return _authorize(
      _AuthorizedResource(
        expires: _clock().add(tokenLifetime),
        mimeType: mimeType,
        upstream: upstream,
        headers: Map.unmodifiable(headers),
      ),
    );
  }

  LocalMediaUrl _authorize(_AuthorizedResource resource) {
    if (_disposed) throw StateError('Media server is disposed');
    final token = base64Url
        .encode(List.generate(32, (_) => _random.nextInt(256)))
        .replaceAll('=', '');
    _resources[token] = resource;
    _expiry ??= Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(expireResources());
    });
    final server = _server!;
    return LocalMediaUrl._(
      Uri(
        scheme: 'http',
        host: server.address.address,
        port: server.port,
        path: '/media/$token',
      ),
      () => _revoke(token),
    );
  }

  Future<void> _revoke(String token) async {
    final resource = _resources.remove(token);
    if (resource == null) return;
    resource.revoked = true;
    // Reject new requests immediately, but retain file access until every
    // already accepted HTTP read has drained and closed its file stream.
    await Future.wait(resource.reads.toList().map((read) => read.future));
    if (_resources.isEmpty) {
      _expiry?.cancel();
      _expiry = null;
      final server = _server;
      _server = null;
      if (server != null) {
        debugPrint('[Output] local_server.stop');
        await server.close(force: true);
      }
    }
    await resource.file?.release();
  }

  Future<void> expireResources() async {
    final now = _clock();
    for (final entry in _resources.entries.toList()) {
      if (!entry.value.expires.isAfter(now)) await _revoke(entry.key);
    }
  }

  bool _valid(_AuthorizedResource resource) =>
      !resource.revoked && resource.expires.isAfter(_clock()) && !_disposed;

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    final match = RegExp(
      r'^/media/([A-Za-z0-9_-]{43})$',
    ).firstMatch(request.uri.path);
    final resource = match == null || request.uri.hasQuery
        ? null
        : _resources[match.group(1)];
    if (resource == null || !_valid(resource)) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    if (request.method == 'GET') {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      debugPrint(
        '[Output] local_server.request method=GET range=${range != null}',
      );
    } else if (request.method == 'HEAD') {
      debugPrint('[Output] local_server.request method=HEAD');
    }

    if (!{'GET', 'HEAD'}.contains(request.method)) {
      response.statusCode = HttpStatus.methodNotAllowed;
      response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
      await response.close();
      return;
    }
    final read = Completer<void>();
    resource.reads.add(read);
    resource.responses.add(response);
    try {
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      response.headers.set('X-Content-Type-Options', 'nosniff');
      if (resource.file != null) {
        await _serveFile(request, resource);
      } else {
        await _serveProxy(request, resource);
      }
    } catch (_) {
      // Errors must never expose a filesystem path, URL, token, or headers.
      try {
        response.statusCode = HttpStatus.badGateway;
      } catch (_) {}
    } finally {
      try {
        await response.close();
      } catch (_) {}
      resource.responses.remove(response);
      resource.reads.remove(read);
      read.complete();
    }
  }

  Future<void> _serveFile(
    HttpRequest request,
    _AuthorizedResource resource,
  ) async {
    final file = File(resource.file!.canonicalPath);
    // A changed symlink must not expand the authorization to another file.
    if (await file.resolveSymbolicLinks() != resource.file!.canonicalPath) {
      request.response.statusCode = HttpStatus.notFound;
      return;
    }
    final length = await file.length();
    final response = request.response;
    response.headers.set(HttpHeaders.contentTypeHeader, resource.mimeType);
    response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    var start = 0;
    var end = length - 1;
    final range = request.method == 'GET'
        ? request.headers.value(HttpHeaders.rangeHeader)
        : null;
    if (range != null) {
      final parsed = parseByteRange(range, length);
      if (parsed == null) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$length');
        response.contentLength = 0;
        return;
      }
      start = parsed.$1;
      end = parsed.$2;
      response.statusCode = HttpStatus.partialContent;
      response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$end/$length',
      );
    }
    response.contentLength = length == 0 ? 0 : end - start + 1;
    if (request.method == 'HEAD' || length == 0) return;
    await response.addStream(file.openRead(start, end + 1));
  }

  static (int, int)? parseByteRange(String header, int length) {
    if (length <= 0) return null;
    final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
    if (match == null || (match.group(1)!.isEmpty && match.group(2)!.isEmpty))
      return null;
    if (match.group(1)!.isEmpty) {
      final suffix = int.tryParse(match.group(2)!);
      if (suffix == null || suffix <= 0) return null;
      return (max(0, length - suffix), length - 1);
    }
    final start = int.tryParse(match.group(1)!);
    final requestedEnd = match.group(2)!.isEmpty
        ? length - 1
        : int.tryParse(match.group(2)!);
    if (start == null ||
        requestedEnd == null ||
        start >= length ||
        requestedEnd < start)
      return null;
    return (start, min(requestedEnd, length - 1));
  }

  Future<void> _serveProxy(
    HttpRequest request,
    _AuthorizedResource resource,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..autoUncompress = false;
    resource.clients.add(client);
    try {
      var uri = resource.upstream!;
      var headers = resource.headers;
      HttpClientResponse? upstream;
      for (var redirects = 0; redirects <= 5; redirects++) {
        if (!_valid(resource)) return;
        final outgoing = await client.openUrl(request.method, uri);
        outgoing.followRedirects = false;
        headers.forEach((name, value) {
          if (!{
            'host',
            'connection',
            'content-length',
            'transfer-encoding',
            'range',
          }.contains(name.toLowerCase()))
            outgoing.headers.set(name, value);
        });
        final range = request.headers.value(HttpHeaders.rangeHeader);
        if (range != null && request.method == 'GET')
          outgoing.headers.set(HttpHeaders.rangeHeader, range);
        upstream = await outgoing.close().timeout(const Duration(seconds: 10));
        if (![301, 302, 303, 307, 308].contains(upstream.statusCode)) break;
        final location = upstream.headers.value(HttpHeaders.locationHeader);
        if (location == null || redirects == 5)
          throw StateError('Media redirect failed');
        final next = uri.resolve(location);
        if (!{'http', 'https'}.contains(next.scheme) ||
            next.userInfo.isNotEmpty)
          throw StateError('Invalid media redirect');
        if (uri.origin != next.origin) headers = const {};
        uri = next;
        await upstream.drain<void>().timeout(const Duration(seconds: 5));
      }
      if (upstream == null || !_valid(resource)) return;
      request.response.statusCode = upstream.statusCode;
      for (final name in [
        HttpHeaders.contentTypeHeader,
        HttpHeaders.contentLengthHeader,
        HttpHeaders.contentRangeHeader,
        HttpHeaders.acceptRangesHeader,
        HttpHeaders.contentEncodingHeader,
      ]) {
        final value = upstream.headers.value(name);
        if (value != null) request.response.headers.set(name, value);
      }
      if (upstream.headers.value(HttpHeaders.contentTypeHeader) == null)
        request.response.headers.set(
          HttpHeaders.contentTypeHeader,
          resource.mimeType,
        );
      if (request.method != 'HEAD')
        await request.response.addStream(
          upstream.takeWhile((_) => _valid(resource)),
        );
    } finally {
      resource.clients.remove(client);
      client.close(force: true);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final token in _resources.keys.toList()) {
      await _revoke(token);
    }
    await _starting;
    await _server?.close(force: true);
    _server = null;
    _expiry?.cancel();
  }
}

class _AuthorizedResource {
  _AuthorizedResource({
    required this.expires,
    required this.mimeType,
    this.file,
    this.upstream,
    this.headers = const {},
  });
  final DateTime expires;
  final String mimeType;
  final AuthorizedFileLease? file;
  final Uri? upstream;
  final Map<String, String> headers;
  bool revoked = false;
  final reads = <Completer<void>>{};
  final responses = <HttpResponse>{};
  final clients = <HttpClient>{};
}
