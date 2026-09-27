import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/helpers/chat_helper.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../../core/presence/models/chat_action_type.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../../auth/handlers/auth_exception_handler.dart';
import '../../helpers/chat_clear_store.dart';
part 'chats_state.dart';

const int kMaxCachedChatsSnapshot = 50;

class ChatsCubit extends Cubit<ChatsState>
    with WidgetsBindingObserver, SafeEmitMixin<ChatsState> {
  final ChatServices _chatServices;
  final _currentUserId = SupabaseProvider.id;
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _actionsSubscription;
  RealtimeChannel? _reactionsChannel;
  Timer? _refreshDebounce;

  List<ChatUserModel> _cachedChats = [];
  List<ChatUserModel> get cachedChats => _cachedChats;
  Map<String, ChatActionType> _actionsByUserId = {};

  bool _showSkeleton = true;

  bool get showSkeleton => _showSkeleton;

  ChatsCubit(this._chatServices) : super(ChatsInitial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getChats(isRefresh: true);
    }
  }

  ChatActionType actionFor(String otherUserId) =>
      _actionsByUserId[otherUserId] ?? ChatActionType.none;

  void monitorChats() {
    getChats();
    _chatsSubscription?.cancel();

    _listenToChatsStream();
    _listenToActionsStream();
    _listenToReactionsStream();
  }

  void _listenToReactionsStream() {
    _reactionsChannel?.unsubscribe();

    final channelName = 'public:message_reactions_overview_$_currentUserId';
    _reactionsChannel =
        SupabaseProvider.client.channel(channelName)
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: SupabaseConstants.messageReactions,
            callback: (payload) {
              _refreshDebounce?.cancel();
              _refreshDebounce = Timer(const Duration(milliseconds: 100), () {
                getChats(isRefresh: true, silent: true);
              });
            },
          )
          ..subscribe();
  }

  void _listenToChatsStream() {
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatServices.getChatsStream(_currentUserId).listen((
      _,
    ) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 100), () {
        getChats(isRefresh: true, silent: true);
      });
    }, onError: (error) => debugPrint('Stream Error: $error'));
  }

  void _listenToActionsStream() {
    _actionsSubscription?.cancel();
    _actionsSubscription = _chatServices
        .getGlobalActionsStream(_currentUserId)
        .listen((actionsByUserId) {
          _actionsByUserId = actionsByUserId;
          _emitWithPresence();
        });
  }

  void _emitWithPresence() {
    if (isClosed || _cachedChats.isEmpty) return;

    final updatedChats =
        _cachedChats.map((chat) {
          final action = actionFor(chat.id);
          final isTyping = action == ChatActionType.typing;
          final isRecording = action == ChatActionType.recording;

          if (chat.isTyping == isTyping && chat.isRecording == isRecording) {
            return chat;
          }
          return chat.copyWith(isTyping: isTyping, isRecording: isRecording);
        }).toList();

    emit(ChatsSuccessloaded(chats: updatedChats));
  }

  // ─── Local-only "Delete Chat" (multi-select) ───────────────────────────

  bool _isHiddenByLocalClear(ChatUserModel chat) {
    final clearedAt = ChatClearStore.instance.clearedAtFor(chat.id);
    if (clearedAt == null) return false;
    final lastMsgAt = chat.lastMessageTime;
    if (lastMsgAt != null && lastMsgAt.isAfter(clearedAt)) return false;
    return true;
  }

  Future<void> clearChatsLocally(Set<String> otherUserIds) async {
    if (otherUserIds.isEmpty) return;

    await ChatClearStore.instance.setClearedNow(otherUserIds);

    for (final otherUserId in otherUserIds) {
      final conversationId = ChatHelper.buildConversationId(
        _currentUserId,
        otherUserId,
      );
      await LocalSnapshotStore.instance.clear(
        'chat_messages_snapshot_$conversationId',
      );
    }

    if (isClosed) return;

    final newList =
        _cachedChats.where((c) => !otherUserIds.contains(c.id)).toList();
    _cachedChats = newList;
    emit(ChatsSuccessloaded(chats: newList));
    _persistChatsSnapshot(newList);
  }

  void updateChatLastMessagePreview({
    required String otherUserId,
    required String lastMessage,
    required String lastMessageType,
    required DateTime lastMessageTime,
    required bool lastMessageIsMe,
  }) {
    if (isClosed) return;

    final idx = _cachedChats.indexWhere((c) => c.id == otherUserId);
    if (idx == -1) {
      getChats(isRefresh: true, silent: true);
      return;
    }

    final updatedList = List<ChatUserModel>.from(_cachedChats);
    updatedList[idx] = updatedList[idx].copyWith(
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageTime: lastMessageTime,
      lastMessageIsMe: lastMessageIsMe,
    );

    updatedList.sort((a, b) {
      final aTime = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    _cachedChats = updatedList;
    _emitWithPresence();
    _persistChatsSnapshot(updatedList);
  }

  Future<void> getChats({bool isRefresh = false, bool silent = false}) async {
    if (isClosed) return;
    if (!isRefresh && !silent) {
      _showSkeleton = true;
      emit(ChatsLoading());
    }
    try {
      final start = DateTime.now();

      final fetchedChats = await _chatServices.getChatsList(_currentUserId);

      if (isClosed) return;

      final chats =
          fetchedChats.where((c) => !_isHiddenByLocalClear(c)).toList();
      _cachedChats = chats;
      _showSkeleton = false;

      if (isRefresh && !silent) {
        emit(ChatsRefreshFeedback());
        final elapsed = DateTime.now().difference(start);
        if (elapsed < const Duration(milliseconds: 500)) {
          await Future.delayed(const Duration(milliseconds: 500) - elapsed);
        }
        if (isClosed) return;
      }
      _emitWithPresence();
      _persistChatsSnapshot(chats);
    } catch (e) {
      if (isClosed) return;

      _showSkeleton = false;
      if (e.toString().contains('no-internet')) {
        if (_cachedChats.isNotEmpty) {
          debugPrint('Silent error: No internet, but showing cached chats.');
          return;
        }
        final diskChats = _readChatsSnapshot();
        if (diskChats.isNotEmpty) {
          debugPrint(
            'Silent error: No internet, showing chats snapshot from disk.',
          );
          _cachedChats = diskChats;
          if (!isClosed) emit(ChatsSuccessloaded(chats: diskChats));
          return;
        }
        if (!isClosed) {
          emit(
            ChatsError("No internet connection. Please check your network."),
          );
        }
      } else {
        if (!isClosed) emit(ChatsError(AuthExceptionHandler.handle(e)));
      }
      debugPrint('Error in getChats Cubit: $e');
    }
  }

  void _persistChatsSnapshot(List<ChatUserModel> chats) {
    unawaited(
      LocalSnapshotStore.instance.saveList(
        SnapshotKeys.chats,
        chats
            .take(kMaxCachedChatsSnapshot)
            .map((chat) => chat.toCacheJson())
            .toList(),
      ),
    );
  }

  List<ChatUserModel> _readChatsSnapshot() {
    try {
      return LocalSnapshotStore.instance
          .readList(SnapshotKeys.chats)
          .map(ChatUserModel.fromCacheJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to read chats snapshot from disk: $e');
      return [];
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _chatsSubscription?.cancel();
    _actionsSubscription?.cancel();
    _refreshDebounce?.cancel();
    return super.close();
  }
}
