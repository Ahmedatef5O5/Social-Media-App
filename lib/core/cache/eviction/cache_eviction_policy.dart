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

  // static const int maxTotalCacheSizeBytes = 300 * 1024 * 1024; // 300 MB

  static Duration ttlFor(String featureFolder) =>
      _ttlByFolder[featureFolder] ?? _defaultTtl;

  static bool isExpired(String featureFolder, DateTime cachedAt) =>
      DateTime.now().difference(cachedAt) > ttlFor(featureFolder);
}
