import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/fcm_services.dart';
import '../../models/message_model.dart';
import '../../services/chat_services.dart';
import '../../widgets/chat_bubble.dart';
part 'chat_details_state.dart';

class ChatDetailsCubit extends Cubit<ChatDetailsState> {
  final ChatServices _chatServices;
  final String receiverName;
  final String? senderImageUrl;

  final ValueNotifier<MessageModel?> replyToMessage =
      ValueNotifier<MessageModel?>(null);

  StreamSubscription? _messageSubscription;
  StreamSubscription? _lastSeenSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingDebounce;
  Timer? _lastSeenPollingTimer;

  List<MessageModel> cachedMessages = [];

  final currentUserId = Supabase.instance.client.auth.currentUser!.id;

  final String currentUserName;

  final Map<String, GlobalKey<ChatBubbleState>> bubbleKeys = {};

  ChatDetailsCubit(
    this._chatServices,
    this.receiverName, {
    this.senderImageUrl,
    this.currentUserName = 'Someone',
  }) : super(ChatDetailsInitial());

  bool _isUserAtBottom = true;

  void setUserAtBottom(bool isAtBottom) {
    _isUserAtBottom = isAtBottom;

    if (isAtBottom && _pendingReceiverId != null) {
      markAsRead(senderId: _pendingReceiverId!);
    }
  }

  String? _pendingReceiverId;

  void getMessagesStream({required String receiverId}) {
    _messageSubscription?.cancel();
    _messageSubscription = _chatServices
        .getMessagesStream(senderId: currentUserId, receiverId: receiverId)
        .listen((messages) {
          final currentIds = messages.map((m) => m.id).toSet();
          bubbleKeys.removeWhere((key, _) => !currentIds.contains(key));
          for (final msg in messages) {
            if (!bubbleKeys.containsKey(msg.id)) {
              bubbleKeys[msg.id] = GlobalKey<ChatBubbleState>();
            }
          }

          cachedMessages = messages;
          emit(MessagesSuccessLoaded(messages: messages));
          bool hasUnread = messages.any(
            (m) => !m.isRead && m.receiverId == currentUserId,
          );
          if (hasUnread && _isUserAtBottom) {
            markAsRead(senderId: receiverId);
          }
        });
  }

  Future<void> markAsRead({required String senderId}) async {
    try {
      await _chatServices.markMessagesAsRead(
        senderId: senderId,
        currentUserId: currentUserId,
      );
    } catch (e) {
      debugPrint('error marking as read: $e');
      emit(MessagesError(e.toString()));
    }
  }

  final Map<String, double> uploadProgressMap = {};

  Future<void> sendMessage({
    required String receiverId,
    required String messageText,
    String messageType = 'text',
    File? imageFile,
    File? videoFile,
    File? voiceFile,
    String? caption,
    MessageModel? replyTo,
  }) async {
    if (messageText.trim().isEmpty &&
        imageFile == null &&
        videoFile == null &&
        voiceFile == null) {
      return;
    }

    final List<MessageModel> currentMessages = List.from(cachedMessages);

    // optimistic Message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      senderId: currentUserId,
      receiverId: receiverId,
      text: messageText,
      messageType: messageType,
      createdAt: DateTime.now(),
      isRead: false,
      voiceUrl: voiceFile?.path,
      replyToMessageId: replyToMessage.value?.id,
      replyToText: replyToMessage.value?.text,
      replyToMessageType: replyToMessage.value?.messageType,
      replyToSenderId: replyToMessage.value?.senderId,
    );

    final updatedMessages = [optimisticMessage, ...currentMessages];
    cachedMessages = updatedMessages;
    emit(MessagesSending(messages: updatedMessages));

