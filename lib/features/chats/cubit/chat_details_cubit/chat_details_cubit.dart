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
  ChatDetailsCubit(this._chatServices) : super(ChatDetailsInitial());
  final _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  void getMessagesStream({required String receiverId}) {
    _messageSubscription?.cancel();
    _messageSubscription = _chatServices
        .getMessagesStream(senderId: _currentUserId, receiverId: receiverId)
        .listen((messages) {
          emit(MessagesSuccessLoaded(messages: messages));
          bool hasUnread = messages.any(
            (m) => !m.isRead && m.receiverId == _currentUserId,
          );
          if (hasUnread) {
            markAsRead(senderId: receiverId);
          }
        });
  }

  Future<void> markAsRead({required String senderId}) async {
    try {
      await _chatServices.markMessagesAsRead(
        senderId: senderId,
        currentUserId: _currentUserId,
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
  }) async {
    if (messageText.trim().isEmpty &&
        imageFile == null &&
        videoFile == null &&
        voiceFile == null) {
      return;
    }
    List<MessageModel> currentMessages = [];

    if (state is MessagesSuccessLoaded) {
      currentMessages = (state as MessagesSuccessLoaded).messages;
    }

    // optimistic Message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      senderId: _currentUserId,
      receiverId: receiverId,
      text: messageText,
      messageType: messageType,
      createdAt: DateTime.now(),
      isRead: false,
      voiceUrl: voiceFile?.path,
    );

    final updatedMessages = [optimisticMessage, ...currentMessages];
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
        senderId: _currentUserId,
        receiverId: receiverId,
        text: messageText,
        messageType: messageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        voiceUrl: voiceUrl,
        caption: caption,
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
      await _chatServices.updateLastSeen(_currentUserId);
    } catch (e) {
      debugPrint('error updating last seen: $e');
      emit(MessagesError(e.toString()));
    }
  }

  StreamSubscription? _lastSeenSubscription;

  void watchReceiverLastSeen(String receiverId) {
    _lastSeenSubscription?.cancel();
    _lastSeenSubscription = _chatServices
        .getLastSeenStream(receiverId)
        .listen((lastSeen) => emit(LastSeenUpdated(lastSeen)));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _lastSeenSubscription?.cancel();
    return super.close();
  }
}
