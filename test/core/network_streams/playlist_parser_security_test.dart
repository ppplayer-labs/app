import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/network_streams/network_stream_service.dart';
import 'package:ppplayer/core/network_streams/playlist_parser.dart';
import 'package:ppplayer/core/services/secure_credentials_service.dart';

class _CapturingHttpClient extends http.BaseClient {
  Uri? lastUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"title":"Safe Title"}')),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  group('PlaylistParser security and malformed input hardening', () {
    test(
      'handles malformed percent-encoding in M3U pipe headers without throwing',
      () {
        const m3u = '''#EXTM3U
#EXTINF:-1,Malformed Header Stream
https://example.com/live.m3u8|User-Agent=Player%ZZ&Referer=100%
''';
        final result = PlaylistParser.parseString(
          m3u,
          'https://example.com/list.m3u',
        );

        expect(result.type, PlaylistType.channelList);
        expect(result.channels, hasLength(1));
        expect(result.channels.first.url, 'https://example.com/live.m3u8');
        expect(result.channels.first.httpHeaders?['User-Agent'], 'Player%ZZ');
        expect(result.channels.first.httpHeaders?['Referer'], '100%');
      },
    );

    test(
      'handles single-character quote lines without throwing RangeError',
      () {
        const m3u = '''#EXTM3U
#EXTINF:-1,Bad Quote
"
#EXTINF:-1,Valid Channel
https://example.com/ok.m3u8
''';
        final result = PlaylistParser.parseString(
          m3u,
          'https://example.com/list.m3u',
        );

        expect(result.type, PlaylistType.channelList);
        expect(result.channels, hasLength(1));
        expect(result.channels.first.url, 'https://example.com/ok.m3u8');
      },
    );

    test('ignores integer-overflow PLS entry numbers safely', () {
      const pls = '''[playlist]
File999999999999999999999999=https://example.com/overflow.mp3
File1=https://example.com/valid.mp3
Title1=Valid Stream
''';
      final result = PlaylistParser.parseString(pls, 'https://example.com');

      expect(result.type, PlaylistType.channelList);
      expect(result.channels, hasLength(1));
      expect(result.channels.first.url, 'https://example.com/valid.mp3');
    });

    test(
      'blocks dangerous non-network schemes in M3U, PLS, XSPF, and ASX playlists',
      () {
        const m3u = '''#EXTM3U
#EXTINF:-1,Local File
file:///etc/passwd
#EXTINF:-1,JS Injection
javascript:alert(1)
#EXTINF:-1,Data URI
data:text/html,<script>alert(1)</script>
#EXTINF:-1,Safe RTSP
rtsp://stream.example.com/live
#EXTINF:-1,Safe HTTPS
https://stream.example.com/live.m3u8
''';
        final m3uResult = PlaylistParser.parseString(
          m3u,
          'https://example.com/list.m3u',
        );
        expect(m3uResult.channels.map((c) => c.url), [
          'rtsp://stream.example.com/live',
          'https://stream.example.com/live.m3u8',
        ]);

        const pls = '''[playlist]
File1=file:///etc/passwd
File2=https://stream.example.com/radio
''';
        final plsResult = PlaylistParser.parseString(
          pls,
          'https://example.com',
        );
        expect(plsResult.channels.map((c) => c.url), [
          'https://stream.example.com/radio',
        ]);

        const xspf = '''<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <trackList>
    <track><location>file:///secret</location></track>
    <track><location>https://stream.example.com/xspf</location></track>
  </trackList>
</playlist>''';
        final xspfResult = PlaylistParser.parseString(
          xspf,
          'https://example.com',
        );
        expect(xspfResult.channels.map((c) => c.url), [
          'https://stream.example.com/xspf',
        ]);

        const asx = '''<asx>
  <entry><ref href="javascript:evil()" /></entry>
  <entry><ref href="https://stream.example.com/asx" /></entry>
</asx>''';
        final asxResult = PlaylistParser.parseString(
          asx,
          'https://example.com',
        );
        expect(asxResult.channels.map((c) => c.url), [
          'https://stream.example.com/asx',
        ]);
      },
    );

    test('fetchAndParse rejects non-http/https schemes', () async {
      await expectLater(
        PlaylistParser.fetchAndParse('file:///etc/passwd'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        PlaylistParser.fetchAndParse('javascript:alert(1)'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('NetworkStreamService security and malformed input hardening', () {
    late AppDatabase db;
    late NetworkStreamService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = NetworkStreamService(db, SecureCredentialsService());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'extractDirectStreamUrl handles malformed percent-encoding safely',
      () async {
        final extracted = await service.extractDirectStreamUrl(
          'https://example.com/live.m3u8|User-Agent=Bad%ZZ',
        );
        expect(extracted, isNotNull);
        expect(extracted!.url, 'https://example.com/live.m3u8');
        expect(extracted.httpHeaders?['User-Agent'], 'Bad%ZZ');
      },
    );

    test(
      'extractDirectStreamUrl handles trailing /video Dailymotion URL safely',
      () async {
        final extracted = await service.extractDirectStreamUrl(
          'https://www.dailymotion.com/video',
        );
        expect(extracted, isNull);
      },
    );

    test(
      'fetchVideoMetadata properly URL-encodes query parameters to prevent injection',
      () async {
        final client = _CapturingHttpClient();
        const rawUrl = 'https://www.youtube.com/watch?v=abc123&injected=1';
        await service.fetchVideoMetadata(rawUrl, client: client);

        expect(client.lastUri, isNotNull);
        expect(client.lastUri!.queryParameters['url'], rawUrl);
        expect(
          client.lastUri!.queryParameters.containsKey('injected'),
          isFalse,
        );
        expect(client.lastUri!.queryParameters['format'], 'json');
      },
    );
  });
}
