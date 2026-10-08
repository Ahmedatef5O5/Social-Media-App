import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/cache_meta_keys.dart';
import '../datasources/media_local_data_source.dart';
import '../entities/media_cache_entry.dart';
import 'cache_eviction_policy.dart';

class CacheEvictionService {
  CacheEvictionService({
    required MediaLocalDataSource localDataSource,
    required Box<dynamic> metaBox,
    Duration periodicInterval = const Duration(hours: 6),
  }) : _localDataSource = localDataSource,
       _metaBox = metaBox,
       _periodicInterval = periodicInterval;

  final MediaLocalDataSource _localDataSource;
  final Box<dynamic> _metaBox;
  final Duration _periodicInterval;

  static const String _lastRunKey = 'last_eviction_run_at';
  static const String _lastRemovedKey = 'last_eviction_removed_count';

  Timer? _timer;
  bool _isSweeping = false;

  Future<int> runSweep() async {
    if (_isSweeping) return 0;
    _isSweeping = true;

    try {
      final entries = _localDataSource.getAllCachedEntries();
      var expiredCount = 0;
      var sizeEvictedCount = 0;
      var remainingBytes = 0;
      final survivors = <MediaCacheEntry>[];

      // Pass 1: TTL.
      for (final entry in entries) {
        final expired = CacheEvictionPolicy.isExpired(
          entry.featureFolder,
          entry.cachedAt,
        );
        if (expired) {
          await _localDataSource.removeCachedMedia(entry.secureUrl);
          expiredCount++;
        } else {
          survivors.add(entry);
          remainingBytes += entry.sizeInBytes ?? 0;
        }
      }

      // Pass 2: size cap, least-recently-used first. The total is summed from
      // the entries themselves, not from the running counter, which can drift.
      if (remainingBytes > CacheEvictionPolicy.maxTotalCacheSizeBytes) {
        final now = DateTime.now();
        final candidates =
            survivors
                .where(
                  (e) =>
                      now.difference(e.cachedAt) >=
                      CacheEvictionPolicy.minAgeForSizeEviction,
                )
                .toList()
              ..sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

        for (final entry in candidates) {
          if (remainingBytes <= CacheEvictionPolicy.evictionTargetBytes) break;
          await _localDataSource.removeCachedMedia(entry.secureUrl);
          remainingBytes -= entry.sizeInBytes ?? 0;
          sizeEvictedCount++;
        }
      }

      final removedCount = expiredCount + sizeEvictedCount;
      await _metaBox.put(_lastRunKey, DateTime.now().toIso8601String());
      await _metaBox.put(_lastRemovedKey, removedCount);
      // Re-anchor the running counter to the exact figure just computed.
      await _metaBox.put(CacheMetaKeys.totalCacheSizeBytes, remainingBytes);

      if (removedCount > 0) {
        debugPrint(
          '[CacheEvictionService] Swept $expiredCount expired and '
          '$sizeEvictedCount over-cap entries '
          '(${(remainingBytes / (1024 * 1024)).toStringAsFixed(1)} MB left).',
        );
      }
      return removedCount;
    } finally {
      _isSweeping = false;
    }
  }

  void startPeriodicSweep() {
    unawaited(runSweep());
    _timer?.cancel();
    _timer = Timer.periodic(_periodicInterval, (_) => runSweep());
  }

  void stopPeriodicSweep() {
    _timer?.cancel();
    _timer = null;
  }

  DateTime? get lastRunAt {
    final raw = _metaBox.get(_lastRunKey) as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
