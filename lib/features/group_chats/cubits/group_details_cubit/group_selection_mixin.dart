part of 'group_details_cubit.dart';

mixin GroupSelectionMixin on Cubit<GroupDetailsState> {
  String get currentUserId;
  GroupChatServices get _services;
  List<GroupMessageModel> get cachedMessages;
  set cachedMessages(List<GroupMessageModel> value);
  bool get isMember;
  void cancelUpload(String tempId);
  void _emitLoaded({bool force = false});

  final ValueNotifier<Set<String>> selectedMessageIds =
      ValueNotifier<Set<String>>({});

  late final SelectedMessageStarController starController =
      SelectedMessageStarController(currentUserId: currentUserId);

  bool get isInSelectionMode => selectedMessageIds.value.isNotEmpty;

  List<GroupMessageModel> get selectedMessages =>
      cachedMessages
          .where((m) => selectedMessageIds.value.contains(m.id))
          .toList();

  bool get canDeleteSelectedForEveryone =>
      selectedMessages.isNotEmpty &&
      selectedMessages.every((m) => m.senderId == currentUserId);

  void startSelection(String messageId) {
    if (!isMember) return;
    selectedMessageIds.value = {messageId};
    starController.onSelectionChanged(selectedMessageIds.value);
  }

  void toggleMessageSelection(String messageId) {
    if (!isMember) return;
    final current = Set<String>.from(selectedMessageIds.value);
    if (current.contains(messageId)) {
      current.remove(messageId);
    } else {
      current.add(messageId);
    }
    selectedMessageIds.value = current;
    starController.onSelectionChanged(current);
  }

  void clearSelection() {
    selectedMessageIds.value = {};
    starController.onSelectionChanged(const {});
  }

  Future<void> toggleStarSelected() => starController.toggleSelected();

  Future<void> deleteSelectedForMe() async {
    final messages = selectedMessages;
    if (messages.isEmpty) return;
    clearSelection();
    try {
      await _services.deleteGroupMessagesForMe(
        messages: messages,
        currentUserId: currentUserId,
      );
    } catch (e) {
      debugPrint('error deleting selected group messages for me: $e');
      emit(GroupDetailsError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> deleteSelectedForEveryone() async {
    final ids = selectedMessageIds.value.toList();
    if (ids.isEmpty) return;

    final selectedSet = ids.toSet();
    final selected =
        cachedMessages.where((m) => selectedSet.contains(m.id)).toList();

    bool isStillSending(GroupMessageModel m) =>
        m.clientMessageId != null && m.id == m.clientMessageId;

    final stillSendingIds =
        selected.where(isStillSending).map((m) => m.id).toList();
    final realIds =
        selected.where((m) => !isStillSending(m)).map((m) => m.id).toList();

    var updated = cachedMessages;
    for (final id in selectedSet) {
      updated = GroupDetailsCubit._reconciler.removeById(updated, id);
    }
    cachedMessages = updated;
    _emitLoaded();

    for (final tempId in stillSendingIds) {
      cancelUpload(tempId);
    }

    clearSelection();

    if (realIds.isEmpty) return;

    try {
      await _services.deleteGroupMessagesForEveryone(realIds);
    } catch (e) {
      debugPrint('error deleting selected group messages for everyone: $e');
      emit(GroupDetailsError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  @override
  Future<void> close() {
    selectedMessageIds.dispose();
    starController.dispose();
    return super.close();
  }
}
