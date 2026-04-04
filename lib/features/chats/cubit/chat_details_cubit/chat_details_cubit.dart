import 'dart:async';
import 'dart:io';
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
          markAsRead(senderId: receiverId);
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

    emit(MessagesSending(messages: currentMessages));
    try {
      String? imageUrl;
      String? videoUrl;
      String? voiceUrl;
      if (imageFile != null) {
        imageUrl = await _chatServices.uploadChatFile(imageFile, 'image');
      }

      if (videoFile != null) {
        if (await videoFile.exists()) {
          videoUrl = await _chatServices.uploadChatFile(videoFile, 'video');
        } else {
          debugPrint('File does not exist at path: ${videoFile.path}');
        }
      }

      if (voiceFile != null) {
        voiceUrl = await _chatServices.uploadChatFile(voiceFile, 'voice');
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
    } catch (e) {
      debugPrint('error sending message: $e');
      emit(MessagesError(e.toString()));
      emit(MessagesSuccessLoaded(messages: currentMessages));
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
