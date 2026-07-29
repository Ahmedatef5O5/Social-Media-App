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

  Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(HiveBoxNames.dataSnapshots);
    _isInitialized = true;
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    if (!_isInitialized) return;
    try {
      await _box.put(key, jsonEncode(items));
    } catch (error, stackTrace) {
      debugPrint('[LocalSnapshotStore] Failed to save "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<Map<String, dynamic>> readList(String key) {
    if (!_isInitialized) return [];
    final raw = _box.get(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
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
    } catch (error, stackTrace) {
      debugPrint('[LocalSnapshotStore] Failed to save "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Map<String, dynamic>? readObject(String key) {
    if (!_isInitialized) return null;

    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
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
    await _box.delete(key);
  }

  Future<void> clearAll() async {
    if (!_isInitialized) return;
    try {
      await _box.clear();
    } catch (error, stackTrace) {
      debugPrint('[LocalSnapshotStore] Failed to clear all snapshots: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
