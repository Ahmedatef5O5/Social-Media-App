import 'dart:async';
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
        .listen((messages) => emit(MessagesSuccessLoaded(messages: messages)));
  }

  Future<void> sendMessage({
    required String receiverId,
    required String messageText,
  }) async {
    if (messageText.trim().isEmpty) return;
    try {
      await _chatServices.sendMessage(
        senderId: _currentUserId,
        receiverId: receiverId,
        text: messageText,
      );
    } catch (e) {
      debugPrint('error sending message: $e');
      emit(MessagesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
