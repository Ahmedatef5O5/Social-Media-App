part of 'group_details_cubit.dart';

mixin GroupMessagesStreamMixin on Cubit<GroupDetailsState> {
  GroupChatServices get _services;
  GroupModel get group;
  GroupListCubit get groupListCubit;
  List<GroupMessageModel> get cachedMessages;
  set cachedMessages(List<GroupMessageModel> value);
  Map<String, List<MentionRef>> get _mentionsCache;
  Map<String, Map<String, String>> get _reactionsCache;
  bool _isFirstLoad = true;
  bool _hasReceivedFirstStreamEvent = false;
  GroupPresenceSnapshot _presence = GroupPresenceSnapshot.empty;
  Timer? _recordingHeartbeat;
  bool _isRecordingActionActive = false;
  String? get _messagesSnapshotKey;
  String get currentUserId;
  bool get isMember;
  set isMember(bool value);

  void _emitLoaded({bool force = false});
  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages);
  Future<void> markRead();

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _readReceiptsSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _membershipSubscription;
  Timer? _typingDebounce;

  void _listenMembership() {
    _membershipSubscription?.cancel();
    _membershipSubscription = SupabaseProvider.client
        .from(SupabaseConstants.groupMembers)
        .stream(primaryKey: ['id'])
        .eq(GroupMemberColumns.groupId, group.id)
        .listen((data) {
          final myRow = data.firstWhere(
            (row) => row[GroupMemberColumns.userId] == currentUserId,
            orElse: () => <String, dynamic>{},
          );

          final bool newIsMember =
              myRow.isNotEmpty &&
              myRow[GroupMemberColumns.membershipStatus] == 'active';

          final lastStateIsMember =
              state is GroupDetailsLoaded
                  ? (state as GroupDetailsLoaded).isMember
                  : null;

          if (lastStateIsMember == newIsMember) return;

          isMember = newIsMember;
          _emitLoaded(force: true);

          groupListCubit.updateGroupMembership(group.id, newIsMember);

          if (!newIsMember) {
            _messagesSubscription?.cancel();
            _messagesSubscription = null;
            _readReceiptsSubscription?.cancel();
            _readReceiptsSubscription = null;
            _typingSubscription?.cancel();
            _typingSubscription = null;
          } else {
            _listenMessages();
            _listenReadReceipts();
            _listenPresence();
          }
        });
  }

  void _listenMessages() {
    _messagesSubscription?.cancel();
    if (!isMember) return;

    _hasReceivedFirstStreamEvent = false;

    final clearedAt = GroupChatClearStore.instance.clearedAtFor(group.id);

    _messagesSubscription = _services.getGroupMessagesStream(group.id).listen((
      messages,
    ) {
      final visibleMessages =
          clearedAt == null
              ? messages
              : messages.where((m) => m.createdAt.isAfter(clearedAt)).toList();

      final existingById = {for (final c in cachedMessages) c.id: c};

      final enriched =
          visibleMessages.map((msg) {
            final existing = existingById[msg.id];
            final mentions =
                _mentionsCache[msg.id] ??
                existing?.mentions ??
                const <MentionRef>[];
            final reactions =
                _reactionsCache[msg.id] ?? existing?.reactions ?? {};
            return msg.copyWith(mentions: mentions, reactions: reactions);
          }).toList();

      List<GroupMessageModel> resolved;
      if (!_hasReceivedFirstStreamEvent && cachedMessages.isNotEmpty) {
        final cachedIds = cachedMessages.map((m) => m.id).toSet();
        resolved = [
          ...enriched.where((m) => !cachedIds.contains(m.id)),
          ...cachedMessages,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        resolved = enriched;
      }
      _hasReceivedFirstStreamEvent = true;

      cachedMessages = resolved;
      _isFirstLoad = false;
      _emitLoaded();
      if (_messagesSnapshotKey != null) {
        _persistMessagesSnapshot(_messagesSnapshotKey!, resolved);
      }

      markRead();

      bool amIRemoved = false;
      for (final msg in visibleMessages) {
        if (msg.isSystemEvent) {
          final type = msg.systemEventData?['type'];
          final targetId = msg.targetId ?? msg.systemEventData?['target_id'];
          if (targetId == currentUserId && type == 'member_removed') {
            amIRemoved = true;
            break;
          }
        }
      }
      if (amIRemoved) {
        groupListCubit.updateGroupMembership(group.id, false);
      }

      if (resolved.isNotEmpty) {
        final latest = resolved.first;
        groupListCubit.updateGroupLastMessage(
          groupId: group.id,
          message: latest.text,
          messageId: latest.id,
          messageType: latest.messageType,
          createdAt: latest.createdAt,
          lastMessageSenderId: latest.senderId,
          lastMessageSenderName: latest.senderName,
          lastMessageTargetId: latest.targetId,
          lastMessageTargetName: latest.targetName,
        );
      }
    });
  }

  void _listenReadReceipts() {
    _readReceiptsSubscription?.cancel();
    if (!isMember) return;
    _readReceiptsSubscription = _services
        .getReadReceiptsStream(group.id)
        .listen((receipts) {
          if (receipts.isEmpty) return;

          final receiptMap = <String, Set<String>>{};
          for (final r in receipts) {
            final id = r['id'] as String?;
            final readByRaw = r['read_by'];
            if (id == null) continue;
            Set<String> readBySet = {};
            if (readByRaw is List) {
              readBySet = readByRaw.map((e) => e.toString()).toSet();
            }
            receiptMap[id] = readBySet;
          }

          bool changed = false;
          cachedMessages =
              cachedMessages.map((msg) {
                final newReadBy = receiptMap[msg.id];
                if (newReadBy != null && newReadBy != msg.readBy) {
                  changed = true;
                  return msg.copyWith(readBy: newReadBy);
                }
                return msg;
              }).toList();

          if (changed) _emitLoaded();
        });
  }

  void _listenPresence() {
    _typingSubscription?.cancel();
    if (!isMember) return;
    _typingSubscription = _services.watchGroupPresence(group.id).listen((
      snapshot,
    ) {
      _presence = snapshot;
      _emitLoaded();
    });
  }

  void onTyping() {
    if (!isMember) return;
    _services.setGroupAction(
      group.id,
      ChatActionType.typing,
      isMember: isMember,
    );
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _services.setGroupAction(
        group.id,
        ChatActionType.none,
        isMember: isMember,
      );
    });
  }

  void startRecordingAction() {
    if (!isMember) return;
    _isRecordingActionActive = true;
    _services.setGroupAction(
      group.id,
      ChatActionType.recording,
      isMember: isMember,
    );
    _recordingHeartbeat?.cancel();
    _recordingHeartbeat = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isRecordingActionActive) {
        timer.cancel();
        return;
      }
      _services.setGroupAction(
        group.id,
        ChatActionType.recording,
        isMember: isMember,
      );
    });
  }

  void pauseRecordingAction() {
    _recordingHeartbeat?.cancel();
    _services.setGroupAction(group.id, ChatActionType.none, isMember: isMember);
  }

  void resumeRecordingAction() => startRecordingAction();

  void stopRecordingAction() {
    _isRecordingActionActive = false;
    _recordingHeartbeat?.cancel();

    _services.setGroupAction(group.id, ChatActionType.none, isMember: isMember);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!isClosed) {
        _services.setGroupAction(
          group.id,
          ChatActionType.none,
          isMember: isMember,
        );
      }
    });
  }

  void cancelRecordingAction() => stopRecordingAction();

  @override
  Future<void> close() {
    stopRecordingAction();
    _messagesSubscription?.cancel();
    _readReceiptsSubscription?.cancel();
    _typingSubscription?.cancel();
    _membershipSubscription?.cancel();
    _typingDebounce?.cancel();
    return super.close();
  }
}
