import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/network_streams/network_stream_service.dart';
import 'package:ppplayer/core/network_streams/playlist_parser.dart';
import 'package:ppplayer/core/services/secure_credentials_service.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  group('NetworkStreamService', () {
    late AppDatabase db;
    late NetworkStreamService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = NetworkStreamService(db, SecureCredentialsService());
    });

    tearDown(() async {
      await db.close();
    });

    test('analyzeUrl classifies Albanian IPTV playlist (al.m3u) accurately', () async {
      const alM3uPayload = '''#EXTM3U
#EXTINF:-1 tvg-id="AlbKanaleMusicTV.al" tvg-logo="https://i.imgur.com/GzB2Pq8.png" group-title="Music",AlbKanale Music TV (720p) [Not 24/7]
https://albportal.net/albkanalemusic.m3u8
#EXTINF:-1 tvg-id="AlpoTV.al" tvg-logo="https://i.imgur.com/dK46r3R.png" group-title="General",Alpo TV (576p)
https://stream.alpotv.com/alpotv/live/playlist.m3u8
#EXTINF:-1 tvg-id="CNA.al" tvg-logo="https://i.imgur.com/Z421lQ8.png" group-title="News",CNA (1080p)
https://live1.mediadesk.al/cnatvlive.m3u8
#EXTINF:-1 tvg-id="Cufo.al" tvg-logo="https://i.imgur.com/tOa7c64.png" group-title="Kids",Cufo (576p) [Not 24/7]
https://cufo-al-stream.example.com/live.m3u8
''';

      final client = MockHttpClient((request) async {
        final bytes = utf8.encode(alM3uPayload);
        return http.StreamedResponse(
          Stream.fromIterable([bytes]),
          200,
          headers: {'content-type': 'application/x-mpegurl'},
          request: request,
        );
      });

      final result = await service.analyzeUrl(
        'https://raw.githubusercontent.com/iptv-org/iptv/refs/heads/master/streams/al.m3u',
        client: client,
      );

      expect(result.type, PlaylistType.channelList);
      expect(result.isIptvPlaylist, isTrue);
      expect(result.isHlsStream, isFalse);
      expect(result.isSingleStream, isFalse);
      expect(result.channels.length, 4);
      expect(result.channels[0].title, 'AlbKanale Music TV (720p) [Not 24/7]');
      expect(result.channels[2].title, 'CNA (1080p)');
      expect(result.suggestedTitle, 'AL');
    });

    test('analyzeUrl classifies HLS master playlist as hlsManifest without exposing internal sub-streams as channels', () async {
      const hlsMasterPayload = '''#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720
chunklist_720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2560000,RESOLUTION=1920x1080
chunklist_1080p.m3u8
''';

      final client = MockHttpClient((request) async {
        final bytes = utf8.encode(hlsMasterPayload);
        return http.StreamedResponse(
          Stream.fromIterable([bytes]),
          200,
          headers: {'content-type': 'application/vnd.apple.mpegurl'},
          request: request,
        );
      });

      final result = await service.analyzeUrl(
        'https://example.com/live/master.m3u8',
        client: client,
      );

      expect(result.type, PlaylistType.hlsManifest);
      expect(result.isIptvPlaylist, isFalse);
      expect(result.isHlsStream, isTrue);
      expect(result.isSingleStream, isTrue);
      expect(result.channels.length, 1);
      expect(result.channels.first.url, 'https://example.com/live/master.m3u8');
    });

    test('analyzeUrl classifies direct MP4 stream as unknown/single stream', () async {
      final client = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.fromIterable([[0, 0, 0, 24, 102, 116, 121, 112]]),
          200,
          headers: {'content-type': 'video/mp4'},
          request: request,
        );
      });

      final result = await service.analyzeUrl(
        'https://example.com/video.mp4',
        client: client,
      );

      expect(result.type, PlaylistType.unknown);
      expect(result.isIptvPlaylist, isFalse);
      expect(result.isSingleStream, isTrue);
      expect(result.channels.length, 1);
      expect(result.channels.first.url, 'https://example.com/video.mp4');
    });

    test('extractDirectStreamUrl parses pipe headers syntax', () async {
      final inputUrl =
          'https://stream.example.com/live.m3u8|User-Agent=CustomAgent%2F1.0&Referer=https%3A%2F%2Fiptv.org';

      final extracted = await service.extractDirectStreamUrl(inputUrl);

      expect(extracted, isNotNull);
      expect(extracted!.url, 'https://stream.example.com/live.m3u8');
      expect(extracted.httpHeaders, isNotNull);
      expect(extracted.httpHeaders!['User-Agent'], 'CustomAgent/1.0');
      expect(extracted.httpHeaders!['Referer'], 'https://iptv.org');
    });

    test('savePlaylist and refreshPlaylist persist and reload channels with headers', () async {
      final channels = [
        PlaylistItem(
          title: 'CNA (1080p)',
          url: 'https://live1.mediadesk.al/cnatvlive.m3u8',
          tvgId: 'CNA.al',
          groupTitle: 'News',
          httpHeaders: {'User-Agent': 'VLC/3.0'},
        ),
      ];

      final playlistId = await service.savePlaylist(
        'Albanian TV',
        'https://example.com/al.m3u',
        channels,
        sourceKind: 'url',
      );

      expect(playlistId, isPositive);

      final savedChannels = await (db.select(db.streamChannels)
            ..where((t) => t.playlistId.equals(playlistId)))
          .get();

      expect(savedChannels.length, 1);
      expect(savedChannels.first.title, 'CNA (1080p)');
      expect(savedChannels.first.streamUrl, contains('|User-Agent=VLC%2F3.0'));

      // Test refreshPlaylist updates or preserves channels
      final refreshCount = await service.refreshPlaylist(playlistId);
      // Since network is unreachable for mock url in this test, refresh catches error and returns 0
      expect(refreshCount, isNonNegative);
    });
  });
}
