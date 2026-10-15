import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../db/app_database.dart';
import 'playlist_parser.dart';
import '../services/secure_credentials_service.dart';
import 'video_metadata.dart';

import 'package:http/http.dart' as http;

class ExtractedStream {
  final String url;
  final Map<String, String>? httpHeaders;
  const ExtractedStream({required this.url, this.httpHeaders});
}

class YoutubeApiKeyMissingException implements Exception {
  final String message;
  YoutubeApiKeyMissingException([this.message = 'YouTube API Key is missing']);
  @override
  String toString() => message;
}

final networkStreamServiceProvider = Provider<NetworkStreamService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final secureCredentialsService = ref.watch(secureCredentialsProvider);
  return NetworkStreamService(db, secureCredentialsService);
});

class StreamAnalysisResult {
  final PlaylistType type;
  final List<PlaylistItem> channels;
  final String normalizedUrl;
  final String? suggestedTitle;

  const StreamAnalysisResult({
    required this.type,
    required this.channels,
    required this.normalizedUrl,
    this.suggestedTitle,
  });

  bool get isIptvPlaylist =>
      type == PlaylistType.channelList && channels.isNotEmpty;
  bool get isHlsStream => type == PlaylistType.hlsManifest;
  bool get isSingleStream =>
      type == PlaylistType.hlsManifest ||
      type == PlaylistType.unknown ||
      (type == PlaylistType.channelList && channels.length <= 1);
}

class NetworkStreamService {
  final AppDatabase _db;
  final SecureCredentialsService _secureCredentialsService;

  NetworkStreamService(this._db, this._secureCredentialsService);

  /// Analyzes a network URL to determine if it's an IPTV playlist,
  /// HLS manifest, or single media stream.
  Future<StreamAnalysisResult> analyzeUrl(
    String url, {
    http.Client? client,
  }) async {
    final normalizedUrl = PlaylistParser.normalizeUrl(url);

    // Check if it's a YouTube playlist URL
    final uri = Uri.tryParse(normalizedUrl);
    if (uri != null &&
        (uri.host == 'youtube.com' ||
            uri.host == 'www.youtube.com' ||
            uri.host == 'm.youtube.com' ||
            uri.host == 'music.youtube.com' ||
            uri.host == 'youtu.be')) {
      if (uri.queryParameters.containsKey('list')) {
        final playlistId = uri.queryParameters['list']!;
        final channels = await _fetchYoutubePlaylist(
          playlistId,
          client: client,
        );
        return StreamAnalysisResult(
          type: PlaylistType.channelList,
          channels: channels,
          normalizedUrl: normalizedUrl,
          suggestedTitle: 'YouTube Playlist',
        );
      }
    }

    try {
      final result = await PlaylistParser.fetchAndParse(
        normalizedUrl,
        client: client,
      );

      String? suggestedTitle = result.playlistTitle;
      if (suggestedTitle == null || suggestedTitle.isEmpty) {
        if (uri != null && uri.pathSegments.isNotEmpty) {
          final lastSeg = uri.pathSegments.last;
          final cleanSeg = lastSeg.replaceAll(
            RegExp(r'\.(m3u8?|pls|xspf|asx)$', caseSensitive: false),
            '',
          );
          if (cleanSeg.isNotEmpty &&
              cleanSeg != 'index' &&
              cleanSeg != 'playlist') {
            suggestedTitle = cleanSeg.toUpperCase();
          }
        }
      }

      switch (result.type) {
        case PlaylistType.channelList:
          return StreamAnalysisResult(
            type: PlaylistType.channelList,
            channels: result.channels,
            normalizedUrl: normalizedUrl,
            suggestedTitle: suggestedTitle,
          );
        case PlaylistType.hlsManifest:
          return StreamAnalysisResult(
            type: PlaylistType.hlsManifest,
            channels: [
              PlaylistItem(
                title: suggestedTitle ?? 'Live Stream',
                url: normalizedUrl,
              ),
            ],
            normalizedUrl: normalizedUrl,
            suggestedTitle: suggestedTitle,
          );
        case PlaylistType.unknown:
          return StreamAnalysisResult(
            type: PlaylistType.unknown,
            channels: [
              PlaylistItem(
                title: suggestedTitle ?? 'Stream 1',
                url: normalizedUrl,
              ),
            ],
            normalizedUrl: normalizedUrl,
            suggestedTitle: suggestedTitle,
          );
      }
    } catch (e) {
      return StreamAnalysisResult(
        type: PlaylistType.unknown,
        channels: [PlaylistItem(title: 'Stream 1', url: normalizedUrl)],
        normalizedUrl: normalizedUrl,
      );
    }
  }

