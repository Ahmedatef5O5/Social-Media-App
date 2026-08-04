import '../../../core/cache/constants/snapshot_keys.dart';
import '../../../core/cache/services/local_snapshot_store.dart';

class GroupChatClearStore {
  GroupChatClearStore._();
  static final GroupChatClearStore instance = GroupChatClearStore._();

  final Map<String, DateTime> _clearedAt = {};
  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    final raw = LocalSnapshotStore.instance.readObject(
      SnapshotKeys.clearedGroupChats,
    );
    if (raw == null) return;
    raw.forEach((groupId, iso) {
      final parsed = DateTime.tryParse(iso as String);
      if (parsed != null) _clearedAt[groupId] = parsed;
    });
  }

  DateTime? clearedAtFor(String groupId) {
    _ensureLoaded();
    return _clearedAt[groupId];
  }

  Future<void> setClearedNow(Iterable<String> groupIds) async {
    _ensureLoaded();
    final now = DateTime.now().toUtc();
    for (final id in groupIds) {
      _clearedAt[id] = now;
    }
    await _persist();
  }

  Future<void> clear(String groupId) async {
    _ensureLoaded();
    if (_clearedAt.remove(groupId) != null) {
      await _persist();
    }
  }

  Future<void> _persist() {
    return LocalSnapshotStore.instance.saveObject(
      SnapshotKeys.clearedGroupChats,
      _clearedAt.map((k, v) => MapEntry(k, v.toIso8601String())),
    );
  }
}
