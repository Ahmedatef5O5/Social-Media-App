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
  List<String> _typingUserIds = [];
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
            _listenTyping();
          }
        });
  }

  void _listenMessages() {
    _messagesSubscription?.cancel();
    if (!isMember) return;
    _messagesSubscription = _services.getGroupMessagesStream(group.id).listen((
      messages,
    ) {
      final existingById = {for (final c in cachedMessages) c.id: c};

      final enriched =
          messages.map((msg) {
            final existing = existingById[msg.id];

            final mentions =
                _mentionsCache[msg.id] ??
                existing?.mentions ??
                const <MentionRef>[];
            final reactions =
                _reactionsCache[msg.id] ?? existing?.reactions ?? {};
            return msg.copyWith(mentions: mentions, reactions: reactions);
          }).toList();

      cachedMessages = enriched;
      _isFirstLoad = false;
      _emitLoaded();
      if (_messagesSnapshotKey != null) {
        _persistMessagesSnapshot(_messagesSnapshotKey!, enriched);
      }

      // Mark read in DB
      markRead();

      bool amIRemoved = false;
      for (final msg in messages) {
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

      if (enriched.isNotEmpty) {
        final latest = enriched.first;

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

  void _listenTyping() {
    _typingSubscription?.cancel();
    if (!isMember) return;
    _typingSubscription = _services.getTypingUsersStream(group.id).listen((
      typingIds,
    ) {
      _typingUserIds = typingIds;
      _emitLoaded();
    });
  }

  void onTyping() {
    if (!isMember) return;
    _services.setTyping(group.id, true, isMember: isMember);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _services.setTyping(group.id, false, isMember: isMember);
    });
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _readReceiptsSubscription?.cancel();
    _typingSubscription?.cancel();
    _membershipSubscription?.cancel();
    _typingDebounce?.cancel();
    return super.close();
  }
}
