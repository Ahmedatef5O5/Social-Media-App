part of 'chat_details_cubit.dart';

mixin ChatSelectionMixin on Cubit<ChatDetailsState> {
  String get currentUserId;
  ChatServices get _chatServices;
  List<MessageModel> get cachedMessages;
  set cachedMessages(List<MessageModel> val);
  void cancelUpload(String messageId);
  final ValueNotifier<Set<String>> selectedMessageIds =
      ValueNotifier<Set<String>>({});

  late final SelectedMessageStarController starController =
      SelectedMessageStarController(currentUserId: currentUserId);

  bool get isInSelectionMode => selectedMessageIds.value.isNotEmpty;

  List<MessageModel> get selectedMessages =>
      cachedMessages
          .where((m) => selectedMessageIds.value.contains(m.id))
          .toList();

  bool get canDeleteSelectedForEveryone =>
      selectedMessages.isNotEmpty &&
      selectedMessages.every((m) => m.senderId == currentUserId);

  void startSelection(String messageId) {
    selectedMessageIds.value = {messageId};
    starController.onSelectionChanged(selectedMessageIds.value);
  }

  void toggleMessageSelection(String messageId) {
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
      await _chatServices.deleteMessagesForMe(
        messages: messages,
        currentUserId: currentUserId,
      );
    } catch (e) {
      debugPrint('error deleting selected messages for me: $e');
      emit(MessagesError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> deleteSelectedForEveryone() async {
    final ids = selectedMessageIds.value.toList();
    if (ids.isEmpty) return;

    final selectedSet = ids.toSet();
    final selected =
        cachedMessages.where((m) => selectedSet.contains(m.id)).toList();

    bool isStillSending(MessageModel m) =>
        m.clientMessageId != null && m.id == m.clientMessageId;

    final stillSendingIds =
        selected.where(isStillSending).map((m) => m.id).toList();
    final realIds =
        selected.where((m) => !isStillSending(m)).map((m) => m.id).toList();

    var updated = cachedMessages;
    for (final m in selected) {
      updated = ChatDetailsCubit._reconciler.applyRemoval(
        updated,
        id: m.id,
        clientMessageId: m.clientMessageId,
      );
    }
    cachedMessages = updated;
    emit(MessagesSuccessLoaded(messages: List.from(cachedMessages)));

    for (final tempId in stillSendingIds) {
      cancelUpload(tempId);
    }

    clearSelection();

    if (realIds.isEmpty) return;

    try {
      await _chatServices.deleteMessagesForEveryone(realIds);
    } catch (e) {
      debugPrint('error deleting selected messages for everyone: $e');
      emit(MessagesError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  @override
  Future<void> close() {
    selectedMessageIds.dispose();
    starController.dispose();
    return super.close();
  }
}
