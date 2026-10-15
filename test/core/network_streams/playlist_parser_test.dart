import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ppplayer/core/network_streams/playlist_parser.dart';

class MockClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  MockClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}

void main() {
  group('PlaylistParser', () {
    test(
      'Early media classification returns unknown stream and cancels early',
      () async {
        bool streamCancelled = false;
        final controller = StreamController<List<int>>(
          onCancel: () {
            streamCancelled = true;
          },
        );

        final client = MockClient((request) async {
          return http.StreamedResponse(
            controller.stream,
            200,
            headers: {'content-type': 'video/mp4'},
          );
        });

        final futureResult = PlaylistParser.fetchAndParse(
          'http://example.com/stream.mp4',
          client: client,
        );

        // Send some bytes
        controller.add([1, 2, 3]);

        final result = await futureResult;

        expect(result.type, PlaylistType.unknown);
        expect(streamCancelled, true);
      },
    );

    test('M3U parsing correctly decodes split-chunk UTF-8', () async {
      final utf8Payload =
          '#EXTM3U\n#EXTINF:-1,📺 My Channel (Café)\nhttp://example.com/stream.m3u8';
      final encoded = utf8.encode(utf8Payload);

      final client = MockClient((request) async {
        return http.StreamedResponse(
          // Split right in the middle of a multi-byte character
          Stream.fromIterable([encoded.sublist(0, 30), encoded.sublist(30)]),
          200,
          headers: {'content-type': 'application/vnd.apple.mpegurl'},
        );
      });

      final result = await PlaylistParser.fetchAndParse(
        'http://example.com/playlist.m3u8',
        client: client,
      );

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 1);
      expect(result.channels.first.title, '📺 My Channel (Café)');
    });

    test('PLS parsing handles missing fields and non-consecutive indexes', () {
      final content = '''
[playlist]
File2=http://example.com/stream2
Title2=Stream Two
File5=http://example.com/stream5
Length5=-1
File7=http://example.com/stream7
Title7=Stream Seven
      ''';
      final result = PlaylistParser.parseString(content, 'http://example.com');

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 3);
      expect(result.channels[0].title, 'Stream Two');
      expect(result.channels[0].url, 'http://example.com/stream2');
      expect(result.channels[1].title, 'Stream 5'); // Fallback title
      expect(result.channels[1].url, 'http://example.com/stream5');
      expect(result.channels[2].title, 'Stream Seven');
    });

    test('XSPF parsing handles namespaces and alternative locations', () {
      final content = '''<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <trackList>
    <track>
      <title>My XSPF Stream</title>
      <location>http://example.com/1</location>
      <location>http://example.com/backup</location>
    </track>
  </trackList>
</playlist>''';

      final result = PlaylistParser.parseString(content, 'http://example.com');

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 1);
      expect(result.channels[0].title, 'My XSPF Stream');
      expect(
        result.channels[0].url,
        'http://example.com/1',
      ); // Only picks first
    });

    test('ASX parsing handles case-insensitivity', () {
      final content = '''<AsX>
  <EnTrY>
    <tItLe>My ASX Stream</tItLe>
    <rEf HrEf="http://example.com/asx" />
  </EnTrY>
</AsX>''';

      final result = PlaylistParser.parseString(content, 'http://example.com');

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 1);
      expect(result.channels[0].title, 'My ASX Stream');
      expect(result.channels[0].url, 'http://example.com/asx');
    });

    test(
      'Parses encoding properly from headers and enforces UTF-8 for M3U8',
      () async {
        final latin1Payload =
            '\#EXTM3U\n\#EXTINF:-1,* My Channel (Caf\xE9)\nhttp://example.com/stream.m3u8';
        final encoded = latin1.encode(latin1Payload);

        final client = MockClient((request) async {
          return http.StreamedResponse(
            Stream.fromIterable([encoded]),
            200,
            headers: {'content-type': 'application/vnd.apple.mpegurl'},
            request: request,
          );
        });

        // Should fail because M3U8 must be UTF-8 and we gave it latin-1, so utf8.decode throws FormatException
        expect(
          () => PlaylistParser.fetchAndParse(
            'http://example.com/playlist.m3u8',
            client: client,
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'Handles redirects and resolves relative URLs against final URL',
      () async {
        final utf8Payload = '#EXTM3U\n#EXTINF:-1,Test\nstream.m3u8';
        final encoded = utf8.encode(utf8Payload);

        final client = MockClient((request) async {
          // Return a response where the final request URL was modified by redirect
          final finalRequest = http.Request(
            'GET',
            Uri.parse('http://example.com/redirected/folder/playlist.m3u8'),
          );
          return http.StreamedResponse(
            Stream.fromIterable([encoded]),
            200,
            headers: {'content-type': 'application/vnd.apple.mpegurl'},
            request: finalRequest, // Mocks the redirect
          );
        });

        final result = await PlaylistParser.fetchAndParse(
          'http://example.com/original.m3u8',
          client: client,
        );
        expect(
          result.channels.first.url,
          'http://example.com/redirected/folder/stream.m3u8',
        );
      },
    );

    test('Times out if server takes too long to send headers', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return http.StreamedResponse(const Stream.empty(), 200);
      });

      expect(
        () => PlaylistParser.fetchAndParse(
          'http://example.com',
          client: client,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('Times out if server stream hangs during body transfer', () async {
      final client = MockClient((request) async {
        final stream = Stream<List<int>>.periodic(
          const Duration(milliseconds: 100),
          (i) => [i],
        ).take(10);
        return http.StreamedResponse(
          stream,
          200,
          headers: {'content-type': 'application/x-mpegurl'},
        );
      });

      expect(
        () => PlaylistParser.fetchAndParse(
          'http://example.com',
          client: client,
          timeout: const Duration(milliseconds: 150),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test(
      'Stream errors (e.g. connection aborted) are correctly bubbled up',
      () async {
        // Simulate an aborted connection mid-stream
        final client = MockClient((request) async {
          final controller = StreamController<List<int>>();
          controller.add([1, 2, 3]);
          // Emit an error after a short delay
          Future.delayed(const Duration(milliseconds: 50), () {
            controller.addError(http.ClientException('Connection aborted'));
            controller.close();
          });

          return http.StreamedResponse(
            controller.stream,
            200,
            headers: {'content-type': 'application/x-mpegurl'},
          );
        });

        expect(
          () => PlaylistParser.fetchAndParse(
            'http://example.com',
            client: client,
          ),
          throwsA(isA<http.ClientException>()),
        );
      },
    );

    test(
      'IPTV Albanian playlist (al.m3u fixture) parses channels and metadata',
      () {
        final alM3u = '''#EXTM3U
#EXTINF:-1 tvg-id="AlbKanaleMusicTV.al" tvg-logo="https://i.imgur.com/GzB2Pq8.png" group-title="Music",AlbKanale Music TV (720p) [Not 24/7]
https://albportal.net/albkanalemusic.m3u8
#EXTINF:-1 tvg-id="AlpoTV.al" tvg-logo="https://i.imgur.com/dK46r3R.png" group-title="General",Alpo TV (576p)
https://stream.alpotv.com/alpotv/live/playlist.m3u8
#EXTINF:-1 tvg-id="CNA.al" tvg-logo="https://i.imgur.com/Z421lQ8.png" group-title="News",CNA (1080p)
https://live1.mediadesk.al/cnatvlive.m3u8
#EXTINF:-1 tvg-id="Cufo.al" tvg-logo="https://i.imgur.com/tOa7c64.png" group-title="Kids",Cufo (576p) [Not 24/7]
https://cufo-al-stream.example.com/live.m3u8
''';

        final result = PlaylistParser.parseString(
          alM3u,
          'https://raw.githubusercontent.com/iptv-org/iptv/refs/heads/master/streams/al.m3u',
        );

        expect(result.type, PlaylistType.channelList);
        expect(result.channels.length, 4);

        final ch1 = result.channels[0];
        expect(ch1.title, 'AlbKanale Music TV (720p) [Not 24/7]');
        expect(ch1.tvgId, 'AlbKanaleMusicTV.al');
        expect(ch1.tvgLogo, 'https://i.imgur.com/GzB2Pq8.png');
        expect(ch1.groupTitle, 'Music');
        expect(ch1.url, 'https://albportal.net/albkanalemusic.m3u8');

        final ch3 = result.channels[2];
        expect(ch3.title, 'CNA (1080p)');
        expect(ch3.tvgId, 'CNA.al');
        expect(ch3.groupTitle, 'News');
        expect(ch3.url, 'https://live1.mediadesk.al/cnatvlive.m3u8');
      },
    );

    test('IPTV playlist deduplicates channels with identical stream URLs', () {
      final duplicateContent = '''#EXTM3U
#EXTINF:-1 tvg-id="CNA.al" group-title="News",CNA (1080p)
https://live1.mediadesk.al/cnatvlive.m3u8
#EXTINF:-1 tvg-id="CNA.al" group-title="News",CNA Duplicate
https://live1.mediadesk.al/cnatvlive.m3u8
#EXTINF:-1 tvg-id="AlpoTV.al" group-title="General",Alpo TV
https://stream.alpotv.com/alpotv/live/playlist.m3u8
''';

      final result = PlaylistParser.parseString(
        duplicateContent,
        'http://example.com/playlist.m3u',
      );

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 2);
      expect(result.channels[0].title, 'CNA (1080p)');
      expect(result.channels[1].title, 'Alpo TV');
    });

    test(
      'HLS master playlist with EXT-X-STREAM-INF is detected as hlsManifest',
      () {
        final hlsMaster = '''#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720
chunklist_720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2560000,RESOLUTION=1920x1080
chunklist_1080p.m3u8
''';

        final result = PlaylistParser.parseString(
          hlsMaster,
          'https://example.com/live/master.m3u8',
        );

        expect(result.type, PlaylistType.hlsManifest);
        expect(result.channels.isEmpty, isTrue);
      },
    );

    test(
      'HLS media segment playlist with EXT-X-TARGETDURATION is detected as hlsManifest',
      () {
        final hlsMedia = '''#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:42
#EXTINF:10.0,
segment42.ts
#EXTINF:10.0,
segment43.ts
''';

        final result = PlaylistParser.parseString(
          hlsMedia,
          'https://example.com/live/media.m3u8',
        );

        expect(result.type, PlaylistType.hlsManifest);
        expect(result.channels.isEmpty, isTrue);
      },
    );

    test('Regular M3U media playlist parses correctly', () {
      final regularM3u = '''#EXTM3U
#EXTINF:185,Artist One - Song One
http://example.com/track1.mp3
#EXTINF:210,Artist Two - Song Two
http://example.com/track2.mp3
''';

      final result = PlaylistParser.parseString(
        regularM3u,
        'http://example.com/music.m3u',
      );

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 2);
      expect(result.channels[0].title, 'Artist One - Song One');
      expect(result.channels[0].url, 'http://example.com/track1.mp3');
      expect(result.channels[1].title, 'Artist Two - Song Two');
    });

    test(
      'Handles single-quotes, unquoted attributes, and commas in channel title',
      () {
        final complexM3u = '''#EXTM3U
#EXTINF:-1 tvg-id='Custom.ID' group-title="News, Current Affairs" tvg-logo=https://example.com/logo.png,Channel One, Breaking News & More
http://example.com/ch1.m3u8
''';

        final result = PlaylistParser.parseString(
          complexM3u,
          'http://example.com/playlist.m3u',
        );

        expect(result.type, PlaylistType.channelList);
        expect(result.channels.length, 1);
        final ch = result.channels.first;
        expect(ch.tvgId, 'Custom.ID');
        expect(ch.groupTitle, 'News, Current Affairs');
        expect(ch.tvgLogo, 'https://example.com/logo.png');
        expect(ch.title, 'Channel One, Breaking News & More');
        expect(ch.url, 'http://example.com/ch1.m3u8');
      },
    );

    test('Strips UTF-8 BOM and handles CRLF line endings cleanly', () {
      final bomM3u =
          '\uFEFF#EXTM3U\r\n#EXTINF:-1 tvg-id="Test",Clean Channel\r\nhttp://example.com/stream.m3u8\r\n';

      final result = PlaylistParser.parseString(
        bomM3u,
        'http://example.com/playlist.m3u',
      );

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 1);
      expect(result.channels.first.title, 'Clean Channel');
      expect(result.channels.first.tvgId, 'Test');
    });

    test('Attaches EXTVLCOPT headers to channel item httpHeaders', () {
      final vlcOptM3u = '''#EXTM3U
#EXTINF:-1 tvg-id="Protected",Protected Stream
#EXTVLCOPT:http-user-agent=CustomPlayer/2.0
#EXTVLCOPT:http-referrer=https://allowed-origin.com
http://example.com/stream.m3u8
''';

      final result = PlaylistParser.parseString(
        vlcOptM3u,
        'http://example.com/playlist.m3u',
      );

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 1);
      final ch = result.channels.first;
      expect(ch.url, 'http://example.com/stream.m3u8');
      expect(ch.httpHeaders?['User-Agent'], 'CustomPlayer/2.0');
      expect(ch.httpHeaders?['Referer'], 'https://allowed-origin.com');
    });

    test('Resolves relative channel URLs against parent playlist URL', () {
      final relativeM3u = '''#EXTM3U
#EXTINF:-1,Channel 1
streams/live1.m3u8
#EXTINF:-1,Channel 2
../other/live2.m3u8
''';

      final result = PlaylistParser.parseString(
        relativeM3u,
        'http://example.com/iptv/lists/channels.m3u',
      );

      expect(result.type, PlaylistType.channelList);
      expect(result.channels.length, 2);
      expect(
        result.channels[0].url,
        'http://example.com/iptv/lists/streams/live1.m3u8',
      );
      expect(
        result.channels[1].url,
        'http://example.com/iptv/other/live2.m3u8',
      );
    });
  });
}
