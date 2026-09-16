import 'package:flutter/foundation.dart';
import '../../../core/cache/services/starred_message_store.dart';

enum AiSelectionStarState { none, allStarred, allUnstarred, mixed }

class AiChatSelectionController {
  AiChatSelectionController({required this.currentUserId}) {
    _loadStarredMessageIds();
  }

  final String currentUserId;
  final StarredMessagesStore _starStore = StarredMessagesStore.instance;

  final ValueNotifier<Set<String>> selectedMessageIds =
      ValueNotifier<Set<String>>({});
  final ValueNotifier<AiSelectionStarState> starState =
      ValueNotifier<AiSelectionStarState>(AiSelectionStarState.none);

  final ValueNotifier<Set<String>> starredMessageIds =
      ValueNotifier<Set<String>>({});

  bool get isInSelectionMode => selectedMessageIds.value.isNotEmpty;

  Future<void> _loadStarredMessageIds() async {
    final ids = await _starStore.getStarredMessageIds(currentUserId);
    starredMessageIds.value = ids.toSet();
  }

  void startSelection(String messageId) {
    selectedMessageIds.value = {messageId};
    _refreshStarState();
  }

  void toggleMessageSelection(String messageId) {
    final current = Set<String>.from(selectedMessageIds.value);
    if (current.contains(messageId)) {
      current.remove(messageId);
    } else {
      current.add(messageId);
    }
    selectedMessageIds.value = current;
    _refreshStarState();
  }

  void clearSelection() {
    selectedMessageIds.value = {};
    starState.value = AiSelectionStarState.none;
  }

  bool _sameSelection(List<String> ids) {
    final current = selectedMessageIds.value;
    return current.length == ids.length && ids.every(current.contains);
  }

  Future<void> _refreshStarState() async {
    final ids = selectedMessageIds.value.toList(growable: false);
    if (ids.isEmpty) {
      starState.value = AiSelectionStarState.none;
      return;
    }

    final flags = await Future.wait(
      ids.map(
        (id) =>
            _starStore.isStarred(currentUserId: currentUserId, messageId: id),
      ),
    );

    // The selection may have changed while these lookups were in flight
    // (fast tapping) — a stale result must never clobber a newer one.
    if (!_sameSelection(ids)) return;

    final allStarred = flags.every((f) => f);
    final allUnstarred = flags.every((f) => !f);
    starState.value =
        allStarred
            ? AiSelectionStarState.allStarred
            : allUnstarred
            ? AiSelectionStarState.allUnstarred
            : AiSelectionStarState.mixed;
  }

  Future<void> toggleStarForSelection() async {
    final current = starState.value;
    if (current == AiSelectionStarState.mixed ||
        current == AiSelectionStarState.none) {
      return;
    }

    final shouldStar = current == AiSelectionStarState.allUnstarred;
    final ids = selectedMessageIds.value.toList(growable: false);

    for (final id in ids) {
      final isStarred = await _starStore.isStarred(
        currentUserId: currentUserId,
        messageId: id,
      );
      if (isStarred != shouldStar) {
        await _starStore.toggleStar(
          currentUserId: currentUserId,
          messageId: id,
        );
      }
    }

    final updatedStarred = Set<String>.from(starredMessageIds.value);
    if (shouldStar) {
      updatedStarred.addAll(ids);
    } else {
      updatedStarred.removeAll(ids);
    }
    starredMessageIds.value = updatedStarred;

    if (_sameSelection(ids)) {
      starState.value =
          shouldStar
              ? AiSelectionStarState.allStarred
              : AiSelectionStarState.allUnstarred;
    }
  }

  void dispose() {
    selectedMessageIds.dispose();
    starState.dispose();
    starredMessageIds.dispose();
  }
}
