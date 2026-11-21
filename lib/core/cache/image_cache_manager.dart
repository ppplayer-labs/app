import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PPImageCacheManager {
  static const key = 'ppPlayerImageCache';

  static final CacheManager _defaultInstance = CacheManager(
    Config(key, stalePeriod: const Duration(days: 7), maxNrOfCacheObjects: 500),
  );

  @visibleForTesting
  static CacheManager? debugTestOverride;

  static CacheManager get instance => debugTestOverride ?? _defaultInstance;
}
