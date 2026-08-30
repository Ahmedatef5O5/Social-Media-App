part of 'chat_details_cubit.dart';

mixin ChatPresenceActionMixin on Cubit<ChatDetailsState> {
  String get currentUserId;
  ChatPresenceService get _presenceService;
  ValueNotifier<bool> get isAtBottomNotifier;

  Timer? _typingDebounce;
  Timer? _recordingHeartbeat;
  StreamSubscription? _actionSubscription;

  final ValueNotifier<ChatActionType> receiverAction = ValueNotifier(
    ChatActionType.none,
  );
  final ValueNotifier<ChatActionType> listVisibleAction = ValueNotifier(
    ChatActionType.none,
  );

  void _recomputeListVisibleAction() {
    listVisibleAction.value =
        isAtBottomNotifier.value ? receiverAction.value : ChatActionType.none;
  }

  String getChatId(String u1, String u2) {
    final ids = [u1, u2]..sort();
    return ids.join('_');
  }

  void watchReceiverAction(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);
    _actionSubscription?.cancel();
    _actionSubscription = _presenceService
        .getActionStream(chatId: chatId, receiverId: receiverId)
        .listen((action) {
          receiverAction.value = action;
          // if (receiverAction.value != action) {
          //   receiverAction.value = action;
          // }
          _recomputeListVisibleAction();
        });
    isAtBottomNotifier.addListener(_recomputeListVisibleAction);
  }

  void onUserTyping(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);
    _presenceService.setAction(
      chatId: chatId,
      currentUserId: currentUserId,
      actionType: ChatActionType.typing,
    );
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _presenceService.setAction(
        chatId: chatId,
        currentUserId: currentUserId,
        actionType: ChatActionType.none,
      );
    });
  }

  void stopTyping(String receiverId) {
    _typingDebounce?.cancel();
    final chatId = getChatId(currentUserId, receiverId);
    _presenceService.setAction(
      chatId: chatId,
      currentUserId: currentUserId,
      actionType: ChatActionType.none,
    );
  }

  void startRecordingAction(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);
    _emitAction(chatId, ChatActionType.recording);

    _recordingHeartbeat?.cancel();
    _recordingHeartbeat = Timer.periodic(const Duration(seconds: 2), (_) {
      _emitAction(chatId, ChatActionType.recording);
    });
  }

  void pauseRecordingAction(String receiverId) {
    _recordingHeartbeat?.cancel();
    _emitAction(getChatId(currentUserId, receiverId), ChatActionType.none);
  }

  void resumeRecordingAction(String receiverId) =>
      startRecordingAction(receiverId);

  void stopRecordingAction(String receiverId) {
    _recordingHeartbeat?.cancel();
    _emitAction(getChatId(currentUserId, receiverId), ChatActionType.none);
  }

  void cancelRecordingAction(String receiverId) =>
      stopRecordingAction(receiverId);

  void _emitAction(String chatId, ChatActionType type) {
    _presenceService.setAction(
      chatId: chatId,
      currentUserId: currentUserId,
      actionType: type,
    );
  }

  @override
  Future<void> close() {
    _typingDebounce?.cancel();
    _recordingHeartbeat?.cancel();
    _actionSubscription?.cancel();
    isAtBottomNotifier.removeListener(_recomputeListVisibleAction);
    receiverAction.dispose();
    listVisibleAction.dispose();
    return super.close();
  }
}
