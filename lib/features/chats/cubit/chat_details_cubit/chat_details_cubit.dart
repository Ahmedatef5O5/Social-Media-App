import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message_model.dart';
import '../../services/chat_services.dart';
part 'chat_details_state.dart';

class ChatDetailsCubit extends Cubit<ChatDetailsState> {
  final ChatServices _chatServices;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _lastSeenSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingDebounce;
  Timer? _lastSeenPollingTimer;

  List<MessageModel> cachedMessages = [];

  final currentUserId = Supabase.instance.client.auth.currentUser!.id;

  ChatDetailsCubit(this._chatServices) : super(ChatDetailsInitial());

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

  void watchReceiverLastSeen(String receiverId) {
    _lastSeenSubscription?.cancel();
    _lastSeenSubscription = _chatServices
        .getLastSeenStream(receiverId)
        .listen((lastSeen) => emit(LastSeenUpdated(lastSeen)));

    _lastSeenPollingTimer = Timer.periodic(const Duration(seconds: 10), (
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
    _messageSubscription?.cancel();
    _lastSeenSubscription?.cancel();
    _lastSeenPollingTimer?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    return super.close();
  }
}
