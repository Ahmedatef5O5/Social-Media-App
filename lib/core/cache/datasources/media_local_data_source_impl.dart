import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/cache_meta_keys.dart';
import '../entities/media_cache_entry.dart';
import '../exceptions/media_cache_exception.dart';
import '../models/cached_media_model.dart';
import '../utils/cloudinary_url_extensions.dart';
import 'media_local_data_source.dart';

class MediaLocalDataSourceImpl implements MediaLocalDataSource {
  MediaLocalDataSourceImpl({
    required Box<CachedMediaModel> box,
    required Box<dynamic> metaBox,
    Dio? dio,
  }) : _box = box,
       _metaBox = metaBox,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(minutes: 3),
             ),
           );

  final Box<CachedMediaModel> _box;
  final Box<dynamic> _metaBox;
  final Dio _dio;

  static const String _cacheDirName = 'media';

  static const Duration _accessTimestampThrottle = Duration(minutes: 30);

  final Map<String, Future<CachedMediaModel>> _inFlightDownloads = {};

  final Map<String, List<void Function(double progress)>> _progressListeners =
      {};

  @override
  MediaCacheEntry? getCachedEntry(String secureUrl) =>
      _box.get(secureUrl)?.toEntity();

  @override
  Future<String?> getCachedFilePath(String secureUrl) async {
    final entry = _box.get(secureUrl);
    if (entry == null || entry.localFilePath == null) return null;

    final file = File(entry.localFilePath!);
    if (!await file.exists()) {
      await _box.delete(secureUrl);
      return null;
    }

    final now = DateTime.now();
    if (now.difference(entry.lastAccessedAt) >= _accessTimestampThrottle) {
      entry.lastAccessedAt = now;
      await entry.save();
    }
    return entry.localFilePath;
  }

  @override
  Future<MediaCacheEntry> cacheMedia(
    String secureUrl, {
    void Function(double progress)? onProgress,
  }) async {
    final validPath = await getCachedFilePath(secureUrl);
    if (validPath != null) {
      // Already cached and verified on disk — skip the network entirely.
      return _box.get(secureUrl)!.toEntity();
    }

    final inFlight = _inFlightDownloads[secureUrl];
    if (inFlight != null) {
      _registerProgressListener(secureUrl, onProgress);
      return (await inFlight).toEntity();
    }

    _registerProgressListener(secureUrl, onProgress);

    final downloadFuture = _downloadAndCache(secureUrl);
    _inFlightDownloads[secureUrl] = downloadFuture;

    try {
      final model = await downloadFuture;
      return model.toEntity();
    } finally {
      _inFlightDownloads.remove(secureUrl);
      _progressListeners.remove(secureUrl);
    }
  }

  Future<CachedMediaModel> _downloadAndCache(String secureUrl) async {
    final directory = await _resolveDirectoryFor(secureUrl);
    final filePath = '${directory.path}/${_localFileName(secureUrl)}';

    try {
      final response = await _dio.download(
        secureUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _notifyProgressListeners(
              secureUrl,
              (received / total).clamp(0.0, 1.0),
            );
          }
        },
      );

      if (response.statusCode == null || response.statusCode! >= 400) {
        throw Exception('unexpected_status_code: ${response.statusCode}');
      }

      final sizeInBytes = await File(filePath).length();
      final now = DateTime.now();

      final entry = CachedMediaModel(
        secureUrl: secureUrl,
        mediaType: secureUrl.cachedMediaType,
        featureFolder: secureUrl.cloudinaryFeatureFolder,
        localFilePath: filePath,
        cachedAt: now,
        lastAccessedAt: now,
        sizeInBytes: sizeInBytes,
      );

      await _box.put(secureUrl, entry);
      await _adjustTotalSize(sizeInBytes);
      return entry;
    } catch (error, stackTrace) {
      debugPrint(
        '[MediaLocalDataSource] cacheMedia failed for $secureUrl: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      final partialFile = File(filePath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      throw MediaCacheDownloadException(secureUrl, error);
    }
  }

  void _registerProgressListener(
    String secureUrl,
    void Function(double progress)? onProgress,
  ) {
    if (onProgress == null) return;
    _progressListeners.putIfAbsent(secureUrl, () => []).add(onProgress);
  }

  void _notifyProgressListeners(String secureUrl, double progress) {
    final listeners = _progressListeners[secureUrl];
    if (listeners == null || listeners.isEmpty) return;
    // Iterate over a copy — a listener could trigger a rebuild/dispose that
    // mutates the list mid-callback.
    for (final listener in List<void Function(double)>.of(listeners)) {
      listener(progress);
    }
  }

  @override
  Future<void> removeCachedMedia(String secureUrl) async {
    final entry = _box.get(secureUrl);
    if (entry?.localFilePath != null) {
      final file = File(entry!.localFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (entry != null) {
      await _adjustTotalSize(-(entry.sizeInBytes ?? 0));
    }
    await _box.delete(secureUrl);
  }

  @override
  List<MediaCacheEntry> getAllCachedEntries() =>
      _box.values.map((model) => model.toEntity()).toList();

  @override
  Future<void> clearAll() async {
    for (final entry in _box.values) {
      if (entry.localFilePath != null) {
        final file = File(entry.localFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _box.clear();
    await _metaBox.put(CacheMetaKeys.totalCacheSizeBytes, 0);
  }

  @override
  int getTotalCacheSizeBytes() =>
      (_metaBox.get(CacheMetaKeys.totalCacheSizeBytes) as int?) ?? 0;

  @override
  Future<void> recalculateTotalCacheSize() async {
    final total = _box.values.fold<int>(
      0,
      (sum, entry) => sum + (entry.sizeInBytes ?? 0),
    );
    await _metaBox.put(CacheMetaKeys.totalCacheSizeBytes, total);
  }

  Future<void> _adjustTotalSize(int deltaBytes) async {
    if (deltaBytes == 0) return;
    final updated = (getTotalCacheSizeBytes() + deltaBytes).clamp(0, 1 << 62);
    await _metaBox.put(CacheMetaKeys.totalCacheSizeBytes, updated);
  }

  Future<Directory> _resolveDirectoryFor(String secureUrl) async {
    final cacheDir = await getApplicationCacheDirectory();
    final folder = secureUrl.cloudinaryFeatureFolder;
    final targetDir = Directory('${cacheDir.path}/$_cacheDirName/$folder');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  String _localFileName(String secureUrl) {
    final hash = md5.convert(utf8.encode(secureUrl)).toString();
    final ext = secureUrl.fileExtension;
    return ext.isEmpty ? hash : '$hash.$ext';
  }
}
