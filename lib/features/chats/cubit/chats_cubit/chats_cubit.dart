import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/services/chat_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/handler/auth_exception_handler.dart';
part 'chats_state.dart';

class ChatsCubit extends Cubit<ChatsState> {
  final ChatServices _chatServices;
  final _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _refreshDebounce;

  List<ChatUserModel> _cachedChats = [];
  List<String> _typingUserIds = [];

  bool _showSkeleton = true;

  bool get showSkeleton => _showSkeleton;

  ChatsCubit(this._chatServices) : super(ChatsInitial());

  void monitorChats() {
    getChats();
    _chatsSubscription?.cancel();

    _listenToChatsStream();
    _listenToTypingStream();
  }

  void _listenToChatsStream() {
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatServices.getChatsStream(_currentUserId).listen((
      _,
    ) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 100), () {
        getChats(isRefresh: true);
      });
    }, onError: (error) => debugPrint('Stream Error: $error'));
  }

  void _listenToTypingStream() {
    _typingSubscription?.cancel();
    _typingSubscription = _chatServices
        .getTypingUsersStream(_currentUserId)
        .listen((typingUserIds) {
          _typingUserIds = typingUserIds;
          _emitWithTyping();
        });
  }

  void _emitWithTyping() {
    if (_cachedChats.isEmpty) return;

    final updatedChats =
        _cachedChats.map((chat) {
          final isTyping = _typingUserIds.contains(chat.id);

          if (chat.isTyping == isTyping) return chat;
          return chat.copyWith(isTyping: isTyping);
        }).toList();

    emit(ChatsSuccessloaded(chats: updatedChats));
  }

  Future<void> getChats({bool isRefresh = false}) async {
    if (!isRefresh) {
      _showSkeleton = true;
      emit(ChatsLoading());
    }
    try {
      final start = DateTime.now();

      final chats = await _chatServices.getChatsList(_currentUserId);
      _cachedChats = chats;
      _showSkeleton = false;

      if (isRefresh) {
        emit(ChatsRefreshFeedback());
        final elapsed = DateTime.now().difference(start);
        if (elapsed < const Duration(milliseconds: 500)) {
          await Future.delayed(const Duration(milliseconds: 500) - elapsed);
        }
      }
      _emitWithTyping();
    } catch (e) {
      _showSkeleton = false;
      if (e.toString().contains('no-internet')) {
        if (_cachedChats.isNotEmpty) {
          debugPrint('Silent error: No internet, but showing cached chats.');
          return;
        }
        emit(ChatsError("No internet connection. Please check your network."));
      } else {
        emit(ChatsError(AuthExceptionHandler.handle(e)));
      }
      debugPrint('Error in getChats Cubit: $e');
    }
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    _typingSubscription?.cancel();
    _refreshDebounce?.cancel();
    return super.close();
  }
}
