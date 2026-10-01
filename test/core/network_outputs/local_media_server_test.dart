import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/local_media_server.dart';

// ──────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────

/// Fake clock for expiry tests.
DateTime Function() _fakeClock(DateTime initial) {
  DateTime current = initial;
  return () => current;
}

/// Build a server that binds to loopback for test purposes.
LocalMediaServer makeServer({
  Duration tokenLifetime = const Duration(hours: 1),
}) => LocalMediaServer(
  routeResolver: (_) async => InternetAddress.loopbackIPv4,
  clock: _fakeClock(DateTime(2025)),
  tokenLifetime: tokenLifetime,
  allowLoopbackForTests: true,
);

/// Write a temp file and return an [AuthorizedFileLease] pointing to it.
Future<AuthorizedFileLease> tempFile(
  Directory dir,
  String name,
  Uint8List content,
) async {
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(content);
  // Resolve once; symlink not involved in this test helper.
  final canonical = await file.resolveSymbolicLinks();
  return AuthorizedFileLease(canonicalPath: canonical);
}

final _rendererUri = Uri.parse('http://192.168.1.100:1234/desc.xml');

// ──────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('ppplayer_lms_test_');
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  group('LocalMediaServer — file serving', () {
    test('GET full file returns 200 with correct body', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(512, (i) => i % 256));
      final lease = await tempFile(tmpDir, 'song.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      final resp = await req.close();

      expect(resp.statusCode, 200);
      expect(resp.headers.value(HttpHeaders.contentTypeHeader), 'audio/mpeg');
      expect(resp.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');
      final body = await resp.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      expect(body, data);
    });

    test('HEAD returns headers only, no body', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(100, (i) => i));
      final lease = await tempFile(tmpDir, 'track.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.headUrl(url.uri);
      final resp = await req.close();

      expect(resp.statusCode, 200);
      expect(resp.contentLength, data.length);
      final body = await resp.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      expect(body, isEmpty);
    });

    test('Range request returns 206 with correct slice', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(200, (i) => i % 256));
      final lease = await tempFile(tmpDir, 'range.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=10-19');
      final resp = await req.close();

      expect(resp.statusCode, 206);
      expect(
        resp.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 10-19/200',
      );
      expect(resp.contentLength, 10);
      final body = await resp.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      expect(body, data.sublist(10, 20));
    });

    test('open-ended Range request returns from start to end', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(100, (i) => i));
      final lease = await tempFile(tmpDir, 'oe.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=50-');
      final resp = await req.close();

      expect(resp.statusCode, 206);
      final body = await resp.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      expect(body, data.sublist(50));
    });

    test('suffix Range request returns the last N bytes', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(50, (i) => i));
      final lease = await tempFile(tmpDir, 'suf.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=-10');
      final resp = await req.close();

      expect(resp.statusCode, 206);
      final body = await resp.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      expect(body, data.sublist(40));
    });

    test('invalid Range returns 416', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(50, (i) => i));
      final lease = await tempFile(tmpDir, 'inv.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=999-9999');
      final resp = await req.close();

      expect(resp.statusCode, 416);
    });

    test('out-of-bounds Range returns 416', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(10, (i) => i));
      final lease = await tempFile(tmpDir, 'oob.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=100-200');
      final resp = await req.close();

      expect(resp.statusCode, 416);
    });

    test('Content-Length matches body length for full GET', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList(List.generate(300, (i) => i % 200));
      final lease = await tempFile(tmpDir, 'cl.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      final resp = await req.close();

      expect(resp.contentLength, data.length);
      final body = await resp.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      expect(body.length, data.length);
    });

    test('URL does not expose physical filesystem path', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList([0, 1, 2]);
      final lease = await tempFile(tmpDir, 'secret.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      expect(url.uri.path, isNot(contains(tmpDir.path)));
      expect(url.uri.toString(), isNot(contains('secret.mp3')));
    });

    test('unknown token returns 404', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      // Start server with one real file first
      final data = Uint8List.fromList([1, 2, 3]);
      final lease = await tempFile(tmpDir, 'seed.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final bad = url.uri.replace(path: '/media/${'x' * 43}');
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(bad);
      final resp = await req.close();

      expect(resp.statusCode, 404);
    });

    test('revoked token returns 404', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      // Keep an anchor lease alive so the server stays running after we revoke.
      final anchor = await tempFile(
        tmpDir,
        'anchor_rev.mp3',
        Uint8List.fromList([0x00]),
      );
      final anchorUrl = await server.authorizeFile(
        file: anchor,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(anchorUrl.release);

      final data = Uint8List.fromList([0xAA, 0xBB]);
      final lease = await tempFile(tmpDir, 'revoked.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      await url.release(); // revoke it

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      final resp = await req.close();

      expect(resp.statusCode, 404);
    });

    test('MIME type is preserved in Content-Type', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList([0, 1, 2, 3]);
      final lease = await tempFile(tmpDir, 'vid.mp4', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'video/mp4',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.headUrl(url.uri);
      final resp = await req.close();

      expect(resp.headers.value(HttpHeaders.contentTypeHeader), 'video/mp4');
    });

    test('multiple leases can coexist', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final d1 = Uint8List.fromList([0x01]);
      final d2 = Uint8List.fromList([0x02]);
      final l1 = await tempFile(tmpDir, 'a.mp3', d1);
      final l2 = await tempFile(tmpDir, 'b.mp3', d2);
      final u1 = await server.authorizeFile(
        file: l1,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      final u2 = await server.authorizeFile(
        file: l2,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(u1.release);
      addTearDown(u2.release);

      expect(u1.uri.path, isNot(u2.uri.path));
      expect(server.authorizedResourceCount, 2);
    });

    test('releasing one lease does not affect another', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final d1 = Uint8List.fromList(List.generate(10, (i) => i));
      final d2 = Uint8List.fromList(List.generate(10, (i) => i + 100));
      final l1 = await tempFile(tmpDir, 'c.mp3', d1);
      final l2 = await tempFile(tmpDir, 'd.mp3', d2);
      final u1 = await server.authorizeFile(
        file: l1,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      final u2 = await server.authorizeFile(
        file: l2,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(u2.release);

      await u1.release();

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(u2.uri);
      final resp = await req.close();

      expect(resp.statusCode, 200);
      final body = await resp.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      expect(body, d2);
    });
  });

  group('LocalMediaServer.parseByteRange', () {
    test(
      'full range',
      () => expect(LocalMediaServer.parseByteRange('bytes=0-99', 100), (0, 99)),
    );
    test(
      'clamped end',
      () =>
          expect(LocalMediaServer.parseByteRange('bytes=0-999', 100), (0, 99)),
    );
    test(
      'open-ended',
      () => expect(LocalMediaServer.parseByteRange('bytes=50-', 100), (50, 99)),
    );
    test(
      'suffix',
      () => expect(LocalMediaServer.parseByteRange('bytes=-10', 100), (90, 99)),
    );
    test(
      'null on empty file',
      () => expect(LocalMediaServer.parseByteRange('bytes=0-0', 0), isNull),
    );
    test(
      'null on bad format',
      () => expect(LocalMediaServer.parseByteRange('invalid', 100), isNull),
    );
    test(
      'null on both empty',
      () => expect(LocalMediaServer.parseByteRange('bytes=-', 100), isNull),
    );
    test(
      'null when start >= length',
      () =>
          expect(LocalMediaServer.parseByteRange('bytes=100-200', 100), isNull),
    );
    test(
      'null when end < start',
      () => expect(LocalMediaServer.parseByteRange('bytes=50-10', 100), isNull),
    );
  });

  group('LocalMediaServer — security', () {
    test('expired token (clock advanced) returns 404', () async {
      DateTime current = DateTime(2025);
      final server = LocalMediaServer(
        routeResolver: (_) async => InternetAddress.loopbackIPv4,
        clock: () => current,
        tokenLifetime: const Duration(minutes: 5),
        allowLoopbackForTests: true,
      );
      addTearDown(server.dispose);

      final data = Uint8List.fromList([0xCC]);
      final lease = await tempFile(tmpDir, 'exp.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      // Advance clock past expiry
      current = DateTime(2025).add(const Duration(hours: 1));

      // Keep an anchor lease alive so the server stays running after expiry.
      // Created after advancing the clock so it doesn't expire.
      final anchor = await tempFile(
        tmpDir,
        'anchor_exp.mp3',
        Uint8List.fromList([0x00]),
      );
      final anchorUrl = await server.authorizeFile(
        file: anchor,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(anchorUrl.release);

      await server.expireResources();

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(url.uri);
      final resp = await req.close();

      expect(resp.statusCode, 404);
    });

    test('query string on valid token is rejected with 404', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList([0xDD]);
      final lease = await tempFile(tmpDir, 'qs.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final badUri = url.uri.replace(queryParameters: {'x': '1'});
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.getUrl(badUri);
      final resp = await req.close();

      expect(resp.statusCode, 404);
    });

    test('POST is rejected with 405', () async {
      final server = makeServer();
      addTearDown(server.dispose);

      final data = Uint8List.fromList([0xEE]);
      final lease = await tempFile(tmpDir, 'post.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );
      addTearDown(url.release);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final req = await client.postUrl(url.uri);
      final resp = await req.close();

      expect(resp.statusCode, 405);
    });
  });

  group('LocalMediaServer — dispose', () {
    test('dispose closes server and subsequent requests fail', () async {
      final server = makeServer();
      final data = Uint8List.fromList([0xFF]);
      final lease = await tempFile(tmpDir, 'disp.mp3', data);
      final url = await server.authorizeFile(
        file: lease,
        renderer: _rendererUri,
        mimeType: 'audio/mpeg',
      );

      await server.dispose();

      final client = HttpClient()..idleTimeout = const Duration(seconds: 2);
      addTearDown(() => client.close(force: true));
      await expectLater(
        client.getUrl(url.uri).timeout(const Duration(seconds: 3)),
        throwsA(anything),
      );
    });

    test('dispose twice does not throw', () async {
      final server = makeServer();
      await server.dispose();
      await expectLater(server.dispose(), completes);
    });
  });
}
