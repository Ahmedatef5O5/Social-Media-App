import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/services/supabase_storage_services.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../models/message_model.dart';
import '../../models/presence_snapshot.dart';
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
  StreamSubscription? _presenceSubscription;

  StreamSubscription? _typingSubscription;
  Timer? _typingDebounce;
  Timer? _lastSeenPollingTimer;

  PresenceSnapshot? _lastPresence;

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

  // ignore: unused_field
  bool _isUserAtBottom = true;

  void setUserAtBottom(bool isAtBottom) {
    _isUserAtBottom = isAtBottom;
  }

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
        });
  }

  Future<void> markAsRead({required String senderId}) async {
    // if (!_isUserAtBottom) return;
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
          imageUrl = await _chatServices.storage.uploadFile(
            imageFile,
            'chats',
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
          videoUrl = await _chatServices.storage.uploadFile(
            videoFile,
            'chats',
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
          voiceUrl = await _chatServices.storage.uploadFile(
            voiceFile,
            'chats',
            'voice',
            cancelToken: cancelToken,
          );
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
      if (messageType != 'call') {
        await NotificationRepository.instance.notifyChatMessage(
          receiverId: receiverId,
          senderId: currentUserId,
          senderName:
              _resolvedCurrentUserName.isNotEmpty
                  ? _resolvedCurrentUserName
                  : currentUserName,
          senderImageUrl:
              _resolvedSenderImageUrl.isNotEmpty
                  ? _resolvedSenderImageUrl
                  : (senderImageUrl ?? ''),
          messageBody: caption ?? messageText,
          messageType: messageType,
          chatReferenceId: currentUserId,
        );
      }
      _cancelTokens.remove(tempId);

      _sendPushNotification(
        receiverId: receiverId,
        messageText: caption ?? messageText,
        messageType: messageType,
        attachmentUrl: imageUrl ?? videoUrl,
      );
    } on UploadCanceledException {
      return;
    } catch (e) {
      _cancelTokens.remove(tempId);

      if (e is dio_pkg.DioException &&
          e.type == dio_pkg.DioExceptionType.cancel) {
        debugPrint("User canceled the upload");
        return;
      }
      if (e.toString().contains('session_expired')) {
        emit(MessagesError('Your session has expired; please log in again'));
        return;
      } else {
        debugPrint('Error uploading file: $e');

        _cancelTokens.remove(tempId);
        uploadProgressMap.remove(tempId);

        cachedMessages.removeWhere((m) => m.id == tempId);

        emit(MessagesSuccessLoaded(messages: List.from(cachedMessages)));
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
    highlightedMessageId.dispose();

    _messageSubscription?.cancel();
    _presenceSubscription?.cancel();
    _lastSeenPollingTimer?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    return super.close();
  }
}
