part of 'chat_details_cubit.dart';

mixin ChatPresenceActionMixin on Cubit<ChatDetailsState> {
  String get currentUserId;
  ChatPresenceService get _presenceService;
  ValueNotifier<bool> get isAtBottomNotifier;

  Timer? _typingDebounce;
  Timer? _recordingHeartbeat;
  StreamSubscription? _actionSubscription;
  DateTime? _lastTypingSentAt;
  bool _isRecordingActionActive = false;

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
    isAtBottomNotifier.removeListener(_recomputeListVisibleAction);
    isAtBottomNotifier.addListener(_recomputeListVisibleAction);

    _actionSubscription = _presenceService
        .getActionStream(chatId: chatId, receiverId: receiverId)
        .listen((action) {
          if (receiverAction.value != action) {
            receiverAction.value = action;
          }
          _recomputeListVisibleAction();
        });
  }

  void onUserTyping(String receiverId) {
    if (_isRecordingActionActive) return;

    final chatId = getChatId(currentUserId, receiverId);
    final now = DateTime.now();
    if (_lastTypingSentAt == null ||
        now.difference(_lastTypingSentAt!).inMilliseconds >= 1500) {
      _lastTypingSentAt = now;
      _emitAction(chatId, ChatActionType.typing);
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _lastTypingSentAt = null;
      if (!_isRecordingActionActive) {
        _emitAction(chatId, ChatActionType.none);
      }
    });
  }

  void stopTyping(String receiverId) {
    _typingDebounce?.cancel();
    _lastTypingSentAt = null;
    if (_isRecordingActionActive) return;
    _emitAction(getChatId(currentUserId, receiverId), ChatActionType.none);
  }

  void startRecordingAction(String receiverId) {
    _isRecordingActionActive = true;
    _typingDebounce?.cancel();
    _lastTypingSentAt = null;

    final chatId = getChatId(currentUserId, receiverId);
    _emitAction(chatId, ChatActionType.recording);

    _recordingHeartbeat?.cancel();
    _recordingHeartbeat = Timer.periodic(const Duration(seconds: 2), (_) {
      _emitAction(chatId, ChatActionType.recording);
    });
  }

  void pauseRecordingAction(String receiverId) {
    _isRecordingActionActive = false;
    _recordingHeartbeat?.cancel();
    _emitAction(getChatId(currentUserId, receiverId), ChatActionType.none);
  }

  void resumeRecordingAction(String receiverId) =>
      startRecordingAction(receiverId);

  void stopRecordingAction(String receiverId) {
    _isRecordingActionActive = false;
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
