import '../../../core/cache/constants/snapshot_keys.dart';
import '../../../core/cache/services/local_snapshot_store.dart';

class ChatClearStore {
  ChatClearStore._();
  static final ChatClearStore instance = ChatClearStore._();

  final Map<String, DateTime> _clearedAt = {};
  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    final raw = LocalSnapshotStore.instance.readObject(
      SnapshotKeys.clearedSingleChats,
    );
    if (raw == null) return;
    raw.forEach((otherUserId, iso) {
      final parsed = DateTime.tryParse(iso as String);
      if (parsed != null) _clearedAt[otherUserId] = parsed;
    });
  }

  DateTime? clearedAtFor(String otherUserId) {
    _ensureLoaded();
    return _clearedAt[otherUserId];
  }

  Future<void> setClearedNow(Iterable<String> otherUserIds) async {
    _ensureLoaded();
    final now = DateTime.now().toUtc();
    for (final id in otherUserIds) {
      _clearedAt[id] = now;
    }
    await _persist();
  }

  Future<void> clear(String otherUserId) async {
    _ensureLoaded();
    if (_clearedAt.remove(otherUserId) != null) {
      await _persist();
    }
  }

  Future<void> _persist() {
    return LocalSnapshotStore.instance.saveObject(
      SnapshotKeys.clearedSingleChats,
      _clearedAt.map((k, v) => MapEntry(k, v.toIso8601String())),
    );
  }
}
