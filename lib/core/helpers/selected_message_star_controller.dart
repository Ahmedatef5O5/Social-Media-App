import 'package:flutter/foundation.dart';
import '../cache/services/starred_message_store.dart';

class SelectedMessageStarController {
  final String currentUserId;
  final StarredMessagesStore _store = StarredMessagesStore.instance;

  SelectedMessageStarController({required this.currentUserId});

  final ValueNotifier<bool> isSelectedStarred = ValueNotifier<bool>(false);
  String? _trackedMessageId;
  bool _isDisposed = false;

  /// Call this whenever the selection set changes (start/toggle/clear).
  Future<void> onSelectionChanged(Set<String> selectedIds) async {
    if (_isDisposed) return;
    if (selectedIds.length != 1) {
      _trackedMessageId = null;
      isSelectedStarred.value = false;
      return;
    }

    final messageId = selectedIds.first;
    _trackedMessageId = messageId;

    final starred = await _store.isStarred(
      currentUserId: currentUserId,
      messageId: messageId,
    );

    if (!_isDisposed && _trackedMessageId == messageId) {
      isSelectedStarred.value = starred;
    }
  }

  Future<void> toggleSelected() async {
    if (_isDisposed) return;
    final messageId = _trackedMessageId;
    if (messageId == null) return;

    final next = await _store.toggleStar(
      currentUserId: currentUserId,
      messageId: messageId,
    );

    if (!_isDisposed && _trackedMessageId == messageId) {
      isSelectedStarred.value = next;
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    isSelectedStarred.dispose();
  }
}
