import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/helpers/chat_helper.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../../core/observability/realtime_diagnostics.dart';
import '../../../../core/presence/models/chat_action_type.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../../auth/handlers/auth_exception_handler.dart';
import '../../../settings/repository/settings_repository.dart';
import '../../helpers/chat_clear_store.dart';
part 'chats_state.dart';

const int kMaxCachedChatsSnapshot = 50;
const String _kSingleChatReadWatermarksKey =
    'local_single_chat_read_watermarks';

class ChatsCubit extends Cubit<ChatsState>
    with WidgetsBindingObserver, SafeEmitMixin<ChatsState> {
  static int _reactionsEpoch = 0;

  final ChatServices _chatServices;
  String get _currentUserId => SupabaseProvider.idOrNull ?? '';
  StreamSubscription<PostgresChangePayload>? _chatsSubscription;
  StreamSubscription? _actionsSubscription;
  RealtimeChannel? _reactionsChannel;
  Timer? _reactionsRetryTimer;
  Timer? _refreshDebounce;
  Timer? _activePeerClearTimer;

  String? _activePeerId;
  String? get activePeerId => _activePeerId;

  final Set<String> _pendingMarkReadPeers = <String>{};
  final Map<String, DateTime> _readWatermarkByPeer = <String, DateTime>{};
  bool _watermarksLoaded = false;
  int _getChatsRequestId = 0;

  final Queue<String> _processedInsertIds = Queue<String>();

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
      getChats(isRefresh: true, silent: true);
    }
  }

  ChatActionType actionFor(String otherUserId) =>
      _actionsByUserId[otherUserId] ?? ChatActionType.none;

  void _ensureWatermarksLoaded() {
    if (_watermarksLoaded) return;
    _watermarksLoaded = true;
    final raw = LocalSnapshotStore.instance.readObject(
      _kSingleChatReadWatermarksKey,
    );
    if (raw == null) return;
    raw.forEach((peerId, iso) {
      if (iso is String) {
        final parsed = DateTime.tryParse(iso);
        if (parsed != null) _readWatermarkByPeer[peerId] = parsed;
      }
    });
  }

  void _recordReadWatermark(String otherUserId, DateTime? serverTime) {
    if (serverTime == null) return;
    _ensureWatermarksLoaded();
    final prev = _readWatermarkByPeer[otherUserId];
    if (prev == null || serverTime.isAfter(prev)) {
      _readWatermarkByPeer[otherUserId] = serverTime;
      unawaited(
        LocalSnapshotStore.instance.saveObject(
          _kSingleChatReadWatermarksKey,
          _readWatermarkByPeer.map((k, v) => MapEntry(k, v.toIso8601String())),
        ),
      );
    }
  }

  void setActiveChatPeerId(String? peerId) {
    _activePeerClearTimer?.cancel();
    if (peerId == null) {
      _activePeerClearTimer = Timer(const Duration(milliseconds: 800), () {
        _activePeerId = null;
      });
    } else {
      _activePeerId = peerId;
      resetChatUnreadCount(peerId);
    }
  }

  void beginMarkPeerRead(String otherUserId, {DateTime? upToServerTime}) {
    _pendingMarkReadPeers.add(otherUserId);
    resetChatUnreadCount(otherUserId, upToServerTime: upToServerTime);
  }

  void endMarkPeerRead(String otherUserId) {
    _pendingMarkReadPeers.remove(otherUserId);
  }

  void resetChatUnreadCount(String otherUserId, {DateTime? upToServerTime}) {
    if (isClosed) return;
    final idx = _cachedChats.indexWhere((c) => c.id == otherUserId);
    final effectiveWatermark =
        upToServerTime ??
        (idx != -1 ? _cachedChats[idx].lastMessageTime : null);
    _recordReadWatermark(otherUserId, effectiveWatermark);

    if (idx == -1 || _cachedChats[idx].unreadCount == 0) return;

    final updatedList = List<ChatUserModel>.from(_cachedChats);
    updatedList[idx] = updatedList[idx].copyWith(unreadCount: 0);
    _cachedChats = updatedList;
    _emitWithPresence();
    _persistChatsSnapshot(updatedList);
  }

  int _effectiveUnreadCountFor(ChatUserModel serverChat) {
    _ensureWatermarksLoaded();
    if (serverChat.unreadCount == 0) {
      _pendingMarkReadPeers.remove(serverChat.id);
      return 0;
    }

    if (_activePeerId == serverChat.id) {
      _recordReadWatermark(serverChat.id, serverChat.lastMessageTime);
      return 0;
    }

    final watermark = _readWatermarkByPeer[serverChat.id];

    if (_pendingMarkReadPeers.contains(serverChat.id)) {
      if (watermark == null ||
          serverChat.lastMessageTime == null ||
          !serverChat.lastMessageTime!.isAfter(watermark)) {
        return 0;
      }
    }

    if (!SettingsRepository.instance.readReceipts) {
      if (watermark != null &&
          serverChat.lastMessageTime != null &&
          !serverChat.lastMessageTime!.isAfter(watermark)) {
        return 0;
      }
    }

    return serverChat.unreadCount;
  }

  void monitorChats() {
    if (SupabaseProvider.idOrNull == null) return;
    getChats();
    _chatsSubscription?.cancel();

    _listenToChatsStream();
    _listenToActionsStream();
    _listenToReactionsStream();
  }

  void _scheduleSilentRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!isClosed) {
        getChats(isRefresh: true, silent: true);
      }
    });
  }

  void _listenToReactionsStream() {
    _reactionsRetryTimer?.cancel();
    int retryAttempt = 0;
    bool hadError = false;

    void subscribeReactions() {
      if (isClosed || _currentUserId.isEmpty) return;
      if (_reactionsChannel != null) {
        final old = _reactionsChannel!;
        _reactionsChannel = null;
        RealtimeDiagnostics.instance.onChannelClosed(old.topic);
        unawaited(SupabaseProvider.client.removeChannel(old));
      }

      final channelName =
          'message_reactions_overview_${_currentUserId}_${++_reactionsEpoch}';
      final channel = SupabaseProvider.client.channel(channelName);
      _reactionsChannel = channel;
      final topic = channel.topic;

      RealtimeDiagnostics.instance.onChannelCreated(
        topic,
        ownerUserId: _currentUserId,
      );

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: SupabaseConstants.messageReactions,
            callback: (_) => _scheduleSilentRefresh(),
          )
          .subscribe((status, [error]) {
            if (isClosed || !identical(_reactionsChannel, channel)) return;
            switch (status) {
              case RealtimeSubscribeStatus.subscribed:
                retryAttempt = 0;
                RealtimeDiagnostics.instance.onChannelSubscribed(topic);
                if (hadError) {
                  hadError = false;
                  _scheduleSilentRefresh();
                }
              case RealtimeSubscribeStatus.channelError:
              case RealtimeSubscribeStatus.timedOut:
                hadError = true;
                final isNormalClose =
                    error is RealtimeCloseEvent &&
                    (error.code == 1000 || error.code == 1001);
                if (!isNormalClose) {
                  RealtimeDiagnostics.instance.onChannelError(
                    topic,
                    error ?? status,
                    StackTrace.current,
                  );
                }
                _reactionsRetryTimer?.cancel();
                final delaySeconds = (1 << retryAttempt.clamp(0, 3)) * 2;
                retryAttempt++;
                _reactionsRetryTimer = Timer(
                  Duration(seconds: delaySeconds),
                  subscribeReactions,
                );
              case RealtimeSubscribeStatus.closed:
                break;
            }
          });
    }

    subscribeReactions();
  }

  void _listenToChatsStream() {
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatServices
        .getChatsStream(
          _currentUserId,
          onReconnected: () => _scheduleSilentRefresh(),
        )
        .listen((payload) {
          _applyRealtimeMessagePayload(payload);
          _scheduleSilentRefresh();
        }, onError: (error) => debugPrint('Stream Error: $error'));
  }

  void _applyRealtimeMessagePayload(PostgresChangePayload payload) {
    if (isClosed || _currentUserId.isEmpty) return;

    if (payload.eventType == PostgresChangeEvent.insert) {
      final row = payload.newRecord;
      final msgId = row[MessagesColumns.id]?.toString();
      if (msgId != null && msgId.isNotEmpty) {
        if (_processedInsertIds.contains(msgId)) return;
        _processedInsertIds.addLast(msgId);
        while (_processedInsertIds.length > 100) {
          _processedInsertIds.removeFirst();
        }
      }

      final senderId = row[MessagesColumns.senderId]?.toString();
      final receiverId = row[MessagesColumns.receiverId]?.toString();
      if (senderId == null || receiverId == null) return;

      final deletedFor =
          (row[MessagesColumns.deletedFor] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      if (deletedFor.contains(_currentUserId)) return;

      final isMe = senderId == _currentUserId;
      final otherUserId = isMe ? receiverId : senderId;
      final idx = _cachedChats.indexWhere((c) => c.id == otherUserId);
      if (idx == -1) return;

      final messageType =
          row[MessagesColumns.messageType]?.toString() ?? 'text';
      final rawText = row[MessagesColumns.messageText]?.toString() ?? '';
      final fileName = row[MessagesColumns.fileName]?.toString();
      final caption = row[MessagesColumns.caption]?.toString();
      final preview =
          (messageType == 'file' || messageType == 'document')
              ? ((fileName != null && fileName.isNotEmpty) ? fileName : rawText)
              : (rawText.isNotEmpty ? rawText : (caption ?? ''));

      final createdAt =
          DateTime.tryParse(row[MessagesColumns.createdAt]?.toString() ?? '') ??
          DateTime.now();
      final isRead = row[MessagesColumns.isRead] as bool? ?? false;

      final existing = _cachedChats[idx];
      final isActive = _activePeerId == otherUserId;
      if (isActive) {
        _recordReadWatermark(otherUserId, createdAt);
      }

      final nextUnread =
          isMe
              ? existing.unreadCount
              : (isActive || isRead ? 0 : existing.unreadCount + 1);

      final isNewerOrEqual =
          existing.lastMessageTime == null ||
          !createdAt.isBefore(existing.lastMessageTime!);

      final updatedList = List<ChatUserModel>.from(_cachedChats);
      updatedList[idx] =
          isNewerOrEqual
              ? existing.copyWith(
                lastMessage: preview,
                lastMessageType: messageType,
                lastMessageTime: createdAt,
                lastMessageIsMe: isMe,
                lastMessageIsRead: isRead,
                unreadCount: nextUnread,
              )
              : existing.copyWith(unreadCount: nextUnread);

      updatedList.sort((a, b) {
        final aTime =
            a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      _cachedChats = updatedList;
      _emitWithPresence();
      _persistChatsSnapshot(updatedList);
      return;
    }

    if (payload.eventType == PostgresChangeEvent.update) {
      final row = payload.newRecord;
      final old = payload.oldRecord;
      final senderId = row[MessagesColumns.senderId]?.toString();
      final receiverId = row[MessagesColumns.receiverId]?.toString();
      if (senderId == null || receiverId == null) return;

      final isMe = senderId == _currentUserId;
      final otherUserId = isMe ? receiverId : senderId;
      final idx = _cachedChats.indexWhere((c) => c.id == otherUserId);
      if (idx == -1) return;

      final existing = _cachedChats[idx];
      int nextUnread = existing.unreadCount;
      bool nextIsRead = existing.lastMessageIsRead;
      String? nextMessage = existing.lastMessage;

      final nowRead = row[MessagesColumns.isRead] as bool? ?? false;
      final wasRead = old[MessagesColumns.isRead] as bool? ?? false;

      if (!isMe && nowRead && !wasRead && nextUnread > 0) {
        nextUnread = (nextUnread - 1).clamp(0, 999999);
      }
      if (isMe && existing.lastMessageIsMe && nowRead && !nextIsRead) {
        nextIsRead = true;
      }

      final createdAt = DateTime.tryParse(
        row[MessagesColumns.createdAt]?.toString() ?? '',
      );
      if (createdAt != null &&
          existing.lastMessageTime != null &&
          createdAt.isAtSameMomentAs(existing.lastMessageTime!)) {
        final messageType =
            row[MessagesColumns.messageType]?.toString() ??
            existing.lastMessageType ??
            'text';
        final rawText = row[MessagesColumns.messageText]?.toString() ?? '';
        final fileName = row[MessagesColumns.fileName]?.toString();
        final caption = row[MessagesColumns.caption]?.toString();
        nextMessage =
            (messageType == 'file' || messageType == 'document')
                ? ((fileName != null && fileName.isNotEmpty)
                    ? fileName
                    : rawText)
                : (rawText.isNotEmpty ? rawText : (caption ?? ''));
      }

      if (nextUnread != existing.unreadCount ||
          nextIsRead != existing.lastMessageIsRead ||
          nextMessage != existing.lastMessage) {
        final updatedList = List<ChatUserModel>.from(_cachedChats);
        updatedList[idx] = existing.copyWith(
          unreadCount: nextUnread,
          lastMessageIsRead: nextIsRead,
          lastMessage: nextMessage,
        );
        _cachedChats = updatedList;
        _emitWithPresence();
        _persistChatsSnapshot(updatedList);
      }
    }
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
    if (isClosed || (_showSkeleton && _cachedChats.isEmpty)) return;

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
    bool? lastMessageIsRead,
    int? unreadCount,
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
      lastMessageIsRead:
          lastMessageIsRead ??
          (lastMessageIsMe ? false : updatedList[idx].lastMessageIsRead),
      unreadCount: unreadCount ?? updatedList[idx].unreadCount,
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
    if (SupabaseProvider.idOrNull == null) return;
    if (isClosed) return;
    final requestId = ++_getChatsRequestId;

    if (!isRefresh && !silent) {
      _showSkeleton = true;
      emit(ChatsLoading());
    }
    try {
      final start = DateTime.now();

      final fetchedChats = await _chatServices.getChatsList(_currentUserId);

      if (isClosed || requestId != _getChatsRequestId) return;

      final chats =
          fetchedChats
              .where((c) => !_isHiddenByLocalClear(c))
              .map((c) => c.copyWith(unreadCount: _effectiveUnreadCountFor(c)))
              .toList();
      _cachedChats = chats;
      _showSkeleton = false;

      if (isRefresh && !silent) {
        emit(ChatsRefreshFeedback());
        final elapsed = DateTime.now().difference(start);
        if (elapsed < const Duration(milliseconds: 500)) {
          await Future.delayed(const Duration(milliseconds: 500) - elapsed);
        }
        if (isClosed || requestId != _getChatsRequestId) return;
      }
      _emitWithPresence();
      _persistChatsSnapshot(chats);
    } catch (e) {
      if (isClosed || requestId != _getChatsRequestId) return;

      _showSkeleton = false;
      if (e.toString().contains('no-internet')) {
        if (_cachedChats.isNotEmpty) {
          debugPrint('Silent error: No internet, but showing cached chats.');
          _emitWithPresence();
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
    _reactionsRetryTimer?.cancel();
    _activePeerClearTimer?.cancel();
    if (_reactionsChannel != null) {
      final old = _reactionsChannel!;
      _reactionsChannel = null;
      RealtimeDiagnostics.instance.onChannelClosed(old.topic);
      unawaited(SupabaseProvider.client.removeChannel(old));
    }
    return super.close();
  }
}
