part of 'group_details_cubit.dart';

mixin GroupReactionsMixin on Cubit<GroupDetailsState> {
  GroupChatServices get _services;
  GroupModel get group;
  String get currentUserId;
  List<GroupMessageModel> get cachedMessages;
  set cachedMessages(List<GroupMessageModel> value);
  final Map<String, Map<String, String>> _reactionsCache = {};

  String? get _messagesSnapshotKey;
  void _emitLoaded();
  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages);

  StreamSubscription? _reactionsSubscription;

  void _listenReactions() {
    _reactionsSubscription?.cancel();
    _reactionsSubscription = _services.getReactionsStream(group.id).listen((
      reactionsList,
    ) {
      _reactionsCache.clear();
      for (final r in reactionsList) {
        final msgId = r['message_id'] as String?;
        final userId = r[GroupMemberColumns.userId] as String?;
        final emoji = r['reaction'] as String?;
        if (msgId != null && userId != null && emoji != null) {
          _reactionsCache[msgId] ??= {};
          _reactionsCache[msgId]![userId] = emoji;
        }
      }

      cachedMessages =
          cachedMessages.map((msg) {
            final reactions = _reactionsCache[msg.id] ?? {};
            return msg.copyWith(reactions: reactions);
          }).toList();
      _emitLoaded();

      if (_messagesSnapshotKey != null && cachedMessages.isNotEmpty) {
        _persistMessagesSnapshot(_messagesSnapshotKey!, cachedMessages);
      }
    });
  }

  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final isOffline = await ConnectivityBannerController.notifyIfOffline();
    if (isOffline) return;

    final currentEmoji = _reactionsCache[messageId]?[currentUserId];

    _reactionsCache[messageId] ??= {};

    if (currentEmoji == emoji) {
      _reactionsCache[messageId]!.remove(currentUserId);
    } else {
      _reactionsCache[messageId]![currentUserId] = emoji;
    }

    try {
      await _services.toggleReaction(
        messageId: messageId,
        emoji: emoji,
        groupId: group.id,
        currentEmoji: currentEmoji,
      );
    } catch (e) {
      if (currentEmoji == null) {
        _reactionsCache[messageId]!.remove(currentUserId);
      } else {
        _reactionsCache[messageId]![currentUserId] = currentEmoji;
      }
      _emitLoaded();
      debugPrint('toggleReaction error: $e');
      // rethrow;
    }
  }

  @override
  Future<void> close() {
    _reactionsSubscription?.cancel();
    return super.close();
  }
}
