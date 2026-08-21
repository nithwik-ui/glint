import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class GlintCacheManager {
  static const key = 'glintCustomCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Aggressive caching: cache for 30 days
      maxNrOfCacheObjects: 500, // Keep up to 500 images in disk cache
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