  /// Analyzes a URL to see if it's a playlist or a direct stream.
  /// If it's a playlist, parses it and returns the list of channels.
  /// If it's a direct stream or HLS manifest, returns a single channel item representing the stream itself.
  Future<List<PlaylistItem>> analyzeAndParseUrl(
    String url, {
    http.Client? client,
  }) async {
    final result = await analyzeUrl(url, client: client);
    return result.channels;
  }

  Future<List<PlaylistItem>> _fetchYoutubePlaylist(
    String playlistId, {
    http.Client? client,
  }) async {
    final apiKey = await _secureCredentialsService.readYoutubeApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw YoutubeApiKeyMissingException(
        'A custom YouTube API Key is required to import playlists. Please add it in Settings.',
      );
    }

    final localClient = client ?? http.Client();
    try {
      final List<PlaylistItem> channels = [];
      String? pageToken;

      do {
        final uri =
            Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
              'part': 'snippet',
              'playlistId': playlistId,
              'maxResults': '50',
              if (pageToken != null) 'pageToken': pageToken,
              'key': apiKey,
            });

        final response = await localClient.get(uri);

        if (response.statusCode == 403) {
          throw Exception('YouTube API Quota exceeded or invalid API Key.');
        } else if (response.statusCode == 404) {
          throw Exception('YouTube Playlist not found. It might be private.');
        } else if (response.statusCode != 200) {
          throw Exception('YouTube API error: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final snippet = item['snippet'];
          if (snippet == null) continue;

          final title = snippet['title'] as String?;
          // Skip deleted or private videos (title is usually "Private video" or "Deleted video")
          if (title == null ||
              title == 'Private video' ||
              title == 'Deleted video')
            continue;

          final resourceId = snippet['resourceId'];
          if (resourceId == null || resourceId['kind'] != 'youtube#video')
            continue;

          final videoId = resourceId['videoId'] as String?;
          if (videoId == null) continue;

          final thumbnails = snippet['thumbnails'];
          String? logoUrl;
          if (thumbnails != null) {
            logoUrl =
                thumbnails['maxres']?['url'] ??
                thumbnails['high']?['url'] ??
                thumbnails['medium']?['url'] ??
                thumbnails['default']?['url'];
          }

          channels.add(
            PlaylistItem(
              title: title,
              url: 'https://youtube.com/watch?v=$videoId',
              tvgLogo: logoUrl,
              groupTitle: snippet['channelTitle'] as String?,
            ),
          );
        }

        pageToken = data['nextPageToken'] as String?;
      } while (pageToken != null);

      if (channels.isEmpty) {
        throw Exception('No accessible videos found in this YouTube playlist.');
      }

