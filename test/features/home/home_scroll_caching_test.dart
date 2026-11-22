import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ppplayer/core/models/track.dart';
import 'package:ppplayer/core/playback/playback_service.dart';
import 'package:ppplayer/core/providers/genre_providers.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/features/home/home_screen.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/section_wrapper.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState(
    selectedCountry: 'US',
    userName: 'Tester',
    isLoaded: true,
    showVideo: true,
  );

  @override
  Future<void> toggleVideo() async {
    state = state.copyWith(showVideo: !state.showVideo);
  }
}

Track _makeTrack(int i) => Track(
  spotifyId: 'track_$i',
  name: 'Track $i',
  artistId: 'artist_$i',
  artistName: 'Artist $i',
  albumId: 'album_$i',
  albumName: 'Album $i',
  albumImage: '',
  durationMs: 180000,
);

void main() {
  group('StaggeredHomeSection scroll lifecycle & caching', () {
    testWidgets(
      'does not restart stagger delay, show shimmer, or refetch after scrolling off-screen and back',
      (tester) async {
        int fetchCount = 0;
        final testProvider = StreamProvider<List<String>>((ref) {
          fetchCount++;
          return Stream.value(const ['Item Alpha', 'Item Beta']);
        });

        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: CustomScrollView(
                  controller: scrollController,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(100),
                  slivers: [
                    SliverList.list(
                      children: [
                        StaggeredHomeSection<String>(
                          key: const ValueKey('test_section'),
                          title: 'Test Section',
                          provider: testProvider,
                          delay: const Duration(seconds: 3),
                          builder: (context, ref, items) => SizedBox(
                            height: 160,
                            child: Column(
                              children: items.map(Text.new).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2200),
                        const SizedBox(
                          height: 200,
                          child: Text('Bottom Anchor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Before initial stagger completes: shimmer is visible and provider not yet read.
        expect(find.byType(SectionShimmer), findsOneWidget);
        expect(fetchCount, 0);

        // Advance past the initial 3s stagger delay.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(fetchCount, 1);
        expect(find.text('Item Alpha'), findsOneWidget);
        expect(find.byType(SectionShimmer), findsNothing);

        // Scroll far past cacheExtent so SliverList disposes the section (low memory).
        scrollController.jumpTo(2000);
        await tester.pump();
        expect(find.text('Item Alpha'), findsNothing);
        expect(find.text('Bottom Anchor'), findsOneWidget);

        // Scroll back to the top: section must render immediately on the first frame
        // with ZERO shimmer, ZERO delay timer, and ZERO provider refetch.
        scrollController.jumpTo(0);
        await tester.pump();

        expect(find.byType(SectionShimmer), findsNothing);
        expect(find.text('Item Alpha'), findsOneWidget);
        expect(find.text('Item Beta'), findsOneWidget);
        expect(fetchCount, 1);
      },
    );

    testWidgets(
      'honors staggerOrigin when initial stagger window has already elapsed',
      (tester) async {
        int fetchCount = 0;
        final testProvider = StreamProvider<List<String>>((ref) {
          fetchCount++;
          return Stream.value(const ['Ready Immediately']);
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: StaggeredHomeSection<String>(
                  title: 'Late Mounted Section',
                  provider: testProvider,
                  delay: const Duration(seconds: 4),
                  staggerOrigin: DateTime.now().subtract(
                    const Duration(seconds: 5),
                  ),
                  builder: (context, ref, items) => Text(items.first),
                ),
              ),
            ),
          ),
        );

        // Pump once to resolve Stream.value microtask — no 4s delay should occur.
        await tester.pump();
        await tester.pump();

        expect(fetchCount, 1);
        expect(find.byType(SectionShimmer), findsNothing);
        expect(find.text('Ready Immediately'), findsOneWidget);

        // Settle SectionWrapper's one-shot 250ms initial entry fade-in.
        await tester.pumpAndSettle();
      },
    );
  });

  group('SectionWrapper animation & reload stability', () {
    testWidgets(
      'skips fade-in Animate wrapper when mounted with already-loaded data',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SectionWrapper<String>(
                title: 'Cached Section',
                asyncValue: const AsyncValue.data(['Cached Item']),
                builder: (data) => Text(data.first),
              ),
            ),
          ),
        );

        expect(find.text('Cached Item'), findsOneWidget);
        expect(find.byType(Animate), findsNothing);
      },
    );

    testWidgets(
      'preserves previously loaded content during background reload instead of showing shimmer',
      (tester) async {
        final reloadCompleter = Completer<List<String>>();
        int calls = 0;
        final refreshingProvider = FutureProvider<List<String>>((ref) {
          calls++;
          if (calls == 1) {
            return Future.value(const ['Existing Track']);
          }
          return reloadCompleter.future;
        });

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    capturedRef = ref;
                    return SectionWrapper<String>(
                      title: 'Refreshing Section',
                      asyncValue: ref.watch(refreshingProvider),
                      builder: (data) => Text(data.first),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Existing Track'), findsOneWidget);

        // Trigger a provider refresh/reload while the new future is still pending.
        capturedRef.invalidate(refreshingProvider);
        await tester.pump();

        expect(capturedRef.read(refreshingProvider).isLoading, isTrue);
        expect(find.text('Existing Track'), findsOneWidget);
        expect(find.byType(ShimmerPlaceholder), findsNothing);

        reloadCompleter.complete(const ['Updated Track']);
        await tester.pumpAndSettle();
        expect(find.text('Updated Track'), findsOneWidget);
      },
    );

    testWidgets(
      'shows loading shimmer when retrying after an error and recovers on success',
      (tester) async {
        final retryCompleter = Completer<List<String>>();
        int attempts = 0;
        final flakyProvider = FutureProvider<List<String>>((ref) {
          attempts++;
          if (attempts == 1) {
            return Future<List<String>>.error(Exception('Temporary offline'));
          }
          return retryCompleter.future;
        }, retry: (_, _) => null);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => SectionWrapper<String>(
                    title: 'Flaky Section',
                    asyncValue: ref.watch(flakyProvider),
                    builder: (data) => Text(data.first),
                    onRetry: () => ref.invalidate(flakyProvider),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

        // Tapping Retry must immediately show loading feedback instead of staying stuck on error.
        await tester.tap(find.byType(TextButton));
        await tester.pump();

        expect(find.byType(ShimmerPlaceholder), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

        retryCompleter.complete(const ['Recovered Content']);
        await tester.pumpAndSettle();

        expect(find.text('Recovered Content'), findsOneWidget);
        expect(attempts, 2);
      },
    );
  });

  group('StaggeredHomeSection timer lifecycle & disposal', () {
    testWidgets(
      'cancels pending stagger timer cleanly when disposed before delay elapses',
      (tester) async {
        int fetchCount = 0;
        final delayedProvider = StreamProvider<List<String>>((ref) {
          fetchCount++;
          return Stream.value(const ['Should Not Fetch']);
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: StaggeredHomeSection<String>(
                  title: 'Transient Section',
                  provider: delayedProvider,
                  delay: const Duration(seconds: 4),
                  builder: (context, ref, items) => Text(items.first),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(SectionShimmer), findsOneWidget);

        // Dispose widget before the 4s stagger timer fires.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 5));

        expect(fetchCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('HomeScreen end-to-end scroll stability', () {
    testWidgets(
      'scrolling down and back up does not reload sections, preserves horizontal scroll offset, and ignores unrelated setting changes',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fetchCounts = <String, int>{};
        int bump(String key) => fetchCounts[key] = (fetchCounts[key] ?? 0) + 1;

        final tracks = List.generate(12, _makeTrack);
        final artists = List.generate(
          10,
          (i) => <String, dynamic>{
            'id': 'artist_$i',
            'name': 'Popular Artist $i',
            'images': const <Map<String, dynamic>>[],
          },
        );
        final albums = List.generate(
          8,
          (i) => <String, dynamic>{
            'id': 'album_$i',
            'name': 'Popular Album $i',
            'images': const <Map<String, dynamic>>[],
            'artists': [
              {'id': 'artist_$i', 'name': 'Artist $i'},
            ],
          },
        );
        final genres = List.generate(
          6,
          (i) => <String, dynamic>{
            'id': 'genre_$i',
            'name': 'Genre $i',
            'icons': const <Map<String, dynamic>>[],
          },
        );
        final playlists = List.generate(
          8,
          (i) => <String, dynamic>{
            'id': 'playlist_$i',
            'name': 'Featured Playlist $i',
            'images': const <Map<String, dynamic>>[],
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(_TestSettingsNotifier.new),
              recentlyPlayedProvider.overrideWith((ref) async {
                bump('recent');
                return tracks;
              }),
              popularArtistsProvider.overrideWith((ref) {
                bump('artists');
                return Stream.value(artists);
              }),
              madeForYouMixesProvider.overrideWith((ref) {
                bump('mixes');
                return Stream.value(const <Map<String, dynamic>>[]);
              }),
              suggestedStationsProvider.overrideWith((ref) {
                bump('stations');
                return Stream.value(const <Map<String, dynamic>>[]);
              }),
              marketPopularAlbumsProvider.overrideWith((ref) {
                bump('albums');
                return Stream.value(albums);
              }),
              browseCategoriesProvider.overrideWith((ref) {
                bump('genres');
                return Stream.value(genres);
              }),
              newReleasesProvider.overrideWith((ref) {
                bump('releases');
                return Stream.value(albums);
              }),
              featuredPlaylistsProvider.overrideWith((ref) {
                bump('playlists');
                return Stream.value(playlists);
              }),
              popularTracksProvider.overrideWith((ref) {
                bump('tracks');
                return Stream.value(tracks);
              }),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: HomeScreen(),
            ),
          ),
        );

        // Allow initial staggers to finish.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(find.text('Track 0'), findsOneWidget);
        expect(find.text('Popular Artist 0'), findsOneWidget);
        expect(find.byType(SectionShimmer), findsNothing);

        // Scroll horizontally inside Continue Listening so we can verify
        // PageStorage restores the offset after vertical disposal/remount.
        final horizontalListFinder = find.byKey(
          const PageStorageKey<String>('home_list_continue_listening'),
        );
        expect(horizontalListFinder, findsOneWidget);
        await tester.drag(horizontalListFinder, const Offset(-350, 0));
        await tester.pumpAndSettle();
        final horizontalScrollable = tester.state<ScrollableState>(
          find.descendant(
            of: horizontalListFinder,
            matching: find.byType(Scrollable),
          ),
        );
        final savedHorizontalOffset = horizontalScrollable.position.pixels;
        expect(savedHorizontalOffset, greaterThan(100));

        // Scroll vertically all the way down so top sections leave the cacheExtent.
        final mainScrollFinder = find.byKey(
          const PageStorageKey<String>('home_scroll_view'),
        );
        final mainScrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: mainScrollFinder,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        mainScrollable.position.jumpTo(mainScrollable.position.maxScrollExtent);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(find.text('Featured Playlist 0'), findsWidgets);

        // Record fetch counts once every section has loaded.
        final countsAfterInitialLoad = Map<String, int>.from(fetchCounts);

        // Scroll back to the top and pump ONE single frame (no stagger wait!).
        mainScrollable.position.jumpTo(0);
        await tester.pump();

        expect(find.byType(SectionShimmer), findsNothing);
        expect(find.byType(ShimmerPlaceholder), findsNothing);
        expect(find.text('Popular Artist 0'), findsOneWidget);
        expect(fetchCounts, equals(countsAfterInitialLoad));

        // Horizontal scroll offset in Continue Listening was preserved via PageStorageKey.
        final restoredScrollable = tester.state<ScrollableState>(
          find.descendant(
            of: horizontalListFinder,
            matching: find.byType(Scrollable),
          ),
        );
        expect(
          restoredScrollable.position.pixels,
          closeTo(savedHorizontalOffset, 1.0),
        );

        // Toggling an unrelated setting (showVideo) must not refetch or flash shimmers.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        await container.read(settingsProvider.notifier).toggleVideo();
        await tester.pump();

        expect(find.byType(SectionShimmer), findsNothing);
        expect(fetchCounts, equals(countsAfterInitialLoad));
      },
    );

    testWidgets(
      '10 repeated vertical scroll cycles, horizontal sweeps, rapid window resizes, and Home->Discover->Library->Home navigation preserve state and trigger zero refetches',
      (tester) async {
        // True 1280x800 logical Retina MacBook viewport (2560x1600 physical @ 2.0x DPR).
        tester.view.physicalSize = const Size(2560, 1600);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fetchCounts = <String, int>{};
        int bump(String key) => fetchCounts[key] = (fetchCounts[key] ?? 0) + 1;

        const sharedArtwork = 'https://example.com/shared_cover.jpg';
        final tracks = List.generate(
          25,
          (i) => Track(
            spotifyId: 't_$i',
            name: 'Popular Song $i',
            artistId: 'a_$i',
            artistName: 'Artist $i',
            albumId: 'al_$i',
            albumName: 'Album $i',
            // Include missing artwork on last item to verify fallback icon rendering.
            albumImage: i == 24 ? '' : sharedArtwork,
            durationMs: 180000,
          ),
        );
        final albums = List.generate(
          6,
          (i) => <String, dynamic>{
            'id': 'al_$i',
            'name': 'Album $i',
            'images': [
              {'url': sharedArtwork, 'width': 640, 'height': 640},
              {
                'url': 'https://example.com/cover_300_$i.jpg',
                'width': 300,
                'height': 300,
              },
            ],
            'artists': [
              {'id': 'a_$i', 'name': 'Artist $i'},
            ],
          },
        );
        final playlists = List.generate(
          6,
          (i) => <String, dynamic>{
            'id': 'pl_$i',
            'name': 'Playlist $i',
            'images': [
              {'url': sharedArtwork},
            ],
          },
        );

        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, _) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
            GoRoute(
              path: '/discover',
              pageBuilder: (_, _) => const NoTransitionPage(
                child: Scaffold(body: Center(child: Text('Discover Page'))),
              ),
            ),
            GoRoute(
              path: '/library',
              pageBuilder: (_, _) => const NoTransitionPage(
                child: Scaffold(body: Center(child: Text('Library Page'))),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(_TestSettingsNotifier.new),
              recentlyPlayedProvider.overrideWith((ref) async {
                bump('recent');
                return tracks.take(10).toList();
              }),
              popularArtistsProvider.overrideWith((ref) {
                bump('artists');
                return Stream.value(const <Map<String, dynamic>>[]);
              }),
              madeForYouMixesProvider.overrideWith((ref) {
                bump('mixes');
                return Stream.value(const <Map<String, dynamic>>[]);
              }),
              suggestedStationsProvider.overrideWith((ref) {
                bump('stations');
                return Stream.value(const <Map<String, dynamic>>[]);
              }),
              marketPopularAlbumsProvider.overrideWith((ref) {
                bump('albums');
                return Stream.value(albums);
              }),
              browseCategoriesProvider.overrideWith((ref) {
                bump('genres');
                return Stream.value(const <Map<String, dynamic>>[]);
              }),
              newReleasesProvider.overrideWith((ref) {
                bump('releases');
                return Stream.value(albums);
              }),
              featuredPlaylistsProvider.overrideWith((ref) {
                bump('playlists');
                return Stream.value(playlists);
              }),
              popularTracksProvider.overrideWith((ref) {
                bump('tracks');
                return Stream.value(tracks);
              }),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );

        // Initial warmup: let staggers complete and visit the bottom once.
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();
        final mainScrollFinder = find.byKey(
          const PageStorageKey<String>('home_scroll_view'),
        );
        ScrollableState getMainScroll() => tester.state<ScrollableState>(
          find
              .descendant(
                of: mainScrollFinder,
                matching: find.byType(Scrollable),
              )
              .first,
        );

        // Step to the true bottom as lazy SliverList sections materialize.
        for (int step = 0; step < 3; step++) {
          getMainScroll().position.jumpTo(
            getMainScroll().position.maxScrollExtent,
          );
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }

        // Duplicate artwork shared between Continue Listening, Popular Albums,
        // and Popular Tracks must use the exact same decode width bucket (320 @ 2x).
        final cachedImages = tester
            .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .where((img) => img.imageUrl == sharedArtwork)
            .toList();
        expect(cachedImages, isNotEmpty);
        for (final img in cachedImages) {
          expect(img.memCacheWidth, 320);
        }

        // Sweep Popular Tracks horizontally to the end to confirm missing artwork
        // renders the music-note fallback icon rather than an empty card.
        final popularTracksList = find.byKey(
          const PageStorageKey<String>('home_list_popular_tracks'),
        );
        final popularTracksScroll = tester.state<ScrollableState>(
          find.descendant(
            of: popularTracksList,
            matching: find.byType(Scrollable),
          ),
        );
        popularTracksScroll.position.jumpTo(
          popularTracksScroll.position.maxScrollExtent,
        );
        await tester.pump();
        expect(find.text('Popular Song 24'), findsOneWidget);
        expect(find.byIcon(Icons.music_note_rounded), findsWidgets);

        // Snapshot provider counts after warmup.
        final baselineCounts = Map<String, int>.from(fetchCounts);

        // 10 repeated vertical scroll cycles with rapid direction changes.
        for (int i = 0; i < 10; i++) {
          final max = getMainScroll().position.maxScrollExtent;
          getMainScroll().position.jumpTo(0);
          await tester.pump();
          expect(find.byType(SectionShimmer), findsNothing);
          getMainScroll().position.jumpTo(max * 0.5);
          await tester.pump();
          getMainScroll().position.jumpTo(max);
          await tester.pump();
          expect(find.byType(SectionShimmer), findsNothing);
        }
        expect(fetchCounts, equals(baselineCounts));

        // Scroll to a mid-page offset, then navigate Home -> Discover -> Library -> Home.
        getMainScroll().position.jumpTo(320);
        await tester.pump();
        final savedY = getMainScroll().position.pixels;

        router.go('/discover');
        await tester.pumpAndSettle();
        expect(find.text('Discover Page'), findsOneWidget);

        router.go('/library');
        await tester.pumpAndSettle();
        expect(find.text('Library Page'), findsOneWidget);

        router.go('/home');
        await tester.pump();
        expect(find.byType(SectionShimmer), findsNothing);
        expect(getMainScroll().position.pixels, closeTo(savedY, 1.0));
        expect(fetchCounts, equals(baselineCounts));

        // Rapid window resizing across desktop/mobile breakpoints (logical 1280 -> 500 -> 900 -> 480 -> 1440 @ 2x).
        for (final size in const [
          Size(1000, 1400),
          Size(1800, 1400),
          Size(960, 1280),
          Size(2880, 1800),
        ]) {
          tester.view.physicalSize = size;
          await tester.pump();
          expect(find.byType(SectionShimmer), findsNothing);
        }
        expect(fetchCounts, equals(baselineCounts));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('extractHomeCollageImages', () {
    test(
      'returns null for albums with Spotify multi-resolution cover variants',
      () {
        final albumImages = [
          {
            'url': 'https://i.scdn.co/image/cover_640',
            'width': 640,
            'height': 640,
          },
          {
            'url': 'https://i.scdn.co/image/cover_300',
            'width': 300,
            'height': 300,
          },
          {
            'url': 'https://i.scdn.co/image/cover_64',
            'width': 64,
            'height': 64,
          },
        ];
        expect(
          extractHomeCollageImages(albumImages, isPlaylist: false),
          isNull,
        );
      },
    );

    test(
      'returns null for playlists with multi-resolution variants of one cover',
      () {
        final mosaicVariants = [
          {
            'url': 'https://mosaic.scdn.co/640/abc',
            'width': 640,
            'height': 640,
          },
          {
            'url': 'https://mosaic.scdn.co/300/abc',
            'width': 300,
            'height': 300,
          },
          {'url': 'https://mosaic.scdn.co/60/abc', 'width': 60, 'height': 60},
        ];
        expect(
          extractHomeCollageImages(mosaicVariants, isPlaylist: true),
          isNull,
        );
      },
    );

    test(
      'returns deduplicated track covers for enriched playlist collages',
      () {
        final collage = [
          {'url': 'https://i.scdn.co/image/track1'},
          {'url': 'https://i.scdn.co/image/track2'},
          {'url': 'https://i.scdn.co/image/track2'},
          {'url': 'https://i.scdn.co/image/track3'},
        ];
        expect(
          extractHomeCollageImages(collage, isPlaylist: true),
          equals([
            'https://i.scdn.co/image/track1',
            'https://i.scdn.co/image/track2',
            'https://i.scdn.co/image/track3',
          ]),
        );
      },
    );
  });
}
