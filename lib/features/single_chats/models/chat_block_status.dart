import '../../../core/cache/services/local_snapshot_store.dart';

class ChatBlockStatus {
  final bool blockedByMe;
  final bool blockedByThem;
  final bool isLoaded;

  const ChatBlockStatus({
    this.blockedByMe = false,
    this.blockedByThem = false,
    this.isLoaded = false,
  });

  bool get isBlocked => blockedByMe || blockedByThem;

  ChatBlockStatus copyWith({
    bool? blockedByMe,
    bool? blockedByThem,
    bool? isLoaded,
  }) {
    return ChatBlockStatus(
      blockedByMe: blockedByMe ?? this.blockedByMe,
      blockedByThem: blockedByThem ?? this.blockedByThem,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class ChatBlockStatusCache {
  ChatBlockStatusCache._();
  static final ChatBlockStatusCache instance = ChatBlockStatusCache._();

  static String _key(String otherUserId) => 'block_status_$otherUserId';

  ChatBlockStatus? read(String otherUserId) {
    final raw = LocalSnapshotStore.instance.readObject(_key(otherUserId));
    if (raw == null) return null;
    return ChatBlockStatus(
      blockedByMe: raw['blockedByMe'] == true,
      blockedByThem: raw['blockedByThem'] == true,
      isLoaded: true,
    );
  }

  Future<void> write(String otherUserId, ChatBlockStatus status) {
    return LocalSnapshotStore.instance.saveObject(_key(otherUserId), {
      'blockedByMe': status.blockedByMe,
      'blockedByThem': status.blockedByThem,
    });
  }
}
