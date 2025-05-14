import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Custom cache manager for handling product images
class CustomCacheManager {
  // Singleton instance of the cache manager
  static final BaseCacheManager instance = CacheManager(
    Config(
      'customProductCache',
      // Time before considering a file as stale
      stalePeriod: const Duration(days: 30),
      // Maximum number of objects to store in cache
      maxNrOfCacheObjects: 100,
    ),
  );
}
