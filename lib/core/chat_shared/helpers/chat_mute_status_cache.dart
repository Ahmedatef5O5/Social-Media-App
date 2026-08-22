import '../../cache/services/local_snapshot_store.dart';

class ChatMuteStatusCache {
  ChatMuteStatusCache._();
  static final ChatMuteStatusCache instance = ChatMuteStatusCache._();

  static String _key(String peerId) => 'chat_mute_status_$peerId';

  bool? read(String peerId) {
    final raw = LocalSnapshotStore.instance.readObject(_key(peerId));
    if (raw == null) return null;
    return raw['isMuted'] == true;
  }

  Future<void> write(String peerId, bool isMuted) {
    return LocalSnapshotStore.instance.saveObject(_key(peerId), {
      'isMuted': isMuted,
    });
  }
}
