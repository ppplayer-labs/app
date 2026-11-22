// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ppplayer/core/cache/image_cache_manager.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/playback/playback_service.dart';
import 'package:ppplayer/core/providers/genre_providers.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/core/theme/app_theme.dart';
import 'package:ppplayer/features/home/home_screen.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/main.dart' show configureDesktopImageCache;
import 'package:ppplayer/shared/widgets/shimmer_placeholder.dart';

final int _kCacheMb =
    int.tryParse(Platform.environment['CACHE_MB'] ?? '') ??
    const int.fromEnvironment('CACHE_MB', defaultValue: 80);
final int _kCacheCount =
    int.tryParse(Platform.environment['CACHE_COUNT'] ?? '') ??
    const int.fromEnvironment('CACHE_COUNT', defaultValue: 300);
final double? _kForceDpr = double.tryParse(
  Platform.environment['FORCE_DPR'] ?? '',
);

/// Instrumented ImageCache subclass that accurately counts RAM cache hits,
/// misses (actual decodes), and evictions on real Flutter desktop runs.
class _InstrumentedImageCache extends ImageCache {
  int hits = 0;
  int misses = 0;
  int evictions = 0;

  void resetCounters() {
    hits = 0;
    misses = 0;
    evictions = 0;
  }

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) {
    final beforeStatus = statusForKey(key);
    final beforeSize = currentSize;
    final result = super.putIfAbsent(key, loader, onError: onError);
    if (beforeStatus.keepAlive || beforeStatus.pending || beforeStatus.live) {
      hits++;
    } else {
      misses++;
      if (currentSize <= beforeSize && beforeSize >= maximumSize) {
        evictions++;
      }
    }
    return result;
  }
}

class _BenchmarkBinding extends WidgetsFlutterBinding {
  late final _InstrumentedImageCache instrumentedCache;

  @override
  ImageCache createImageCache() {
    instrumentedCache = _InstrumentedImageCache();
    return instrumentedCache;
  }

  static _BenchmarkBinding ensureInitialized() {
    _BenchmarkBinding();
    return WidgetsBinding.instance as _BenchmarkBinding;
  }
}

class _BenchmarkSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState(
    selectedCountry: 'US',
    userName: 'PerfTester',
    isLoaded: true,
    showVideo: false,
  );
}

/// Generates a valid 640x640 RGB PNG with a unique color gradient per seed so
/// every artwork URL decodes a realistic 640x640 image through Impeller/Metal.
Uint8List _generatePng640(int seed) {
  const width = 640;
  const height = 640;
  final rBase = (seed * 53) & 0xFF;
  final gBase = (seed * 97 + 40) & 0xFF;
  final bBase = (seed * 151 + 80) & 0xFF;

  // Build raw scanlines (1 filter byte + width * 3 RGB bytes per row).
  final stride = 1 + width * 3;
  final raw = Uint8List(height * stride);
  for (int y = 0; y < height; y++) {
    final rowStart = y * stride;
    raw[rowStart] = 0; // filter None
    final gRow = (gBase + (y >> 2)) & 0xFF;
    for (int x = 0; x < width; x++) {
      final p = rowStart + 1 + x * 3;
      raw[p] = (rBase + (x >> 2)) & 0xFF;
      raw[p + 1] = gRow;
      raw[p + 2] = (bBase + ((x + y) >> 3)) & 0xFF;
    }
  }
  final compressed = zlib.encode(raw);

  final out = BytesBuilder(copy: false);
  // PNG signature
  out.add(const [137, 80, 78, 71, 13, 10, 26, 10]);

  void writeChunk(String type, List<int> data) {
    final lenBytes = ByteData(4)..setUint32(0, data.length);
    out.add(lenBytes.buffer.asUint8List());
    final typeBytes = type.codeUnits;
    out.add(typeBytes);
    out.add(data);
    final crc = _crc32(typeBytes, data);
    final crcBytes = ByteData(4)..setUint32(0, crc);
    out.add(crcBytes.buffer.asUint8List());
  }

  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // color type RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  writeChunk('IHDR', ihdr.buffer.asUint8List());
  writeChunk('IDAT', compressed);
  writeChunk('IEND', const []);
  return out.toBytes();
}

