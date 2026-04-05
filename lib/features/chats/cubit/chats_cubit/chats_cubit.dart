import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/services/chat_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'chats_state.dart';

class ChatsCubit extends Cubit<ChatsState> {
  final ChatServices _chatServices;
  final _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  StreamSubscription? _chatsSubscription;

  ChatsCubit(this._chatServices) : super(ChatsInitial());

  void monitorChats() {
    getChats();
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatServices.getChatsStream(_currentUserId).listen((
      data,
    ) {
      getChats(isRefresh: true);
    }, onError: (error) => debugPrint('Stream Error Detail : $error'));
  }

  Future<void> getChats({bool isRefresh = false}) async {
    if (!isRefresh) emit(ChatsLoading());
    try {
      final chats = await _chatServices.getChatsList(_currentUserId);
      emit(ChatsSuccessloaded(chats: chats));
    } catch (e) {
      debugPrint('Error getting chats: $e');
      emit(ChatsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}
