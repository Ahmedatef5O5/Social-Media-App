import 'dart:io';
import 'package:dio/dio.dart';
import '../entities/media_cache_entry.dart';

abstract class MediaLocalDataSource {
  MediaCacheEntry? getCachedEntry(String secureUrl);

  Future<String?> getCachedFilePath(String secureUrl);

  Future<MediaCacheEntry> cacheMedia(
    String secureUrl, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  });

  Future<MediaCacheEntry> adoptLocalFile(String secureUrl, File sourceFile);

  Future<void> removeCachedMedia(String secureUrl);

  List<MediaCacheEntry> getAllCachedEntries();

  Future<void> clearAll();

  int getTotalCacheSizeBytes();

  Future<void> recalculateTotalCacheSize();
}
