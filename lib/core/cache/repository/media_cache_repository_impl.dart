import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/network_status_service.dart';
import '../datasources/media_local_data_source.dart';
import '../eviction/cache_eviction_service.dart';
import '../exceptions/media_cache_exception.dart';
import 'media_cache_repository.dart';

class MediaCacheRepositoryImpl implements MediaCacheRepository {
  final MediaLocalDataSource _localDataSource;
  final CacheEvictionService _evictionService;
  final NetworkStatusService _networkStatusService;

  MediaCacheRepositoryImpl({
    required MediaLocalDataSource localDataSource,
    required CacheEvictionService evictionService,
    NetworkStatusService? networkStatusService,
  }) : _localDataSource = localDataSource,
       _evictionService = evictionService,
       _networkStatusService =
           networkStatusService ?? NetworkStatusService.instance;

  @override
  void initialize() {
    _evictionService.startPeriodicSweep();
  }

  @override
  bool isAvailableOffline(String secureUrl) {
    final path = _localDataSource.getCachedEntry(secureUrl)?.localFilePath;
    if (path == null) return false;
    return File(path).existsSync();
  }

  @override
  String? resolveLocalPathSync(String secureUrl) {
    final path = _localDataSource.getCachedEntry(secureUrl)?.localFilePath;
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }

  @override
  Future<String?> resolveLocalPath(
    String secureUrl, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final cachedPath = await _localDataSource.getCachedFilePath(secureUrl);
    if (cachedPath != null) return cachedPath;

    final isOnline = await _networkStatusService.isConnected();
    if (!isOnline) {
      debugPrint('[MediaCacheRepository] Offline and not cached: $secureUrl');
      return null;
    }

    try {
      final entry = await _localDataSource.cacheMedia(
        secureUrl,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return entry.localFilePath;
    } on MediaCacheDownloadException catch (e) {
      debugPrint('[MediaCacheRepository] $e');
      return null;
    }
  }

  @override
  Future<int> runEvictionSweep() => _evictionService.runSweep();

  @override
  Future<void> adoptUploadedFile(String secureUrl, File localFile) async {
    try {
      await _localDataSource.adoptLocalFile(secureUrl, localFile);
    } catch (e) {
      debugPrint(
        '[MediaCacheRepository] adoptUploadedFile failed for $secureUrl: $e',
      );
    }
  }

  @override
  Future<void> invalidate(String secureUrl) =>
      _localDataSource.removeCachedMedia(secureUrl);
}
