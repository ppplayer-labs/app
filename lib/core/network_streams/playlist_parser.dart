import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class PlaylistItem {
  final String title;
  final String url;
  final String? tvgId;
  final String? tvgLogo;
  final String? groupTitle;
  final Map<String, String>? httpHeaders;

  PlaylistItem({
    required this.title,
    required this.url,
    this.tvgId,
    this.tvgLogo,
    this.groupTitle,
    this.httpHeaders,
  });
}

enum PlaylistType { channelList, hlsManifest, unknown }

class PlaylistParseResult {
  final PlaylistType type;
  final List<PlaylistItem> channels;
  final String? playlistTitle;

  PlaylistParseResult({
    required this.type,
    this.channels = const [],
    this.playlistTitle,
  });
}

class PlaylistParser {
  /// Normalizes GitHub preview links to raw links.
  static String normalizeUrl(String url) {
    if (url.startsWith('https://github.com/') && url.contains('/blob/')) {
      return url
          .replaceFirst(
            'https://github.com/',
            'https://raw.githubusercontent.com/',
          )
          .replaceFirst('/blob/', '/');
    }
    return url;
  }

  /// Parses content directly from a string based on its inferred format.
  static PlaylistParseResult parseString(String content, String url) {
    var cleanContent = content.startsWith('\uFEFF')
        ? content.substring(1)
        : content;
    cleanContent = cleanContent.trimLeft();

    if (cleanContent.startsWith('#EXTM3U') ||
        cleanContent.startsWith('#EXTINF') ||
        cleanContent.contains('#EXTINF:')) {
      return _parseM3u(cleanContent, url);
    } else if (cleanContent.toLowerCase().startsWith('[playlist]')) {
      return _parsePls(cleanContent, url);
    } else if (cleanContent.startsWith('<')) {
      // Could be XSPF or ASX
      try {
        final document = XmlDocument.parse(cleanContent);
        final root = document.rootElement;

        if (root.name.local.toLowerCase() == 'playlist' &&
            root.name.namespaceUri?.contains('xspf') == true) {
          return _parseXspf(document, url);
        } else if (root.name.local.toLowerCase() == 'asx') {
          return _parseAsx(document, url);
        }
      } catch (e) {
        // XML parsing failed
      }
    }

    // Default: could not parse
    return PlaylistParseResult(type: PlaylistType.unknown);
  }

