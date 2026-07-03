import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../datasources/media_local_data_source.dart';
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
      var removedCount = 0;

      for (final entry in entries) {
        final expired = CacheEvictionPolicy.isExpired(
          entry.featureFolder,
          entry.cachedAt,
        );
        if (expired) {
          await _localDataSource.removeCachedMedia(entry.secureUrl);
          removedCount++;
        }
      }

      await _metaBox.put(_lastRunKey, DateTime.now().toIso8601String());
      await _metaBox.put(_lastRemovedKey, removedCount);

      if (removedCount > 0) {
        debugPrint(
          '[CacheEvictionService] Swept $removedCount expired '
          '${removedCount == 1 ? "entry" : "entries"}.',
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
