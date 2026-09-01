part of 'group_details_cubit.dart';

mixin GroupEditMixin on Cubit<GroupDetailsState> {
  GroupChatServices get _services;
  List<GroupMessageModel> get cachedMessages;
  set cachedMessages(List<GroupMessageModel> value);
  GroupModel get group;
  String get currentUserId;
  void _emitLoaded({bool force = false});

  Future<void> editMessage({
    required String messageId,
    required String newText,
    List<MentionRef> mentions = const [],
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final target = cachedMessages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => cachedMessages.first,
    );
    if (target.senderId != currentUserId) {
      debugPrint(
        '⛔ Blocked: attempt to edit a message not owned by current user',
      );
      return;
    }

    final isCaptionEdit =
        target.messageType == 'image' || target.messageType == 'video';

    cachedMessages = GroupDetailsCubit._reconciler.applyFieldUpdate(
      cachedMessages,
      (m) {
        if (m.id != messageId) return m;
        return isCaptionEdit
            ? m.copyWith(caption: trimmed, isEdited: true)
            : m.copyWith(text: trimmed, isEdited: true);
      },
    );
    _emitLoaded();

    try {
      await _services.editGroupMessage(
        messageId: messageId,
        newText: trimmed,
        isCaptionEdit: isCaptionEdit,
        groupId: group.id,
        mentions: mentions,
      );
    } catch (e) {
      debugPrint('Error editing group message: $e');
    }
  }
}
