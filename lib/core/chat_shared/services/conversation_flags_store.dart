import '../../cache/constants/snapshot_keys.dart';
import '../../cache/services/local_snapshot_store.dart';
import '../models/conversation_flags.dart';
import '../models/conversation_ref.dart';

class ConversationFlagsStore {
  ConversationFlagsStore._();
  static final ConversationFlagsStore instance = ConversationFlagsStore._();

  final Map<String, ConversationFlags> _flags = {};
  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    final raw = LocalSnapshotStore.instance.readObject(
      SnapshotKeys.conversationFlags,
    );
    if (raw == null) return;
    raw.forEach((key, value) {
      if (value is Map) {
        _flags[key] = ConversationFlags.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });
  }

  ConversationFlags flagsFor(ConversationRef ref) {
    _ensureLoaded();
    return _flags[ref.storageKey] ?? ConversationFlags.none;
  }

  Future<void> setPinned(ConversationRef ref, bool value) => _mutate(
    ref,
    (f) => f.copyWith(
      isPinned: value,
      pinnedAt: value ? DateTime.now().toUtc() : null,
    ),
  );

  Future<void> setFavorite(ConversationRef ref, bool value) =>
      _mutate(ref, (f) => f.copyWith(isFavorite: value));

  Future<void> setArchived(ConversationRef ref, bool value) => _mutate(
    ref,
    (f) => f.copyWith(
      isArchived: value,
      archivedAt: value ? DateTime.now().toUtc() : null,
    ),
  );

  Future<void> setMuteOverride(ConversationRef ref, bool? value) =>
      _mutate(ref, (f) => f.copyWith(muteOverride: value));

  Future<void> setAutoMutedByArchive(ConversationRef ref, bool value) =>
      _mutate(ref, (f) => f.copyWith(autoMutedByArchive: value));

  Future<void> _mutate(
    ConversationRef ref,
    ConversationFlags Function(ConversationFlags current) update,
  ) async {
    _ensureLoaded();
    _flags[ref.storageKey] = update(flagsFor(ref));
    await LocalSnapshotStore.instance.saveObject(
      SnapshotKeys.conversationFlags,
      _flags.map((k, v) => MapEntry(k, v.toJson())),
    );
  }
}
