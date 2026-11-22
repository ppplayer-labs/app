import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/cache/image_cache_manager.dart';

class PPImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageRepeat repeat;
  final Color? color;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final IconData? fallbackIcon;
  final double maxCacheLogicalExtent;

  const PPImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.repeat = ImageRepeat.noRepeat,
    this.color,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fallbackIcon,
    this.maxCacheLogicalExtent = 320,
  });

  static const List<int> _cacheWidthBuckets = <int>[
    64,
    128,
    192,
    256,
    320,
    512,
    768,
    1024,
  ];

  /// Quantizes a target physical pixel width into a small deterministic set of
  /// decode buckets so identically-URL'd artwork shown across slightly different
  /// card dimensions (e.g. 150px, 156px, 160px) shares a single [ResizeImage]
  /// entry in Flutter's [ImageCache] instead of decoding and caching duplicates.
  static int resolveCacheWidthForExtent(
    double logicalExtent,
    double devicePixelRatio,
  ) {
    final safeExtent = logicalExtent.isFinite && logicalExtent > 0
        ? logicalExtent
        : 320.0;
    final safeDpr = devicePixelRatio.isFinite && devicePixelRatio > 0
        ? devicePixelRatio
        : 1.0;
    final raw = (safeExtent * safeDpr).round().clamp(32, 1024);
    for (final bucket in _cacheWidthBuckets) {
      if (raw <= bucket) return bucket;
    }
    return _cacheWidthBuckets.last;
  }

  int _resolveCacheWidth(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final finiteW = (width != null && width!.isFinite && width! > 0)
        ? width!
        : null;
    final finiteH = (height != null && height!.isFinite && height! > 0)
        ? height!
        : null;
    // Pass only a single decode dimension to preserve source aspect ratio while
    // capping GPU/RGBA texture size (e.g. 160px card @ 1.25x -> 256px bucket
    // instead of decoding the full 640px source).
    final double logicalTarget;
    if (finiteW != null && finiteH != null) {
      logicalTarget = finiteW >= finiteH ? finiteW : finiteH;
    } else if (finiteW != null) {
      logicalTarget = finiteW;
    } else if (finiteH != null) {
      logicalTarget = finiteH;
    } else {
      logicalTarget = maxCacheLogicalExtent;
    }
    return resolveCacheWidthForExtent(logicalTarget, dpr);
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      final fallback = errorWidget ?? _buildErrorWidget(context);
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    final int decodeWidth = _resolveCacheWidth(context);

    Widget image;
    if (imageUrl!.startsWith('asset:')) {
      final assetPath = imageUrl!.substring(6); // Remove 'asset:'
      image = Image.asset(
        assetPath,
        width: width,
        height: height,
        cacheWidth: decodeWidth,
        fit: fit,
        repeat: repeat,
        color: color,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _buildErrorWidget(context),
      );
    } else if (imageUrl!.startsWith('/') || imageUrl!.startsWith('file://')) {
      final path = imageUrl!.startsWith('file://')
          ? Uri.parse(imageUrl!).toFilePath()
          : imageUrl!;
      image = Image.file(
        File(path),
        width: width,
        height: height,
        cacheWidth: decodeWidth,
        fit: fit,
        repeat: repeat,
        color: color,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _buildErrorWidget(context),
      );
    } else if (_isHttp(imageUrl!)) {
      image = CachedNetworkImage(
        cacheManager: PPImageCacheManager.instance,
        imageUrl: imageUrl!,
        width: width,
        height: height,
        memCacheWidth: decodeWidth,
        fit: fit,
        repeat: repeat,
        color: color,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (context, url) =>
            placeholder ?? _buildPlaceholder(context),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildErrorWidget(context),
      );
    } else {
      image = errorWidget ?? _buildErrorWidget(context);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      child: Icon(
        fallbackIcon ?? Icons.music_note_rounded,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
      ),
    );
  }

  static ImageProvider getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage('assets/logo.png');
    }

    if (imageUrl.startsWith('asset:')) {
      return AssetImage(imageUrl.substring(6));
    } else if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final path = imageUrl.startsWith('file://')
          ? Uri.parse(imageUrl).toFilePath()
          : imageUrl;
      return FileImage(File(path));
    } else if (_isHttp(imageUrl)) {
      return CachedNetworkImageProvider(
        imageUrl,
        cacheManager: PPImageCacheManager.instance,
      );
    }
    return const AssetImage('assets/logo.png');
  }

  static bool _isHttp(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        {'http', 'https'}.contains(uri.scheme) &&
        uri.host.isNotEmpty;
  }
}
