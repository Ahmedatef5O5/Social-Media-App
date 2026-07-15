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
  void _emitLoaded();
  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages);
  Future<void> markRead();

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _readReceiptsSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingDebounce;

  void _listenMessages() {
    _messagesSubscription?.cancel();
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
        );
      }
    });
  }

  void _listenReadReceipts() {
    _readReceiptsSubscription?.cancel();
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
    _typingSubscription = _services.getTypingUsersStream(group.id).listen((
      typingIds,
    ) {
      _typingUserIds = typingIds;
      _emitLoaded();
    });
  }

  void onTyping() {
    _services.setTyping(group.id, true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _services.setTyping(group.id, false);
    });
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _readReceiptsSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    return super.close();
  }
}
