part of 'chat_details_cubit.dart';

mixin ChatTypingStatusMixin on Cubit<ChatDetailsState> {
  String get currentUserId;
  ChatServices get _chatServices;
  StreamSubscription? _typingSubscription;
  Timer? _typingDebounce;
  Timer? _typingStuckGuardTimer;
  static const Duration _typingStuckTimeout = Duration(seconds: 4);

  String getChatId(String u1, String u2) {
    List<String> ids = [u1, u2];
    ids.sort();
    return ids.join('_');
  }

  void watchReceiverTyping(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);

    _typingSubscription?.cancel();
    _typingStuckGuardTimer?.cancel();

    _typingSubscription = _chatServices
        .getTypingStream(
          chatId: chatId,
          receiverId: receiverId,
          currentUserId: currentUserId,
        )
        .listen((isTyping) {
          if (isClosed) return;
          emit(ReceiverTypingState(isTyping));
          _resetTypingStuckGuard(isTyping);
        });
  }

  void _resetTypingStuckGuard(bool isTyping) {
    _typingStuckGuardTimer?.cancel();
    if (!isTyping) return;
    _typingStuckGuardTimer = Timer(_typingStuckTimeout, () {
      if (!isClosed) {
        emit(const ReceiverTypingState(false));
      }
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
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    _typingStuckGuardTimer?.cancel();
    return super.close();
  }
}
