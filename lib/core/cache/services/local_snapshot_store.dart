import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/hive_box_names.dart';

class LocalSnapshotStore {
  LocalSnapshotStore._();

  static final LocalSnapshotStore instance = LocalSnapshotStore._();

  late Box<String> _box;
  bool _isInitialized = false;

  final Map<String, Object?> _decodedCache = {};
  static const int _largePayloadWarningBytes = 200 * 1024;

  Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(HiveBoxNames.dataSnapshots);
    _isInitialized = true;
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    if (!_isInitialized) return;
    try {
      await _box.put(key, jsonEncode(items));
      _decodedCache[key] = items;
    } catch (error, stackTrace) {
      debugPrint('[LocalSnapshotStore] Failed to save "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<Map<String, dynamic>> readList(String key) {
    if (!_isInitialized) return [];

    final cached = _decodedCache[key];
    if (cached is List<Map<String, dynamic>>) {
      return cached;
    }

    final raw = _box.get(key);
    if (raw == null) return [];
    _warnIfLarge(key, raw);
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final result = decoded.cast<Map<String, dynamic>>();
      _decodedCache[key] = result;
      return result;
    } catch (error) {
      debugPrint(
        '[LocalSnapshotStore] Failed to decode "$key", dropping it: $error',
      );
      unawaited(_box.delete(key));
      return [];
    }
  }

  Future<void> saveObject(String key, Map<String, dynamic> item) async {
    if (!_isInitialized) return;
    try {
      await _box.put(key, jsonEncode(item));
      _decodedCache[key] = item;
    } catch (error, stackTrace) {
      debugPrint('[LocalSnapshotStore] Failed to save "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Map<String, dynamic>? readObject(String key) {
    if (!_isInitialized) return null;

    final cached = _decodedCache[key];
    if (cached is Map<String, dynamic>) {
      return cached;
    }

    final raw = _box.get(key);
    if (raw == null) return null;
    _warnIfLarge(key, raw);
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _decodedCache[key] = decoded;
      return decoded;
    } catch (error) {
      debugPrint(
        '[LocalSnapshotStore] Failed to decode object "$key", dropping it: $error',
      );
      unawaited(_box.delete(key));
      return null;
    }
  }

  Future<void> clear(String key) async {
    if (!_isInitialized) return;
    _decodedCache.remove(key);
    await _box.delete(key);
  }

  Future<void> clearAll() async {
    if (!_isInitialized) return;
    try {
      _decodedCache.clear();
      await _box.clear();
    } catch (error, stackTrace) {
      debugPrint('[LocalSnapshotStore] Failed to clear all snapshots: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _warnIfLarge(String key, String raw) {
    if (raw.length > _largePayloadWarningBytes) {
      debugPrint(
        '[LocalSnapshotStore] ⚠️ "$key" is ${(raw.length / 1024).toStringAsFixed(1)}KB '
        'before decoding — consider capping or paginating this snapshot.',
      );
    }
  }
}