  static int _findFirstUnquotedComma(String line) {
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      } else if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (char == ',' && !inDoubleQuote && !inSingleQuote) {
        return i;
      }
    }
    return -1;
  }

  static String? _extractAttribute(String text, String attrName) {
    final pattern = RegExp(
      '''$attrName=(?:"([^"]*)"|'([^']*)'|([^\\s,]+))''',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      return match.group(1) ?? match.group(2) ?? match.group(3);
    }
    return null;
  }

  static PlaylistParseResult _parseM3u(String content, String baseUrl) {
    // Check for standard HLS Master and Media playlist tags
    final hasHlsTag =
        content.contains('#EXT-X-STREAM-INF') ||
        content.contains('#EXT-X-TARGETDURATION') ||
        content.contains('#EXT-X-MEDIA-SEQUENCE') ||
        content.contains('#EXT-X-ENDLIST') ||
        content.contains('#EXT-X-PLAYLIST-TYPE') ||
        content.contains('#EXT-X-MAP:') ||
        content.contains('#EXT-X-KEY:') ||
        content.contains('#EXT-X-MEDIA:') ||
        content.contains('#EXT-X-I-FRAME-STREAM-INF');

    if (hasHlsTag) {
      return PlaylistParseResult(type: PlaylistType.hlsManifest);
    }

    // Extract playlist-level title if defined
    String? playlistTitle;
    final playlistNameMatch = RegExp(
      r'#PLAYLIST:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(content);
    if (playlistNameMatch != null) {
      playlistTitle = playlistNameMatch.group(1)?.trim();
    } else {
      final extm3uNameMatch = RegExp(
        r'''#EXTM3U[^\n\r]*\bname=["']([^"']+)["']''',
        caseSensitive: false,
      ).firstMatch(content);
      if (extm3uNameMatch != null) {
        playlistTitle = extm3uNameMatch.group(1)?.trim();
      }
    }

    final channels = <PlaylistItem>[];
    final seenUrls = <String>{};
    final lines = content.split(RegExp(r'\r?\n'));

    String? currentTitle;
    String? currentTvgId;
    String? currentTvgLogo;
    String? currentGroupTitle;
    Map<String, String>? currentHeaders;

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final commaIndex = _findFirstUnquotedComma(line);
        if (commaIndex != -1 && commaIndex < line.length - 1) {
          currentTitle = line.substring(commaIndex + 1).trim();
        } else {
          currentTitle = '';
        }

        final tagMeta = commaIndex != -1 ? line.substring(0, commaIndex) : line;

        currentTvgId = _extractAttribute(tagMeta, 'tvg-id');
        final tvgName = _extractAttribute(tagMeta, 'tvg-name');
        if (currentTitle.isEmpty) {
          currentTitle = (tvgName != null && tvgName.isNotEmpty)
              ? tvgName
              : (currentTvgId != null && currentTvgId.isNotEmpty
                  ? currentTvgId
                  : 'Unknown Channel');
        }

        currentTvgLogo =
            _extractAttribute(tagMeta, 'tvg-logo') ??
            _extractAttribute(tagMeta, 'logo');
        currentGroupTitle = _extractAttribute(tagMeta, 'group-title');

        final inlineUa =
            _extractAttribute(tagMeta, 'http-user-agent') ??
            _extractAttribute(tagMeta, 'user-agent');
        final inlineRef =
            _extractAttribute(tagMeta, 'http-referrer') ??
            _extractAttribute(tagMeta, 'referrer');
        if (inlineUa != null || inlineRef != null) {
          currentHeaders ??= {};
          if (inlineUa != null) currentHeaders['User-Agent'] = inlineUa;
          if (inlineRef != null) currentHeaders['Referer'] = inlineRef;
        }
      } else if (line.startsWith('#EXTGRP:')) {
        if (currentGroupTitle == null || currentGroupTitle.isEmpty) {
          currentGroupTitle = line.substring(8).trim();
        }
      } else if (line.startsWith('#EXTVLCOPT:')) {
        final opt = line.substring(11).trim();
        final eq = opt.indexOf('=');
        if (eq != -1) {
          final key = opt.substring(0, eq).trim().toLowerCase();
          final val = opt.substring(eq + 1).trim();
          currentHeaders ??= {};
          if (key == 'http-user-agent' || key == 'user-agent') {
            currentHeaders['User-Agent'] = val;
          } else if (key == 'http-referrer' || key == 'referrer') {
            currentHeaders['Referer'] = val;
          } else if (key == 'http-origin' || key == 'origin') {
            currentHeaders['Origin'] = val;
          }
        }
      } else if (line.startsWith('#KODIPROP:')) {
        final prop = line.substring(10).trim();
        if (prop.toLowerCase().startsWith(
          'inputstream.adaptive.manifest_headers=',
        )) {
          final headersVal = prop.substring(38).trim();
          for (final pair in headersVal.split('&')) {
            final eq = pair.indexOf('=');
            if (eq != -1) {
              final k = pair.substring(0, eq).trim();
              final v = pair.substring(eq + 1).trim();
              currentHeaders ??= {};
              currentHeaders[k] = v;
            }
          }
        }
      } else if (!line.startsWith('#')) {
        var streamUrl = line;
        if ((streamUrl.startsWith('"') && streamUrl.endsWith('"')) ||
            (streamUrl.startsWith("'") && streamUrl.endsWith("'"))) {
          streamUrl = streamUrl.substring(1, streamUrl.length - 1).trim();
        }

        // Parse pipe syntax: url|Header=Val&...
        if (streamUrl.contains('|')) {
          final pipeIdx = streamUrl.indexOf('|');
          final rawUrl = streamUrl.substring(0, pipeIdx).trim();
          final pipeParams = streamUrl.substring(pipeIdx + 1).trim();
          for (final pair in pipeParams.split('&')) {
            final eq = pair.indexOf('=');
            if (eq != -1) {
              final k = pair.substring(0, eq).trim();
              final v = Uri.decodeComponent(pair.substring(eq + 1).trim());
              currentHeaders ??= {};
              currentHeaders[k] = v;
            }
          }
          streamUrl = rawUrl;
        }

        final resolvedUrl = _resolveUrl(normalizeUrl(streamUrl), baseUrl);

        if (!seenUrls.contains(resolvedUrl)) {
          seenUrls.add(resolvedUrl);
          channels.add(
            PlaylistItem(
              title: currentTitle ?? 'Stream ${channels.length + 1}',
              url: resolvedUrl,
              tvgId: currentTvgId,
              tvgLogo: currentTvgLogo,
              groupTitle: currentGroupTitle,
              httpHeaders:
                  currentHeaders != null ? Map.from(currentHeaders) : null,
            ),
          );
        }

        currentTitle = null;
        currentTvgId = null;
        currentTvgLogo = null;
        currentGroupTitle = null;
        currentHeaders = null;
      }
    }

    if (channels.isEmpty) {
      return PlaylistParseResult(type: PlaylistType.unknown);
    }

    return PlaylistParseResult(
      type: PlaylistType.channelList,
      channels: channels,
      playlistTitle: playlistTitle,
    );
  }

  static PlaylistParseResult _parsePls(String content, String baseUrl) {
    final channels = <PlaylistItem>[];
    final lines = content.split(RegExp(r'\r?\n'));

    final map = <String, String>{};
    for (var line in lines) {
      final eq = line.indexOf('=');
      if (eq != -1) {
        final key = line.substring(0, eq).trim().toLowerCase();
        final val = line.substring(eq + 1).trim();
        map[key] = val;
      }
    }

    // Extract FileN and TitleN
    final entries = <int, Map<String, String>>{};
    for (final entry in map.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key.startsWith('file') || key.startsWith('title')) {
        final match = RegExp(r'^([a-z]+)(\d+)$').firstMatch(key);
        if (match != null) {
          final prefix = match.group(1)!;
          final index = int.parse(match.group(2)!);

          if (!entries.containsKey(index)) {
            entries[index] = {};
          }
          entries[index]![prefix] = val;
        }
      }
    }

    final sortedKeys = entries.keys.toList()..sort();
    for (final index in sortedKeys) {
      final entry = entries[index]!;
      final file = entry['file'];
      if (file != null) {
        channels.add(
          PlaylistItem(
            title: entry['title'] ?? 'Stream $index',
            url: _resolveUrl(normalizeUrl(file), baseUrl),
          ),
        );
      }
    }

    if (channels.isEmpty) {
      return PlaylistParseResult(type: PlaylistType.unknown);
    }

    return PlaylistParseResult(
      type: PlaylistType.channelList,
      channels: channels,
    );
  }

  static PlaylistParseResult _parseXspf(XmlDocument document, String baseUrl) {
    final channels = <PlaylistItem>[];
    final trackList = document.findAllElements('trackList').firstOrNull;
    if (trackList == null)
      return PlaylistParseResult(type: PlaylistType.unknown);

    final tracks = trackList.findElements('track');
    for (final track in tracks) {
      final location = track.findElements('location').firstOrNull?.innerText;
      if (location != null && location.isNotEmpty) {
        final title = track.findElements('title').firstOrNull?.innerText;
        final creator = track.findElements('creator').firstOrNull?.innerText;
        final image = track.findElements('image').firstOrNull?.innerText;

        final resolvedUrl = _resolveUrl(normalizeUrl(location), baseUrl);

        channels.add(
          PlaylistItem(
            title: title ?? creator ?? 'Stream',
            url: resolvedUrl,
            tvgLogo: image,
          ),
        );
      }
    }

    if (channels.isEmpty) {
      return PlaylistParseResult(type: PlaylistType.unknown);
    }

    return PlaylistParseResult(
      type: PlaylistType.channelList,
      channels: channels,
    );
  }

  static PlaylistParseResult _parseAsx(XmlDocument document, String baseUrl) {
    final channels = <PlaylistItem>[];

    // ASX is case-insensitive in Windows Media Player. The xml package is case-sensitive, so we check both.
    Iterable<XmlElement> getElements(XmlElement parent, String name) {
      return parent.children.whereType<XmlElement>().where(
        (e) => e.name.local.toLowerCase() == name.toLowerCase(),
      );
    }

    String? getAttributeCaseInsensitive(XmlElement element, String name) {
      for (final attr in element.attributes) {
        if (attr.name.local.toLowerCase() == name.toLowerCase()) {
          return attr.value;
        }
      }
      return null;
    }

    final entries = getElements(document.rootElement, 'entry');

    for (final entry in entries) {
      final ref = getElements(entry, 'ref').firstOrNull;
      final href = ref != null
          ? getAttributeCaseInsensitive(ref, 'href')
          : null;

      if (href != null && href.isNotEmpty) {
        final title = getElements(entry, 'title').firstOrNull?.innerText;

        final resolvedUrl = _resolveUrl(normalizeUrl(href), baseUrl);

        channels.add(PlaylistItem(title: title ?? 'Stream', url: resolvedUrl));
      }
    }

    if (channels.isEmpty) {
      return PlaylistParseResult(type: PlaylistType.unknown);
    }

    return PlaylistParseResult(
      type: PlaylistType.channelList,
      channels: channels,
    );
  }

  static String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    try {
      final base = Uri.parse(baseUrl);
      final resolved = base.resolve(url);
      return resolved.toString();
    } catch (_) {
      return url;
    }
  }

  /// Fetches and parses a remote playlist or stream.
  static Future<PlaylistParseResult> fetchAndParse(
    String rawUrl, {
    int maxBytes = 5 * 1024 * 1024,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final url = normalizeUrl(rawUrl);
    final internalClient = client ?? http.Client();
    StreamSubscription? subscription;

    try {
      final request = http.Request('GET', Uri.parse(url));

      bool timedOut = false;
      final responseFuture = internalClient.send(request);

      // Ensure that if the headers arrive AFTER a timeout threw, we still safely drain and abort the socket.
      // Canceling the stream subscription is the supported package:http mechanism for aborting a transfer.
      responseFuture
          .then((response) {
            if (timedOut) {
              response.stream.listen((_) {}).cancel();
            }
          })
          .catchError((_) {});

      final response = await responseFuture.timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load URL: ${response.statusCode}');
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      // If it's a known stream type (not a playlist), return it as a direct stream
      if (contentType.contains('video/mp2t') ||
          contentType.contains('video/mp4') ||
          (contentType.contains('audio/') &&
              !contentType.contains('mpegurl') &&
              !contentType.contains('x-scpls')) ||
          contentType.contains('application/dash+xml')) {
        // Cancel the stream safely without reading
        subscription = response.stream.listen((_) {});
        await subscription.cancel();
        return PlaylistParseResult(type: PlaylistType.unknown);
      }

      int bytesReceived = 0;
      final bytes = <int>[];
      final completer = Completer<List<int>>();

      subscription = response.stream.listen(
        (chunk) {
          bytesReceived += chunk.length;
          if (bytesReceived > maxBytes) {
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                Exception(
                  'File too large (exceeds ${maxBytes / 1024 / 1024}MB bound)',
                ),
              );
            }
          } else {
            bytes.addAll(chunk);
          }
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(bytes);
        },
        cancelOnError: true,
      );

      final finalBytes = await completer.future.timeout(timeout);
      final finalUrl = response.request?.url.toString() ?? url;

      final decodedString = _decodeBytes(finalBytes, contentType, finalUrl);
      return parseString(decodedString, finalUrl);
    } finally {
      await subscription?.cancel();
      if (client == null) {
        internalClient.close();
      }
    }
  }

  static String _decodeBytes(List<int> bytes, String contentType, String url) {
    bool isM3u8 =
        url.toLowerCase().endsWith('.m3u8') ||
        contentType.contains('application/vnd.apple.mpegurl');

    // Check Content-Type charset
    String? headerCharset;
    final match = RegExp(r'charset=([^\s;]+)').firstMatch(contentType);
    if (match != null) headerCharset = match.group(1)?.toLowerCase();

    // XML encoding declaration check (XSPF, ASX)
    String? xmlCharset;
    if (url.toLowerCase().endsWith('.xspf') ||
        url.toLowerCase().endsWith('.asx') ||
        contentType.contains('xml')) {
      // Decode only first ~200 bytes as ascii to find <?xml ... ?>
      final previewBytes = bytes.take(200).toList();
      final preview = ascii.decode(previewBytes, allowInvalid: true);
      final xmlMatch = RegExp(
        r'<\?xml[^>]+encoding=["'
        "'"
        r']([^"'
        "'"
        r']+)["'
        "'"
        r']',
      ).firstMatch(preview);
      if (xmlMatch != null) {
        xmlCharset = xmlMatch.group(1)?.toLowerCase();
      }
    }

    final targetCharset = xmlCharset ?? headerCharset;

    if (isM3u8) {
      // M3U8 strictly requires UTF-8
      return utf8.decode(bytes); // Will throw FormatException if invalid
    }

    if (targetCharset == 'iso-8859-1' || targetCharset == 'latin1') {
      return latin1.decode(bytes);
    }

    // Default to strict UTF-8
    try {
      return utf8.decode(bytes);
    } catch (e) {
      if (e is FormatException && targetCharset == null) {
        // Fallback to latin1 ONLY if it's an old M3U or unknown text format that didn't specify charset
        return latin1.decode(bytes);
      }
      rethrow;
    }
  }
}