    final cancelToken = dio_pkg.CancelToken();
    _cancelTokens[tempId] = cancelToken;
    try {
      String? imageUrl;
      String? videoUrl;
      String? voiceUrl;

      if (imageFile != null) {
        if (await imageFile.exists()) {
          imageUrl = await _chatServices.uploadChatFile(
            imageFile,
            'image',
            cancelToken: cancelToken,
            onProgress: (progress) {
              uploadProgressMap[tempId] = progress;
              emit(MessagesSending(messages: updatedMessages));
            },
          );
          uploadProgressMap[tempId] = 1.0;
          emit(MessagesSending(messages: updatedMessages));
          await Future.delayed(const Duration(milliseconds: 200));
          uploadProgressMap.remove(tempId);
        } else {
          emit(
            MessagesError("Image file not found. Please try picking it again."),
          );
          emit(MessagesSuccessLoaded(messages: currentMessages));
        }
      }

      if (videoFile != null) {
        if (await videoFile.exists()) {
          videoUrl = await _chatServices.uploadChatFile(
            videoFile,
            'video',
            cancelToken: cancelToken,
            onProgress: (progress) {
              uploadProgressMap[tempId] = progress;
              emit(MessagesSending(messages: updatedMessages));
            },
          );
          uploadProgressMap[tempId] = 1.0;
          emit(MessagesSending(messages: updatedMessages));
          await Future.delayed(const Duration(milliseconds: 200));
          uploadProgressMap.remove(tempId);
        } else {
          emit(MessagesError("Video file not found. Please try again."));
          emit(MessagesSuccessLoaded(messages: currentMessages));
          return;
        }
      }

      if (voiceFile != null) {
        if (await voiceFile.exists()) {
          voiceUrl = await _chatServices.uploadChatFile(voiceFile, 'voice');
        } else {
          emit(MessagesError("Voice file not found."));
          return;
        }
      }

      await _chatServices.sendMessage(
        senderId: currentUserId,
        receiverId: receiverId,
        text: messageText,
        messageType: messageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        voiceUrl: voiceUrl,
        caption: caption,
        replyToMessageId: replyTo?.id,
        replyToText: _getReplyPreviewText(replyTo),
        replyToMessageType: replyTo?.messageType,
        replyToSenderId: replyTo?.senderId,
      );
      _cancelTokens.remove(tempId);

      _sendPushNotification(
        receiverId: receiverId,
        messageText: caption ?? messageText,
        messageType: messageType,
        attachmentUrl: imageUrl ?? videoUrl,
      );
    } catch (e) {
      _cancelTokens.remove(tempId);

      if (e is dio_pkg.DioException &&
          e.type == dio_pkg.DioExceptionType.cancel) {
        debugPrint("User canceled the upload");
        return;
      }
      debugPrint('error sending message: $e');
      emit(
        MessagesError("Failed to send message. Please check your connection."),
      );

      emit(MessagesSuccessLoaded(messages: currentMessages));

      uploadProgressMap.remove(tempId);
    }
  }

  // ignore: unused_field
  String _resolvedCurrentUserName = '';
  // ignore: unused_field
  String _resolvedSenderImageUrl = '';

  Future<void> loadCurrentUserInfo() async {
    try {
      final info = await _chatServices.getCurrentUserInfo(currentUserId);
      _resolvedCurrentUserName = info['name'] ?? currentUserName;
      _resolvedSenderImageUrl = info['imageUrl'] ?? senderImageUrl ?? '';
    } catch (_) {}
  }

  Future<void> _sendPushNotification({
    required String receiverId,
    required String messageText,
    required String messageType,
    String? attachmentUrl,
  }) async {
    try {
      final receiverInfo = await _chatServices.getReceiverPushInfo(receiverId);

      if (receiverInfo == null) {
        debugPrint('ℹ️  No FCM token for receiver — skipping notification');
        return;
      }

      await FcmService.instance.sendChatNotification(
        receiverFcmToken: receiverInfo.fcmToken,
        senderId: currentUserId,
        senderName:
            _resolvedCurrentUserName.isNotEmpty
                ? _resolvedCurrentUserName
                : currentUserName,
        senderImageUrl:
            _resolvedSenderImageUrl.isNotEmpty
                ? _resolvedSenderImageUrl
                : (senderImageUrl ?? ''),
        messageBody: messageText,
        messageType: messageType,
        attachmentUrl: attachmentUrl,
      );
    } catch (e) {
      debugPrint('⚠️  _sendPushNotification silent error: $e');
    }
  }

  final Map<String, dio_pkg.CancelToken> _cancelTokens = {};
  void cancelUpload(String tempId) {
    if (_cancelTokens.containsKey(tempId)) {
      _cancelTokens[tempId]!.cancel();
      _cancelTokens.remove(tempId);
      uploadProgressMap.remove(tempId);

      if (state is MessagesSending) {
        final currentList = (state as MessagesSending).messages;
        final updatedList = currentList!.where((m) => m.id != tempId).toList();
        emit(MessagesSuccessLoaded(messages: updatedList));
      }
    }
  }

  void setReplyMessage(MessageModel message) {
    replyToMessage.value = message;
  }

  void cancelReply() {
    replyToMessage.value = null;
  }

  String? _getReplyPreviewText(MessageModel? msg) {
    if (msg == null) return null;
    switch (msg.messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      default:
        final text = msg.caption ?? msg.text;
        return text.length > 60 ? '${text.substring(0, 60)}...' : text;
    }
  }

  int? findMessageIndex(String messageId) {
    final index = cachedMessages.indexWhere((m) => m.id == messageId);
    return index == -1 ? null : index;
  }

  final ValueNotifier<String?> highlightedMessageId = ValueNotifier(null);

  Future<void> scrollToMessage({
    required String messageId,
    required ItemScrollController itemScrollController,
  }) async {
    final index = cachedMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    await itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      alignment: 0.3,
    );

    highlightedMessageId.value = messageId;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!isClosed) highlightedMessageId.value = null;
    });
  }

  Future<void> deleteMessage({
    required String messageId,
    required String receiverId,
  }) async {
    try {
      await _chatServices.deleteMessage(messageId: messageId);
    } catch (e) {
      debugPrint('error deleting message: $e');
      emit(MessagesError(e.toString()));
    }
  }

  Future<void> addReaction({
    required String messageId,
    required String reaction,
    required String? currentReaction,
  }) async {
    try {
      await _chatServices.addReaction(
        messageId: messageId,
        reaction: reaction,
        currentReaction: currentReaction ?? '',
      );
    } catch (e) {
      debugPrint('error adding reaction: $e');
      emit(MessagesError(e.toString()));
    }
  }

  Future<void> updateLastSeen() async {
    try {
      await _chatServices.updateLastSeen(currentUserId);
    } catch (e) {
      debugPrint('error updating last seen: $e');
      emit(MessagesError(e.toString()));
    }
  }

  void watchReceiverLastSeen(String receiverId, {DateTime? initialLastSeen}) {
    _lastSeenSubscription?.cancel();
    _lastSeenPollingTimer?.cancel();

    // _chatServices.getUserLastSeen(receiverId).then((lastSeen) {
    //   if (!isClosed) emit(LastSeenUpdated(lastSeen));
    // });
    if (initialLastSeen != null) {
      emit(LastSeenUpdated(initialLastSeen));
    }

    _lastSeenSubscription = _chatServices.getLastSeenStream(receiverId).listen((
      lastSeen,
    ) {
      if (!isClosed) emit(LastSeenUpdated(lastSeen));
    });

    _lastSeenPollingTimer = Timer.periodic(const Duration(seconds: 45), (
      _,
    ) async {
      final lastSeen = await _chatServices.getUserLastSeen(receiverId);
      if (!isClosed) emit(LastSeenUpdated(lastSeen));
    });
  }

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
    highlightedMessageId.dispose();

    _messageSubscription?.cancel();
    _lastSeenSubscription?.cancel();
    _lastSeenPollingTimer?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    return super.close();
  }
}
