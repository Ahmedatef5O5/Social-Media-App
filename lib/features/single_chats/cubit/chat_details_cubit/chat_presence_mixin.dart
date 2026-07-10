part of 'chat_details_cubit.dart';

mixin ChatPresenceMixin on Cubit<ChatDetailsState> {
  String get currentUserId;
  ChatServices get _chatServices;
  StreamSubscription? _presenceSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingDebounce;
  Timer? _lastSeenPollingTimer;
  PresenceSnapshot? _lastPresence;

  Future<void> updateLastSeen() async {
    try {
      await _chatServices.updateLastSeen(currentUserId);
    } catch (e) {
      debugPrint('error updating last seen: $e');
      emit(MessagesError(e.toString()));
    }
  }

  void watchReceiverPresence(String receiverId, {PresenceSnapshot? initial}) {
    _presenceSubscription?.cancel();

    if (initial != null) {
      _lastPresence = initial;
      Future.microtask(() {
        if (!isClosed) {
          emit(
            ReceiverPresenceUpdated(
              isOnline: initial.isOnline,
              lastSeen: initial.lastSeen,
            ),
          );
        }
      });
    }

    _presenceSubscription = _chatServices.getPresenceStream(receiverId).listen((
      snapshot,
    ) {
      _lastPresence = snapshot;
      if (!isClosed) {
        emit(
          ReceiverPresenceUpdated(
            isOnline: snapshot.isOnline,
            lastSeen: snapshot.lastSeen,
          ),
        );
      }
    });
  }

  PresenceSnapshot? get lastPresence => _lastPresence;

  String getChatId(String u1, String u2) {
    List<String> ids = [u1, u2];
    ids.sort();
    return ids.join('_');
  }

  void watchReceiverTyping(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);

    _typingSubscription?.cancel();
    _typingSubscription = _chatServices
        .getTypingStream(
          chatId: chatId,
          receiverId: receiverId,
          currentUserId: currentUserId,
        )
        .listen((isTyping) {
          if (!isClosed) emit(ReceiverTypingState(isTyping));
        });
  }

  void onUserTyping(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);

    _chatServices.setTyping(
      chatId: chatId,
      currentUserId: currentUserId,
      isTyping: true,
    );

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _chatServices.setTyping(
        chatId: chatId,
        currentUserId: currentUserId,
        isTyping: false,
      );
    });
  }

  void stopTyping(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);

    _typingDebounce?.cancel();
    _chatServices.setTyping(
      chatId: chatId,
      currentUserId: currentUserId,
      isTyping: false,
    );
  }

  @override
  Future<void> close() {
    _presenceSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    _lastSeenPollingTimer?.cancel();
    return super.close();
  }
}
