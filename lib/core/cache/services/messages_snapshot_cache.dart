import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_snapshot_store.dart';

class MessagesSnapshotCache<T> {
  final Map<String, dynamic> Function(T message) toCacheJson;
  final T Function(Map<String, dynamic> json) fromJson;
  final int maxCached;

  const MessagesSnapshotCache({
    required this.toCacheJson,
    required this.fromJson,
    this.maxCached = 60,
  });

  void persist(String key, List<T> messages) {
    unawaited(
      LocalSnapshotStore.instance.saveList(
        key,
        messages.take(maxCached).map(toCacheJson).toList(),
      ),
    );
  }

  List<T> read(String key) {
    try {
      return LocalSnapshotStore.instance.readList(key).map(fromJson).toList();
    } catch (e) {
      debugPrint('Failed to read messages snapshot from disk: $e');
      return [];
    }
  }
}
