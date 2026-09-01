part of 'group_details_cubit.dart';

mixin GroupReactionsMixin on Cubit<GroupDetailsState> {
  GroupChatServices get _services;
  GroupModel get group;
  String get currentUserId;
  List<GroupMessageModel> get cachedMessages;
  bool get isMember;
  set cachedMessages(List<GroupMessageModel> value);
  void clearSelection();
  final Map<String, Map<String, String>> _reactionsCache = {};
  final Map<String, Map<String, String>> _reactionsCreatedAtCache = {};

  String? get _messagesSnapshotKey;
  void _emitLoaded({bool force = false});
  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages);

  StreamSubscription? _reactionsSubscription;

  void _listenReactions() {
    _reactionsSubscription?.cancel();
    if (!isMember) return;
    _reactionsSubscription = _services.getReactionsStream(group.id).listen((
      reactionsList,
    ) {
      _reactionsCache.clear();
      _reactionsCreatedAtCache.clear();
      for (final r in reactionsList) {
        final msgId = r['message_id'] as String?;
        final userId = r[GroupMemberColumns.userId] as String?;
        final emoji = r['reaction'] as String?;
        final createdAt = r[MessageReactionColumns.createdAt] as String?;
        if (msgId != null && userId != null && emoji != null) {
          _reactionsCache[msgId] ??= {};
          _reactionsCache[msgId]![userId] = emoji;
          if (createdAt != null) {
            _reactionsCreatedAtCache[msgId] ??= {};
            _reactionsCreatedAtCache[msgId]![userId] = createdAt;
          }
        }
      }

      cachedMessages = GroupDetailsCubit._reconciler.applyFieldUpdate(
        cachedMessages,
        (msg) => msg.copyWith(
          reactions: _reactionsCache[msg.id] ?? {},
          reactionsCreatedAt: _reactionsCreatedAtCache[msg.id],
        ),
      );
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
    if (!isMember) return;
    clearSelection();

    final isOffline = await ConnectivityBannerController.notifyIfOffline();
    if (isOffline) return;

    final currentEmoji = _reactionsCache[messageId]?[currentUserId];

    final isRemoving = currentEmoji == emoji;

    _reactionsCache[messageId] ??= {};

    if (isRemoving) {
      _reactionsCache[messageId]!.remove(currentUserId);
      _reactionsCreatedAtCache[messageId]?.remove(currentUserId);
    } else {
      _reactionsCache[messageId]![currentUserId] = emoji;
      _reactionsCreatedAtCache[messageId] ??= {};
      _reactionsCreatedAtCache[messageId]![currentUserId] =
          DateTime.now().toIso8601String();
    }
    cachedMessages = GroupDetailsCubit._reconciler.applyFieldUpdate(
      cachedMessages,
      (msg) => msg.copyWith(
        reactions: _reactionsCache[msg.id] ?? {},
        reactionsCreatedAt: _reactionsCreatedAtCache[msg.id],
      ),
    );
    _emitLoaded();
    try {
      await _services.toggleReaction(
        messageId: messageId,
        emoji: emoji,
        groupId: group.id,
        currentEmoji: currentEmoji,
      );

      if (!isRemoving) {
        unawaited(
          FcmService.instance.notifyMessageReact(
            messageId: messageId,
            isGroup: true,
            reactionType: emoji,
          ),
        );
      }
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