final List<int> _crcTable = () {
  final table = List<int>.filled(256, 0);
  for (int n = 0; n < 256; n++) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xedb88320 ^ (c >> 1)) : (c >> 1);
    }
    table[n] = c;
  }
  return table;
}();

int _crc32(List<int> type, List<int> data) {
  int c = 0xffffffff;
  for (final b in type) {
    c = _crcTable[(c ^ b) & 0xff] ^ (c >> 8);
  }
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xff] ^ (c >> 8);
  }
  return c ^ 0xffffffff;
}

class _LocalArtworkServer {
  late final HttpServer _server;
  final Map<int, Uint8List> _pngCache = {};
  final Map<String, int> requestCounts = {};
  int totalRequests = 0;
  bool offline = false;

  int get port => _server.port;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final path = req.uri.path;
      totalRequests++;
      requestCounts[path] = (requestCounts[path] ?? 0) + 1;

      if (offline || path.contains('broken')) {
        req.response.statusCode = offline ? 503 : 404;
        await req.response.close();
        return;
      }

      final match = RegExp(r'/img_(\d+)\.png').firstMatch(path);
      final id = match != null ? int.parse(match.group(1)!) : 0;
      final bytes = _pngCache.putIfAbsent(id, () => _generatePng640(id));
      req.response.headers.contentType = ContentType('image', 'png');
      req.response.headers.set('cache-control', 'public, max-age=86400');
      req.response.add(bytes);
      await req.response.close();
    });
  }

  String url(int id) => 'http://127.0.0.1:$port/img_$id.png';
  String brokenUrl(int id) => 'http://127.0.0.1:$port/broken_$id.png';

  Future<void> close() => _server.close(force: true);
}

class _FrameStats {
  final List<double> buildMs = [];
  final List<double> rasterMs = [];
  final List<double> totalMs = [];

  void record(FrameTiming t) {
    final b = t.buildDuration.inMicroseconds / 1000.0;
    final r = t.rasterDuration.inMicroseconds / 1000.0;
    final tot = t.totalSpan.inMicroseconds / 1000.0;
    buildMs.add(b);
    rasterMs.add(r);
    totalMs.add(tot);
  }

  void clear() {
    buildMs.clear();
    rasterMs.clear();
    totalMs.clear();
  }

  String summarize() {
    if (buildMs.isEmpty) return 'frames=0';
    double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    double pct(List<double> v, double p) {
      final sorted = List<double>.from(v)..sort();
      final idx = ((sorted.length - 1) * p).round().clamp(0, sorted.length - 1);
      return sorted[idx];
    }

    final jank16 = totalMs.where((t) => t > 16.67).length;
    final jank33 = totalMs.where((t) => t > 33.33).length;
    final maxBuild = buildMs.reduce(math.max);
    final maxRaster = rasterMs.reduce(math.max);
    return 'frames=${buildMs.length} '
        'build(avg=${avg(buildMs).toStringAsFixed(2)}ms p95=${pct(buildMs, 0.95).toStringAsFixed(2)}ms max=${maxBuild.toStringAsFixed(2)}ms) '
        'raster(avg=${avg(rasterMs).toStringAsFixed(2)}ms p95=${pct(rasterMs, 0.95).toStringAsFixed(2)}ms max=${maxRaster.toStringAsFixed(2)}ms) '
        'jank>16.7ms=$jank16 jank>33.3ms=$jank33';
  }
}

