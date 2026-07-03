import '../models/cached_media_model.dart';

class MediaCacheEntry {
  const MediaCacheEntry({
    required this.secureUrl,
    required this.mediaType,
    required this.featureFolder,
    required this.cachedAt,
    required this.lastAccessedAt,
    this.localFilePath,
    this.sizeInBytes,
  });

  final String secureUrl;
  final CachedMediaType mediaType;
  final String featureFolder;
  final String? localFilePath;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;
  final int? sizeInBytes;
}

extension CachedMediaModelMapper on CachedMediaModel {
  MediaCacheEntry toEntity() => MediaCacheEntry(
    secureUrl: secureUrl,
    mediaType: mediaType,
    featureFolder: featureFolder,
    localFilePath: localFilePath,
    cachedAt: cachedAt,
    lastAccessedAt: lastAccessedAt,
    sizeInBytes: sizeInBytes,
  );
}
