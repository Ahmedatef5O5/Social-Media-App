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

    final nowUtc = DateTime.now().toUtc();
    final stampedMentions =
        mentions
            .map(
              (r) => MentionRef(
                mentionedUserId: r.mentionedUserId,
                startIndex: r.startIndex,
                endIndex: r.endIndex,
                createdAt: nowUtc,
              ),
            )
            .toList();

    final selfCubit = this as GroupDetailsCubit;
    selfCubit._localEditedMentions[messageId] = stampedMentions;
    selfCubit._mentionsCache[messageId] = stampedMentions;

    cachedMessages = GroupDetailsCubit._reconciler.applyFieldUpdate(
      cachedMessages,
      (m) {
        if (m.id != messageId) return m;
        return isCaptionEdit
            ? m.copyWith(
              caption: trimmed,
              mentions: stampedMentions,
              isEdited: true,
            )
            : m.copyWith(
              text: trimmed,
              mentions: stampedMentions,
              isEdited: true,
            );
      },
    );
    _emitLoaded();
    if (selfCubit._messagesSnapshotKey != null) {
      selfCubit._persistMessagesSnapshot(
        selfCubit._messagesSnapshotKey!,
        cachedMessages,
      );
    }

    try {
      await _services.editGroupMessage(
        messageId: messageId,
        newText: trimmed,
        isCaptionEdit: isCaptionEdit,
        groupId: group.id,
        mentions: stampedMentions,
      );
    } catch (e) {
      debugPrint('Error editing group message: $e');
    }
  }
}