      return channels;
    } finally {
      if (client == null) {
        localClient.close();
      }
    }
  }

  Future<ExtractedStream?> extractDirectStreamUrl(String videoUrl) async {
    // If user pasted an <iframe> embed, extract the src URL
    final trimmedInput = videoUrl.trim();
    if (trimmedInput.toLowerCase().startsWith('<iframe')) {
      final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(trimmedInput);
      if (srcMatch != null) videoUrl = srcMatch.group(1)!;
    }

    // Check for pipe syntax: url|User-Agent=...&Referer=...
    if (videoUrl.contains('|')) {
      final pipeIdx = videoUrl.indexOf('|');
      final actualUrl = videoUrl.substring(0, pipeIdx).trim();
      final headerStr = videoUrl.substring(pipeIdx + 1).trim();
      final headers = <String, String>{};
      for (final pair in headerStr.split('&')) {
        final eq = pair.indexOf('=');
        if (eq != -1) {
          final k = pair.substring(0, eq).trim();
          final v = Uri.decodeComponent(pair.substring(eq + 1).trim());
          if (k.isNotEmpty && v.isNotEmpty) {
            headers[k] = v;
          }
        }
      }
      return ExtractedStream(
        url: actualUrl,
        httpHeaders: headers.isNotEmpty ? headers : null,
      );
    }

    try {
      if (videoUrl.contains('dai.ly') || videoUrl.contains('dailymotion.com')) {
        final uri = Uri.parse(videoUrl);
        String? videoId;
        if (uri.host == 'dai.ly') {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        } else {
          final segments = uri.pathSegments;
          if (segments.contains('video')) {
            videoId = segments[segments.indexOf('video') + 1];
          } else if (uri.queryParameters.containsKey('video')) {
            videoId = uri.queryParameters['video'];
          }
        }
        if (videoId != null) {
          final response = await http.get(
            Uri.parse(
              'https://www.dailymotion.com/player/metadata/video/$videoId',
            ),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final qualities = data['qualities'] as Map<String, dynamic>?;
            if (qualities != null && qualities.containsKey('auto')) {
              final autoList = qualities['auto'] as List<dynamic>;
              if (autoList.isNotEmpty) {
                String masterUrl = autoList[0]['url'] as String;
                if (masterUrl.startsWith('//')) {
                  masterUrl = 'https:$masterUrl';
                }
                final cookies = response.headers['set-cookie'];
                final headers = <String, String>{};
                if (cookies != null) {
                  headers['Cookie'] = cookies
                      .split(',')
                      .map((c) => c.split(';')[0])
                      .join('; ');
                }
                headers['Referer'] = 'https://www.dailymotion.com/';

                return ExtractedStream(url: masterUrl, httpHeaders: headers);
              }
            }
          }
        }
      } else if (videoUrl.contains('vimeo.com')) {
        final uri = Uri.parse(videoUrl);
        // Find numeric video ID from path segments
        String? videoId;
        String? hashToken;
        for (int i = 0; i < uri.pathSegments.length; i++) {
          final seg = uri.pathSegments[i];
          if (RegExp(r'^\d+$').hasMatch(seg)) {
            videoId = seg;
            // Next segment might be a hash/privacy token
            if (i + 1 < uri.pathSegments.length) {
              final next = uri.pathSegments[i + 1];
              if (RegExp(r'^[a-f0-9]+$').hasMatch(next)) {
                hashToken = next;
              }
            }
            break;
          }
        }
        // Also check the query param 'h' for hash
        hashToken ??= uri.queryParameters['h'];

        if (videoId != null) {
          // Build player URL - use the embed player page which exposes window.playerConfig
          String playerUrl;
          if (uri.host == 'player.vimeo.com') {
            // Already a player URL, use as-is but strip extraneous params
            playerUrl =
                'https://player.vimeo.com/video/$videoId${hashToken != null ? '?h=$hashToken' : ''}';
          } else {
            playerUrl =
                'https://player.vimeo.com/video/$videoId${hashToken != null ? '?h=$hashToken' : ''}';
          }

          final response = await http.get(Uri.parse(playerUrl));
          if (response.statusCode == 200) {
            final body = response.body;
            // Parse window.playerConfig from the embed HTML
            const startStr = 'window.playerConfig = ';
            final startIndex = body.indexOf(startStr);
            if (startIndex != -1) {
              final jsonStart = startIndex + startStr.length;
              final endIndex = body.indexOf('</script>', jsonStart);
              if (endIndex != -1) {
                String jsonStr = body.substring(jsonStart, endIndex).trim();
                if (jsonStr.endsWith(';'))
                  jsonStr = jsonStr.substring(0, jsonStr.length - 1);
                try {
                  final data = json.decode(jsonStr);
                  final vimeoHeaders = {'Referer': 'https://vimeo.com/'};

                  // Prefer progressive (MP4) for direct compatibility
                  final mp4s =
                      data['request']?['files']?['progressive']
                          as List<dynamic>?;
                  if (mp4s != null && mp4s.isNotEmpty) {
                    final url = mp4s[0]['url'] as String?;
                    return url != null
                        ? ExtractedStream(url: url, httpHeaders: vimeoHeaders)
                        : null;
                  }
                  // Fall back to HLS
                  final hls = data['request']?['files']?['hls']?['cdns'];
                  if (hls is Map && hls.isNotEmpty) {
                    // Prefer the avc_url (H.264) over url which may be HEVC/AV1
                    final firstCdn = hls.values.first;
                    final avcUrl = firstCdn['avc_url'] as String?;
                    final url = avcUrl ?? firstCdn['url'] as String?;
                    if (url != null && url.contains('/drm/')) {
                      throw Exception(
                        'This video is DRM-protected and cannot be played directly.',
                      );
                    }
                    return url != null
                        ? ExtractedStream(url: url, httpHeaders: vimeoHeaders)
                        : null;
                  }
                } catch (e) {
                  if (e.toString().contains('DRM-protected')) rethrow;
                }
              }
            }
          } else if (response.statusCode == 403) {
            throw Exception(
              'This video has privacy restrictions and cannot be played outside of Vimeo.',
            );
          }
        }
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }

  Future<VideoMetadata> fetchVideoMetadata(
    String url, {
    http.Client? client,
  }) async {
    // Extract src from <iframe> embed code if user pasted one
    final trimmed = url.trim();
    if (trimmed.toLowerCase().startsWith('<iframe')) {
      final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(trimmed);
      if (srcMatch != null) url = srcMatch.group(1)!;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null)
      return const VideoMetadata(title: '', platform: VideoPlatform.custom);

    VideoPlatform platform = VideoPlatform.custom;
    final host = uri.host.toLowerCase();

    if (host.contains('youtube.com') || host == 'youtu.be') {
      platform = VideoPlatform.youtube;
    } else if (host.contains('vimeo.com')) {
      platform = VideoPlatform.vimeo;
    } else if (host.contains('dailymotion.com') || host == 'dai.ly') {
      platform = VideoPlatform.dailymotion;
    } else {
      return VideoMetadata(
        title: uri.pathSegments.lastOrNull ?? 'Unknown Stream',
        platform: platform,
      );
    }

    final localClient = client ?? http.Client();
    try {
      if (platform == VideoPlatform.youtube) {
        final oembedUrl = Uri.parse(
          'https://www.youtube.com/oembed?url=$url&format=json',
        );
        final res = await localClient.get(oembedUrl);
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          return VideoMetadata(
            title: data['title'] ?? 'YouTube Video',
            thumbnailUrl: data['thumbnail_url'],
            platform: platform,
          );
        }
      } else if (platform == VideoPlatform.vimeo) {
        final oembedUrl = Uri.parse(
          'https://vimeo.com/api/oembed.json?url=$url',
        );
        final res = await localClient.get(oembedUrl);
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          return VideoMetadata(
            title: data['title'] ?? 'Vimeo Video',
            thumbnailUrl: data['thumbnail_url'],
            platform: platform,
          );
        }
      } else if (platform == VideoPlatform.dailymotion) {
        final oembedUrl = Uri.parse(
          'https://www.dailymotion.com/services/oembed?url=$url&format=json',
        );
        final res = await localClient.get(
          oembedUrl,
          headers: {'User-Agent': 'Mozilla/5.0'},
        );
        if (res.statusCode == 200) {
          try {
            final data = json.decode(res.body);
            return VideoMetadata(
              title: data['title'] ?? 'Dailymotion Video',
              thumbnailUrl: data['thumbnail_url'],
              platform: platform,
            );
          } catch (_) {
            // JSON parsing failed, likely returned an error string instead of JSON
          }
        }
      }
    } catch (_) {
      // Ignore errors and fallback
    } finally {
      if (client == null) {
        localClient.close();
      }
    }

    return VideoMetadata(
      title: '${platform.displayName} Video',
      platform: platform,
    );
  }

  /// Saves a parsed playlist into the database, clearing old channels for the same playlist.
  Future<int> savePlaylist(
    String title,
    String sourceUrl,
    List<PlaylistItem> channels, {
    String? imageUrl,
    String? sourceKind,
  }) async {
    return await _db.transaction(() async {
      // Check if playlist already exists by URI
      final existingPlaylists = await (_db.select(
        _db.streamPlaylists,
      )..where((t) => t.sourceUri.equals(sourceUrl))).get();

      int playlistId;
      if (existingPlaylists.isNotEmpty) {
        playlistId = existingPlaylists.first.id;

        // Update playlist metadata
        await (_db.update(
          _db.streamPlaylists,
        )..where((t) => t.id.equals(playlistId))).write(
          StreamPlaylistsCompanion(
            lastRefreshed: drift.Value(DateTime.now()),
            imageUrl: drift.Value(imageUrl),
            sourceKind: drift.Value(sourceKind ?? 'url'),
          ),
        );
      } else {
        playlistId = await _db
            .into(_db.streamPlaylists)
            .insert(
              StreamPlaylistsCompanion.insert(
                title: title,
                sourceKind: sourceKind ?? 'url',
                sourceUri: sourceUrl,
                imageUrl: drift.Value(imageUrl),
                lastRefreshed: drift.Value(DateTime.now()),
              ),
            );
      }

      // Fetch existing channels to preserve IDs
      final existingChannels = await (_db.select(
        _db.streamChannels,
      )..where((t) => t.playlistId.equals(playlistId))).get();

      final existingByUrl = {for (var c in existingChannels) c.streamUrl: c};
      final urlsToKeep = <String>{};

      var index = 0;
      final inserts = <StreamChannelsCompanion>[];

      for (final c in channels) {
        final streamUrl =
            (c.httpHeaders != null &&
                c.httpHeaders!.isNotEmpty &&
                !c.url.contains('|'))
            ? '${c.url}|${c.httpHeaders!.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
            : c.url;
        urlsToKeep.add(streamUrl);
        final existing = existingByUrl[streamUrl] ?? existingByUrl[c.url];

        if (existing != null) {
          // Update existing channel
          await (_db.update(
            _db.streamChannels,
          )..where((t) => t.id.equals(existing.id))).write(
            StreamChannelsCompanion(
              title: drift.Value(c.title),
              streamUrl: drift.Value(streamUrl),
              tvgId: drift.Value(c.tvgId),
              logo: drift.Value(c.tvgLogo),
              groupTitle: drift.Value(c.groupTitle),
              position: drift.Value(index),
            ),
          );
        } else {
          // Insert new channel
          inserts.add(
            StreamChannelsCompanion.insert(
              playlistId: playlistId,
              title: c.title,
              streamUrl: streamUrl,
              tvgId: drift.Value(c.tvgId),
              logo: drift.Value(c.tvgLogo),
              groupTitle: drift.Value(c.groupTitle),
              position: index,
            ),
          );
        }
        index++;
      }

      // Delete removed channels
      for (final old in existingChannels) {
        if (!urlsToKeep.contains(old.streamUrl)) {
          await (_db.delete(
            _db.streamChannels,
          )..where((t) => t.id.equals(old.id))).go();
        }
      }

      if (inserts.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.streamChannels, inserts);
        });
      }

      return playlistId;
    });
  }

  Stream<List<StreamPlaylist>> watchPlaylists() {
    return _db.select(_db.streamPlaylists).watch();
  }

  Stream<List<StreamChannel>> watchChannelsForPlaylist(int playlistId) {
    return (_db.select(
      _db.streamChannels,
    )..where((t) => t.playlistId.equals(playlistId))).watch();
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.streamChannels,
      )..where((t) => t.playlistId.equals(playlistId))).go();
      await (_db.delete(
        _db.streamPlaylists,
      )..where((t) => t.id.equals(playlistId))).go();
    });
  }

  Stream<StreamPlaylist> watchPlaylist(int playlistId) {
    return (_db.select(
      _db.streamPlaylists,
    )..where((t) => t.id.equals(playlistId))).watchSingle();
  }

  Future<void> updatePlaylist(int playlistId, String newTitle) async {
    await (_db.update(_db.streamPlaylists)
          ..where((t) => t.id.equals(playlistId)))
        .write(StreamPlaylistsCompanion(title: drift.Value(newTitle)));
  }

  Future<void> updateChannel(
    int channelId,
    String newTitle,
    String newUrl,
  ) async {
    await (_db.update(
      _db.streamChannels,
    )..where((t) => t.id.equals(channelId))).write(
      StreamChannelsCompanion(
        title: drift.Value(newTitle),
        streamUrl: drift.Value(newUrl),
      ),
    );
  }

  Future<void> deleteChannel(int channelId) async {
    await (_db.delete(
      _db.streamChannels,
    )..where((t) => t.id.equals(channelId))).go();
  }

  /// Refreshes an existing playlist from its remote source URL.
  Future<int> refreshPlaylist(int playlistId, {http.Client? client}) async {
    final playlist = await (_db.select(
      _db.streamPlaylists,
    )..where((t) => t.id.equals(playlistId))).getSingleOrNull();
    if (playlist == null) return 0;

    final analysis = await analyzeUrl(playlist.sourceUri, client: client);
    if (analysis.channels.isEmpty) return 0;

    await savePlaylist(
      playlist.title,
      playlist.sourceUri,
      analysis.channels,
      imageUrl: playlist.imageUrl,
      sourceKind: playlist.sourceKind,
    );

    return analysis.channels.length;
  }
}
