part of 'chat_details_cubit.dart';

mixin ChatReactionsMixin on Cubit<ChatDetailsState> {
  String get currentUserId;
  ChatServices get _chatServices;
  List<MessageModel> get cachedMessages;
  set cachedMessages(List<MessageModel> val);
  String? get _messagesSnapshotKey;
  void _persistMessagesSnapshot(String key, List<MessageModel> messages);
  void clearSelection();
  StreamSubscription? _reactionsSubscription;
  Map<String, Map<String, String>> _reactionsCache = {};

  void _listenReactions(String conversationId) {
    _reactionsSubscription?.cancel();
    _reactionsSubscription = _chatServices
        .getMessageReactionsStream(conversationId)
        .listen((reactionsList) {
          _reactionsCache = {};

          for (final r in reactionsList) {
            final msgId = r[MessageReactionColumns.messageId] as String?;
            final userId = r[MessageReactionColumns.userId] as String?;
            final emoji = r[MessageReactionColumns.reaction] as String?;
            if (msgId != null && userId != null && emoji != null) {
              _reactionsCache[msgId] ??= {};
              _reactionsCache[msgId]![userId] = emoji;
            }
          }

          cachedMessages =
              cachedMessages.map((m) {
                final reactions = _reactionsCache[m.id] ?? {};
                return m.copyWith(reactions: reactions);
              }).toList();

          if (!isClosed) emit(MessagesSuccessLoaded(messages: cachedMessages));

          if (_messagesSnapshotKey != null && cachedMessages.isNotEmpty) {
            _persistMessagesSnapshot(_messagesSnapshotKey!, cachedMessages);
          }
        });
  }

  Future<void> toggleReaction({
    required String messageId,
    required String receiverId,
    required String emoji,
  }) async {
    clearSelection();

    final isOffline = await ConnectivityBannerController.notifyIfOffline();
    if (isOffline) return;

    final ids = [currentUserId, receiverId];
    ids.sort();
    final conversationId = ids.join('_');

    final currentEmoji = _reactionsCache[messageId]?[currentUserId];
    _reactionsCache[messageId] ??= {};
    if (currentEmoji == emoji) {
      _reactionsCache[messageId]!.remove(currentUserId);
    } else {
      _reactionsCache[messageId]![currentUserId] = emoji;
    }
    _applyReactionsCacheToMessages();

    try {
      await _chatServices.toggleReaction(
        messageId: messageId,
        conversationId: conversationId,
        emoji: emoji,
      );
    } catch (e) {
      if (currentEmoji == null) {
        _reactionsCache[messageId]!.remove(currentUserId);
      } else {
        _reactionsCache[messageId]![currentUserId] = currentEmoji;
      }
      _applyReactionsCacheToMessages();
      debugPrint('error toggling reaction: $e');
    }
  }

  void _applyReactionsCacheToMessages() {
    cachedMessages =
        cachedMessages.map((m) {
          final reactions = _reactionsCache[m.id] ?? {};
          return m.copyWith(reactions: reactions);
        }).toList();
    if (!isClosed) emit(MessagesSuccessLoaded(messages: cachedMessages));
  }

  @override
  Future<void> close() {
    _reactionsSubscription?.cancel();
    return super.close();
  }
}
