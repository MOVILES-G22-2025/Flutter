import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static final BaseCacheManager instance = CacheManager(
    Config(
      'customProductCache',
      //Tiempo antes de considerar un archivo como obsoleto
      stalePeriod: const Duration(days: 30),
      //Número máximo de objetos en caché
      maxNrOfCacheObjects: 100,
    ),
  );
}
