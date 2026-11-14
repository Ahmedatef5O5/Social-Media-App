import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/core/cache/constants/hive_box_names.dart';
import 'package:social_media_app/core/infrastructure/service_health_coordinator.dart';
import 'package:social_media_app/core/infrastructure/service_health_sample.dart';
import '../constants/hive_type_ids.dart';
import '../models/cached_media_model.dart';

class HiveCacheManager {
  HiveCacheManager._();

  static final HiveCacheManager instance = HiveCacheManager._();

  static const String cacheSubDirectory = 'social_media_cache';
  bool _isInitialized = false;
  Future<void>? _initFuture;

  late final Box<CachedMediaModel> mediaCacheBox;
  late final Box<dynamic> cacheMetaBox;
  late final Box<String> storyReactionsBox;

  Future<void> init() {
    if (_isInitialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    final healthTimer = Stopwatch()..start();
    try {
      final cacheDirectory = await getApplicationDocumentsDirectory();
      Hive.init('${cacheDirectory.path}/$cacheSubDirectory');

      _registerAdapters();

      mediaCacheBox = await _openBoxSafely<CachedMediaModel>(
        HiveBoxNames.mediaCache,
      );

      cacheMetaBox = await _openBoxSafely<dynamic>(HiveBoxNames.cacheMeta);

      storyReactionsBox = await _openBoxSafely<String>(
        HiveBoxNames.storyReactions,
      );

      _isInitialized = true;

      // Service-health telemetry: init time + a cheap liveness check so a
      // quiet-but-healthy cache still produces samples every minute.
      ServiceHealthCoordinator.instance
        ..reportHiveInit(success: true, duration: healthTimer.elapsed)
        ..registerLivenessCheck(HealthServiceKey.hiveCache, _livenessCheck);

      debugPrint(
        '[HiveCacheManager] Initialized — '
        '${mediaCacheBox.length} cached media entries, '
        '${storyReactionsBox.length} cached story reactions.',
      );
    } catch (e) {
      _initFuture = null;
      ServiceHealthCoordinator.instance.reportHiveInit(
        success: false,
        duration: healthTimer.elapsed,
        error: e,
      );
      rethrow;
    }
  }

  /// `null` = not initialised yet (no statement); `false` = a box was closed
  /// behind our back.
  bool? _livenessCheck() {
    if (!_isInitialized) return null;
    return mediaCacheBox.isOpen &&
        cacheMetaBox.isOpen &&
        storyReactionsBox.isOpen;
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTypeIds.cachedMediaModel)) {
      Hive.registerAdapter(CachedMediaModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.cachedMediaType)) {
      Hive.registerAdapter(CachedMediaTypeAdapter());
    }
  }

  Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (error, stackTrace) {
      debugPrint(
        '[HiveCacheManager] Box "$boxName" failed to open, resetting it. '
        'Error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      await Hive.deleteBoxFromDisk(boxName);
      // Corruption recovery happened: the cache works again but is degraded.
      ServiceHealthCoordinator.instance.reportHiveBoxReset(boxName);
      return await Hive.openBox<T>(boxName);
    }
  }

  /// Clears cached data that belongs to the signed-in ACCOUNT (as opposed to
  /// shared content). Called on every session end (logout, expired session,
  /// account deletion) so the next account on this device never inherits it.

  Future<void> clearUserScopedData() async {
    if (!_isInitialized) return;
    try {
      await storyReactionsBox.clear();
    } catch (error) {
      debugPrint('[HiveCacheManager] clearUserScopedData failed: $error');
    }
  }

  Future<void> closeAll() async {
    ServiceHealthCoordinator.instance.unregisterLivenessCheck(
      HealthServiceKey.hiveCache,
    );
    await Hive.close();
    _isInitialized = false;
    _initFuture = null;
  }
}
