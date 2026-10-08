class CacheEvictionPolicy {
  const CacheEvictionPolicy._();

  static const Map<String, Duration> _ttlByFolder = {
    'stories': Duration(hours: 24),
    'chats': Duration(days: 3),
    'group_chats': Duration(days: 3),
    'posts': Duration(days: 7),
    'avatars': Duration(days: 30),
  };

  static const Duration _defaultTtl = Duration(days: 1);

  /// Hard cap for the on-disk media cache. When a sweep finds more than this,
  /// least-recently-used entries are evicted down to [evictionTargetBytes].
  static const int maxTotalCacheSizeBytes = 300 * 1024 * 1024; // 300 MB

  /// Evict down to 80% of the cap so the next download does not immediately
  /// trigger another sweep (hysteresis).
  static const int evictionTargetBytes = maxTotalCacheSizeBytes * 8 ~/ 10;

  /// Entries younger than this are never size-evicted: they were just
  /// downloaded or adopted after an upload and are very likely on screen.
  static const Duration minAgeForSizeEviction = Duration(minutes: 10);

  static Duration ttlFor(String featureFolder) =>
      _ttlByFolder[featureFolder] ?? _defaultTtl;

  static bool isExpired(String featureFolder, DateTime cachedAt) =>
      DateTime.now().difference(cachedAt) > ttlFor(featureFolder);
}
