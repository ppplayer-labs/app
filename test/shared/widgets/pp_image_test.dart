import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/main.dart' show configureDesktopImageCache;
import 'package:ppplayer/shared/widgets/playlist_cover.dart';
import 'package:ppplayer/shared/widgets/pp_image.dart';

void main() {
  test('file artwork preserves spaces and Unicode in URI', () {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}album art ç.png',
    );
    final provider = PPImage.getImageProvider(file.uri.toString()) as FileImage;
    expect(provider.file.path, file.path);
  });

  testWidgets('opaque locator never reaches the HTTP image cache', (
    tester,
  ) async {
    expect(PPImage.getImageProvider('Ym9va21hcms='), isA<AssetImage>());
    await tester.pumpWidget(
      const MaterialApp(home: PPImage(imageUrl: 'Ym9va21hcms=')),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'resolveCacheWidthForExtent buckets similar card extents identically',
    () {
      // 150px, 156px, and 160px cards must share the exact same decode bucket so
      // identical artwork across Home sections hits a single ImageCache entry.
      for (final dpr in [1.0, 1.5, 2.0, 3.0]) {
        final w150 = PPImage.resolveCacheWidthForExtent(150, dpr);
        final w156 = PPImage.resolveCacheWidthForExtent(156, dpr);
        final w160 = PPImage.resolveCacheWidthForExtent(160, dpr);
        expect(w156, equals(w160), reason: 'dpr=$dpr');
        expect(w150, equals(w160), reason: 'dpr=$dpr');
      }
      expect(PPImage.resolveCacheWidthForExtent(160, 2.0), equals(320));
      expect(PPImage.resolveCacheWidthForExtent(160, 1.25), equals(256));
      expect(PPImage.resolveCacheWidthForExtent(160, 1.0), equals(192));
      expect(PPImage.resolveCacheWidthForExtent(2000, 2.0), equals(1024));
    },
  );

  testWidgets(
    'HTTP PPImage disables slow fade-in/out animations that cause scroll flicker',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PPImage(
            imageUrl: 'https://example.com/cover.jpg',
            width: 156,
            height: 156,
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.fadeInDuration, Duration.zero);
      expect(cachedImage.fadeOutDuration, Duration.zero);
      expect(cachedImage.placeholderFadeInDuration, Duration.zero);
      expect(
        cachedImage.memCacheWidth,
        PPImage.resolveCacheWidthForExtent(156, tester.view.devicePixelRatio),
      );
    },
  );

  testWidgets('asset and file PPImage enable gaplessPlayback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            PPImage(imageUrl: 'asset:assets/logo.png', width: 48, height: 48),
            PPImage(imageUrl: '/nonexistent/local.jpg', width: 48, height: 48),
          ],
        ),
      ),
    );

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images.length, 2);
    for (final img in images) {
      expect(img.gaplessPlayback, isTrue);
    }
  });

  testWidgets(
    'PlaylistCover aligns decode extent buckets across fixed and infinite grid sizes',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              SizedBox(
                width: 156,
                height: 156,
                child: PlaylistCover(
                  images: [
                    'https://example.com/a.jpg',
                    'https://example.com/b.jpg',
                    'https://example.com/c.jpg',
                  ],
                  size: 156,
                ),
              ),
              SizedBox(
                width: 172,
                height: 172,
                child: PlaylistCover(
                  images: [
                    'https://example.com/a.jpg',
                    'https://example.com/b.jpg',
                    'https://example.com/c.jpg',
                  ],
                  size: double.infinity,
                ),
              ),
            ],
          ),
        ),
      );

      final cachedImages = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .toList();
      expect(cachedImages.length, 6);
      // Top tile and bottom tiles match decode width across horizontal vs grid layouts.
      expect(cachedImages[0].memCacheWidth, cachedImages[3].memCacheWidth);
      expect(cachedImages[1].memCacheWidth, cachedImages[4].memCacheWidth);
      expect(cachedImages[2].memCacheWidth, cachedImages[5].memCacheWidth);
    },
  );

  test('configureDesktopImageCache sets bounded HiDPI-safe limits', () {
    final cache = ImageCache();
    configureDesktopImageCache(cache);
    expect(cache.maximumSizeBytes, 80 * 1024 * 1024);
    expect(cache.maximumSize, 300);
  });

  testWidgets('PPImage updates memCacheWidth bucket cleanly when DPR changes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PPImage(
          imageUrl: 'https://example.com/dpr_test.jpg',
          width: 160,
          height: 160,
        ),
      ),
    );
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .memCacheWidth,
      192,
    );

    tester.view.devicePixelRatio = 1.5;
    await tester.pump();
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .memCacheWidth,
      256,
    );

    tester.view.devicePixelRatio = 2.0;
    await tester.pump();
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .memCacheWidth,
      320,
    );
  });
}
