import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/core/cache/constants/hive_box_names.dart';
import '../constants/hive_type_ids.dart';
import '../models/cached_media_model.dart';

class HiveCacheManager {
  HiveCacheManager._();

  static final HiveCacheManager instance = HiveCacheManager._();

  static const String cacheSubDirectory = 'social_media_cache';
  bool _isInitialized = false;

  late final Box<CachedMediaModel> mediaCacheBox;
  late final Box<dynamic> cacheMetaBox;
  late final Box<String> storyReactionsBox;

  Future<void> init() async {
    if (_isInitialized) return;

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

    debugPrint(
      '[HiveCacheManager] Initialized — '
      '${mediaCacheBox.length} cached media entries, '
      '${storyReactionsBox.length} cached story reactions.',
    );
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
      return await Hive.openBox<T>(boxName);
    }
  }

  Future<void> closeAll() async {
    await Hive.close();
    _isInitialized = false;
  }
}