Future<void> main() async {
  final binding = _BenchmarkBinding.ensureInitialized();
  configureDesktopImageCache(binding.instrumentedCache);
  binding.instrumentedCache.maximumSizeBytes = _kCacheMb * 1024 * 1024;
  binding.instrumentedCache.maximumSize = _kCacheCount;

  // Use a fresh isolated disk cache per run so cold vs warm behavior is clean.
  final tempCacheDir = await Directory.systemTemp.createTemp('pp_bench_cache_');
  final cacheManager = CacheManager(
    Config(
      'ppBenchCache_${DateTime.now().millisecondsSinceEpoch}',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 500,
    ),
  );
  PPImageCacheManager.debugTestOverride = cacheManager;

  final server = _LocalArtworkServer();
  await server.start();

  // Pre-generate 180 PNGs outside timed UI phases so server latency is ~0ms.
  for (int i = 0; i < 180; i++) {
    server._pngCache[i] = _generatePng640(i);
  }

  final effectiveDpr =
      _kForceDpr ?? binding.platformDispatcher.views.first.devicePixelRatio;
  final baselineRssMb = ProcessInfo.currentRss / (1024 * 1024);
  stdout.writeln(
    '[BENCH_CONFIG] cacheMaxMB=$_kCacheMb cacheMaxEntries=$_kCacheCount '
    'dpr=$effectiveDpr baselineRssMB=${baselineRssMb.toStringAsFixed(2)}',
  );

  final fetchCounts = <String, int>{};
  int bump(String key) => fetchCounts[key] = (fetchCounts[key] ?? 0) + 1;

  // Build realistic dataset mirroring real Spotify payloads:
  // - 50 Popular Tracks (47 valid URLs, 2 missing artwork, 1 HTTP 404)
  // - 10 Continue Listening tracks (overlapping with Popular Tracks)
  // - 10 Popular Artists
  // - 10 Popular Albums (multi-resolution [640, 300, 64] sharing track covers)
  // - 10 New Releases (multi-resolution [640, 300, 64])
  // - 20 Featured Playlists (10 3-track collages + 10 multi-res standard)
  // - 12 Genres
  final popularTracks = List.generate(50, (i) {
    final String? img;
    if (i == 47 || i == 48) {
      img = ''; // Missing artwork -> must show fallback icon
    } else if (i == 49) {
      img = server.brokenUrl(i); // Failed load -> must show fallback icon
    } else {
      img = server.url(i);
    }
    return Track(
      spotifyId: 'track_$i',
      name: 'Popular Track $i',
      artistId: 'artist_${i % 10}',
      artistName: 'Artist ${i % 10}',
      albumId: 'album_${i % 15}',
      albumName: 'Album ${i % 15}',
      albumImage: img,
      durationMs: 210000,
    );
  });

  final recentTracks = List.generate(10, (i) => popularTracks[i]);

  final artists = List.generate(
    10,
    (i) => <String, dynamic>{
      'id': 'artist_$i',
      'name': 'Artist $i',
      'images': [
        {'url': server.url(50 + i), 'width': 640, 'height': 640},
        {'url': server.url(50 + i), 'width': 300, 'height': 300},
      ],
    },
  );

  final mixes = <Map<String, dynamic>>[
    {
      'type': 'artist',
      'id': 'artist_0',
      'title': 'Daily Mix 1',
      'subtitle': 'Your favorites\nand new discoveries',
      'imageAsset': 'assets/images/mix_covers/daily_mix_1.jpg',
      'color1': AppTheme.themeColors[0],
      'color2': AppTheme.themeColors[1],
    },
    {
      'type': 'artist',
      'id': 'artist_1',
      'title': 'Daily Mix 2',
      'subtitle': 'Your favorites\nand new discoveries',
      'imageAsset': 'assets/images/mix_covers/daily_mix_2.jpg',
      'color1': AppTheme.themeColors[2],
      'color2': AppTheme.themeColors[3],
    },
    {
      'type': 'genre',
      'id': 'pop',
      'title': 'Discover Weekly',
      'subtitle': 'Made for you',
      'imageAsset': 'assets/images/mix_covers/discover_weekly.jpg',
      'color1': AppTheme.themeColors[4],
      'color2': AppTheme.themeColors[5],
    },
    {
      'type': 'genre',
      'id': 'new-release',
      'title': 'Release Radar',
      'subtitle': 'New music\njust for you',
      'imageAsset': 'assets/images/mix_covers/release_radar.jpg',
      'color1': AppTheme.themeColors[6],
      'color2': AppTheme.themeColors[7],
    },
    {
      'type': 'genre',
      'id': 'chill',
      'title': 'Chill Mix',
      'subtitle': 'Relax and unwind',
      'imageAsset': 'assets/images/mix_covers/chill_mix.jpg',
      'color1': AppTheme.themeColors[8],
      'color2': AppTheme.themeColors[9],
    },
    {
      'type': 'genre',
      'id': 'study',
      'title': 'Focus Mix',
      'subtitle': 'Deep focus\nand productivity',
      'imageAsset': 'assets/images/mix_covers/focus_mix.jpg',
      'color1': AppTheme.themeColors[10],
      'color2': AppTheme.themeColors[11],
    },
  ];

  final stations = List.generate(
    8,
    (i) => <String, dynamic>{
      'type': 'artist',
      'id': 'artist_$i',
      'name': 'Artist $i',
      'imageUrl': server.url(50 + i),
      'title': 'Artist $i Radio',
    },
  );

  final popularAlbums = List.generate(
    10,
    (i) => <String, dynamic>{
      'id': 'album_$i',
      'name': 'Popular Album $i',
      'images': [
        {'url': server.url(i), 'width': 640, 'height': 640},
        {'url': server.url(90 + i), 'width': 300, 'height': 300},
        {'url': server.url(100 + i), 'width': 64, 'height': 64},
      ],
      'artists': [
        {'id': 'artist_$i', 'name': 'Artist $i'},
      ],
    },
  );

  final newReleases = List.generate(
    10,
    (i) => <String, dynamic>{
      'id': 'release_$i',
      'name': 'New Release $i',
      'images': [
        {'url': server.url(60 + i), 'width': 640, 'height': 640},
        {'url': server.url(90 + i), 'width': 300, 'height': 300},
        {'url': server.url(100 + i), 'width': 64, 'height': 64},
      ],
      'artists': [
        {'id': 'artist_$i', 'name': 'Artist $i'},
      ],
    },
  );

  final featuredPlaylists = List.generate(20, (i) {
    if (i < 10) {
      // Enriched 3-track collage playlist (no width/height)
      return <String, dynamic>{
        'id': 'playlist_$i',
        'name': 'Featured Playlist $i',
        'images': [
          {'url': server.url((i * 3) % 45)},
          {'url': server.url((i * 3 + 1) % 45)},
          {'url': server.url((i * 3 + 2) % 45)},
        ],
      };
    }
    // Standard Spotify mosaic playlist (multi-resolution variants)
    return <String, dynamic>{
      'id': 'playlist_$i',
      'name': 'Featured Playlist $i',
      'images': [
        {'url': server.url(70 + (i - 10)), 'width': 640, 'height': 640},
        {'url': server.url(100 + (i - 10)), 'width': 300, 'height': 300},
        {'url': server.url(110 + (i - 10)), 'width': 60, 'height': 60},
      ],
    };
  });

  final genres = List.generate(
    12,
    (i) => <String, dynamic>{
      'id': 'genre_$i',
      'name': 'Genre $i',
      'icons': [
        {'url': server.url(80 + (i % 10))},
      ],
    },
  );

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '/discover',
        pageBuilder: (context, state) => NoTransitionPage(
          child: Scaffold(
            body: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 36,
              itemBuilder: (_, i) => Image.network(
                server.url(120 + i),
                cacheWidth: (160 * effectiveDpr).round(),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/library',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: Scaffold(body: Center(child: Text('Library Route'))),
        ),
      ),
      GoRoute(
        path: '/playlist/remote/:id',
        builder: (context, state) => Scaffold(
          body: Center(child: Text('Playlist ${state.pathParameters['id']}')),
        ),
      ),
    ],
  );

  final frameStats = _FrameStats();
  binding.addTimingsCallback((timings) {
    for (final t in timings) {
      frameStats.record(t);
    }
  });

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_BenchmarkSettingsNotifier.new),
        recentlyPlayedProvider.overrideWith((ref) async {
          bump('recent');
          return recentTracks;
        }),
        popularArtistsProvider.overrideWith((ref) {
          bump('artists');
          return Stream.value(artists);
        }),
        madeForYouMixesProvider.overrideWith((ref) {
          bump('mixes');
          return Stream.value(mixes);
        }),
        suggestedStationsProvider.overrideWith((ref) {
          bump('stations');
          return Stream.value(stations);
        }),
        marketPopularAlbumsProvider.overrideWith((ref) {
          bump('albums');
          return Stream.value(popularAlbums);
        }),
        browseCategoriesProvider.overrideWith((ref) {
          bump('genres');
          return Stream.value(genres);
        }),
        newReleasesProvider.overrideWith((ref) {
          bump('releases');
          return Stream.value(newReleases);
        }),
        featuredPlaylistsProvider.overrideWith((ref) {
          bump('playlists');
          return Stream.value(featuredPlaylists);
        }),
        popularTracksProvider.overrideWith((ref) {
          bump('tracks');
          return Stream.value(popularTracks);
        }),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(primaryColor: AppTheme.themeColors[0]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return Center(
            child: SizedBox(
              width: math.min(mq.size.width, 1280),
              height: math.min(mq.size.height, 800),
              child: MediaQuery(
                data: mq.copyWith(
                  size: Size(
                    math.min(mq.size.width, 1280),
                    math.min(mq.size.height, 800),
                  ),
                  devicePixelRatio: effectiveDpr,
                ),
                child: child!,
              ),
            ),
          );
        },
        routerConfig: router,
      ),
    ),
  );

  // Helper to locate a ScrollableState inside the mounted tree by key.
  ScrollableState? findScrollableByKey(Key targetKey) {
    ScrollableState? result;
    void walk(Element el) {
      if (result != null) return;
      if (el.widget.key == targetKey) {
        void walkDesc(Element d) {
          if (result != null) return;
          if (d is StatefulElement && d.state is ScrollableState) {
            result = d.state as ScrollableState;
            return;
          }
          d.visitChildren(walkDesc);
        }

        el.visitChildren(walkDesc);
        return;
      }
      el.visitChildren(walk);
    }

    final root = binding.rootElement;
    if (root != null) walk(root);
    return result;
  }

  int countWidgetType<W extends Widget>() {
    int count = 0;
    void walk(Element el) {
      if (el.widget is W) count++;
      el.visitChildren(walk);
    }

    final root = binding.rootElement;
    if (root != null) walk(root);
    return count;
  }

  int countFallbackIcons() {
    int count = 0;
    void walk(Element el) {
      final w = el.widget;
      if (w is Icon && w.icon == Icons.music_note_rounded) count++;
      el.visitChildren(walk);
    }

    final root = binding.rootElement;
    if (root != null) walk(root);
    return count;
  }

  void logStage(String stage) {
    final cache = binding.instrumentedCache;
    final rssMb = ProcessInfo.currentRss / (1024 * 1024);
    final cacheMb = cache.currentSizeBytes / (1024 * 1024);
    final totalLookups = cache.hits + cache.misses;
    final hitRate = totalLookups > 0
        ? (cache.hits * 100.0 / totalLookups).toStringAsFixed(1)
        : 'n/a';
    final duplicateHttp = server.requestCounts.values
        .where((c) => c > 1)
        .fold<int>(0, (sum, c) => sum + (c - 1));
    stdout.writeln(
      '[BENCH_STAGE] $stage | rssMB=${rssMb.toStringAsFixed(2)} '
      'imgCache=${cache.currentSize}/${cache.maximumSize} '
      'imgCacheMB=${cacheMb.toStringAsFixed(2)}/${(cache.maximumSizeBytes / (1024 * 1024)).toStringAsFixed(0)} '
      'live=${cache.liveImageCount} pending=${cache.pendingImageCount} '
      'hits=${cache.hits} misses=${cache.misses} hitRate=$hitRate% evictions=${cache.evictions} '
      'httpTotal=${server.totalRequests} httpDup=$duplicateHttp '
      'shimmers=${countWidgetType<SectionShimmer>()} '
      'providers=$fetchCounts | ${frameStats.summarize()}',
    );
  }

  Future<void> waitFrames([int ms = 250]) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
  }

  // Phase 1: Initial Home load (allow all staggered sections + initial scroll down to warm all sections).
  await waitFrames(4500);
  var mainScroll = findScrollableByKey(
    const PageStorageKey<String>('home_scroll_view'),
  );
  if (mainScroll == null) {
    stderr.writeln('ERROR: could not find home_scroll_view');
    exit(2);
  }
  // Scroll down once to materialize lower sections on cold load.
  await mainScroll.position.animateTo(
    mainScroll.position.maxScrollExtent,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
  await waitFrames(1500);
  await mainScroll.position.animateTo(
    0,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
  await waitFrames(800);
  logStage('initial_loaded');

  // Verify zero shimmers and zero refetches before starting steady-state measurement.
  final httpAfterWarmup = server.totalRequests;
  final providersAfterWarmup = Map<String, int>.from(fetchCounts);

  // Phase 2: Scenario A — 10 vertical scroll cycles + rapid direction changes.
  binding.instrumentedCache.resetCounters();
  frameStats.clear();
  int shimmersSeenDuringScroll = 0;

  for (int cycle = 0; cycle < 10; cycle++) {
    final max = mainScroll.position.maxScrollExtent;
    await mainScroll.position.animateTo(
      max,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
    shimmersSeenDuringScroll += countWidgetType<SectionShimmer>();
    // Rapid direction reversal mid-way
    await mainScroll.position.animateTo(
      max * 0.45,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
    await mainScroll.position.animateTo(
      max * 0.8,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
    await mainScroll.position.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
    shimmersSeenDuringScroll += countWidgetType<SectionShimmer>();
    await waitFrames(40);
  }
  logStage('after_10_vertical_cycles (shimmersSeen=$shimmersSeenDuringScroll)');

  // Phase 3: 20 more cycles (30 total) for leak & steady-state stability.
  for (int cycle = 0; cycle < 20; cycle++) {
    final max = mainScroll.position.maxScrollExtent;
    await mainScroll.position.animateTo(
      max,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
    shimmersSeenDuringScroll += countWidgetType<SectionShimmer>();
    await mainScroll.position.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
    shimmersSeenDuringScroll += countWidgetType<SectionShimmer>();
  }
  logStage('after_30_vertical_cycles (shimmersSeen=$shimmersSeenDuringScroll)');

  // Phase 4: Scenario B — Horizontal scrolling (Continue Listening + Popular Tracks 50 items)
  // and verify horizontal offset survives vertical disposal & remount.
  binding.instrumentedCache.resetCounters();
  frameStats.clear();
  final recentHoriz = findScrollableByKey(
    const PageStorageKey<String>('home_list_continue_listening'),
  );
  double savedHorizOffset = 0;
  if (recentHoriz != null && recentHoriz.position.maxScrollExtent > 0) {
    await recentHoriz.position.animateTo(
      math.min(360.0, recentHoriz.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    savedHorizOffset = recentHoriz.position.pixels;
  }
  // Scroll down to Popular Tracks and sweep through all 50 cards horizontally.
  await mainScroll.position.animateTo(
    mainScroll.position.maxScrollExtent,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
  );
  await waitFrames(300);
  final tracksHoriz = findScrollableByKey(
    const PageStorageKey<String>('home_list_popular_tracks'),
  );
  int fallbackIconsAtPopularTracksEnd = 0;
  if (tracksHoriz != null && tracksHoriz.position.maxScrollExtent > 0) {
    // Step smoothly across all 50 cards so every card builds and decodes.
    final maxH = tracksHoriz.position.maxScrollExtent;
    for (int step = 1; step <= 6; step++) {
      await tracksHoriz.position.animateTo(
        maxH * (step / 6),
        duration: const Duration(milliseconds: 180),
        curve: Curves.linear,
      );
      await waitFrames(180);
    }
    await waitFrames(400);
    fallbackIconsAtPopularTracksEnd = countFallbackIcons();
    await tracksHoriz.position.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
    );
    await waitFrames(300);
  }
  // Scroll back to top and check Continue Listening horizontal scroll preservation.
  await mainScroll.position.animateTo(
    0,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
  );
  await waitFrames(150);
  final restoredHoriz = findScrollableByKey(
    const PageStorageKey<String>('home_list_continue_listening'),
  );
  final restoredHorizOffset = restoredHoriz?.position.pixels ?? -1;
  logStage(
    'after_horizontal_scroll (savedOffset=${savedHorizOffset.toStringAsFixed(1)} restoredOffset=${restoredHorizOffset.toStringAsFixed(1)} fallbackIcons=$fallbackIconsAtPopularTracksEnd)',
  );

  // Phase 5: Scenario C — Navigation cycles (Home -> Discover -> Home -> Library -> Home -> Playlist -> Home)
  binding.instrumentedCache.resetCounters();
  frameStats.clear();
  await mainScroll.position.animateTo(
    420,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );
  final preNavVerticalOffset = mainScroll.position.pixels;
  int shimmersOnNavReturn = 0;
  for (int i = 0; i < 3; i++) {
    router.go('/discover');
    await waitFrames(150);
    router.go('/home');
    await waitFrames(200);
    shimmersOnNavReturn += countWidgetType<SectionShimmer>();

    router.go('/library');
    await waitFrames(150);
    router.go('/home');
    await waitFrames(200);
    shimmersOnNavReturn += countWidgetType<SectionShimmer>();

    router.push('/playlist/remote/playlist_0');
    await waitFrames(150);
    router.pop();
    await waitFrames(200);
    shimmersOnNavReturn += countWidgetType<SectionShimmer>();
  }
  mainScroll = findScrollableByKey(
    const PageStorageKey<String>('home_scroll_view'),
  );
  final postNavVerticalOffset = mainScroll?.position.pixels ?? -1;
  logStage(
    'after_navigation_cycles (preNavY=${preNavVerticalOffset.toStringAsFixed(1)} postNavY=${postNavVerticalOffset.toStringAsFixed(1)} shimmersOnReturn=$shimmersOnNavReturn)',
  );

  // Phase 6: Scenario D — Offline mode scrolling (cached images stay rendered, no shimmers).
  server.offline = true;
  binding.instrumentedCache.resetCounters();
  frameStats.clear();
  if (mainScroll != null) {
    await mainScroll.position.animateTo(
      mainScroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    await waitFrames(150);
    await mainScroll.position.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    await waitFrames(150);
  }
  logStage('after_offline_scroll');

  // Phase 7: Return to idle.
  await waitFrames(3000);
  logStage('return_to_idle');

  final httpDeltaAfterWarmup = server.totalRequests - httpAfterWarmup;
  final providersUnchanged =
      fetchCounts.toString() == providersAfterWarmup.toString();
  stdout.writeln(
    '[BENCH_SUMMARY] cacheMB=$_kCacheMb cacheEntries=$_kCacheCount '
    'httpAfterWarmup=$httpAfterWarmup httpDeltaTotal=$httpDeltaAfterWarmup '
    'providersUnchanged=$providersUnchanged '
    'shimmersDuringScroll=$shimmersSeenDuringScroll '
    'shimmersOnNavReturn=$shimmersOnNavReturn',
  );

  await server.close();
  await cacheManager.emptyCache();
  await tempCacheDir.delete(recursive: true);
  exit(0);
}
