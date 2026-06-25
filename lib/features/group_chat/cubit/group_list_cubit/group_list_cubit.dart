import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../models/group_model.dart';
import '../../services/group_chat_services.dart';
part 'group_list_state.dart';

class GroupListCubit extends Cubit<GroupListState> {
  final GroupChatServices _services;
  RealtimeChannel? _channel;
  StreamSubscription? _messagesStreamSub;
  List<GroupModel> _cached = [];

  Timer? _activeGroupTimer;
  String? _activeGroupId;

  final Map<String, int> _dbUnreadCounts = {};

  List<GroupModel> get cachedGroupsChats => _cached;

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  GroupListCubit(this._services) : super(GroupListInitial());

  void setActiveGroupId(String? groupId) {
    _activeGroupTimer?.cancel();

    if (groupId == null) {
      _activeGroupTimer = Timer(const Duration(milliseconds: 800), () {
        _activeGroupId = null;
      });
    } else {
      _activeGroupId = groupId;
      _dbUnreadCounts[groupId] = 0;
      resetGroupUnreadCount(groupId);
    }
  }

  void monitorGroups() {
    loadGroups();
    _subscribeRealtime();
    _subscribeMessagesStream();
  }

  void _subscribeMessagesStream() {
    _messagesStreamSub?.cancel();

    _messagesStreamSub = Supabase.instance.client
        .from(SupabaseConstants.groupMessages)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .listen((data) {
          if (isClosed) return;
          if (data.isEmpty) return;
          if (state is! GroupListLoaded) return;

          // Collect latest message per group
          final Map<String, Map<String, dynamic>> latestPerGroup = {};
          // Count unread per group (not from me, not in read_by)
          final Map<String, int> unreadPerGroup = {};

          for (final row in data) {
            final gId = row[GroupMemberColumns.groupId] as String?;
            if (gId == null) continue;

            // Track latest message per group (first occurrence = most recent)
            if (!latestPerGroup.containsKey(gId)) {
              latestPerGroup[gId] = row;
            }

            // Count unread: not my message AND my ID not in read_by
            final senderId = row['sender_id'] as String?;
            if (senderId == _currentUserId) continue;
            if (_isReadByMe(row['read_by'])) continue;
            unreadPerGroup[gId] = (unreadPerGroup[gId] ?? 0) + 1;
          }

          for (final entry in latestPerGroup.entries) {
            final groupId = entry.key;
            final row = entry.value;

            // Use DB-computed unread count, but override to 0 if group is active
            final isActiveGroup = _activeGroupId == groupId;
            final computedUnread =
                isActiveGroup ? 0 : (unreadPerGroup[groupId] ?? 0);

            _processMessageRow(groupId, row, computedUnread);
          }
        });
  }

  void _processMessageRow(
    String groupId,
    Map<String, dynamic> row,
    int unreadCount,
  ) {
    if (state is! GroupListLoaded) return;

    final messageId = row['id'] as String?;
    if (messageId == null) return;

    final createdAtStr = row['created_at'] as String?;
    final createdAt =
        createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now();

    final messageType = row['message_type'] as String? ?? 'text';
    final senderId = row['sender_id'] as String?;
    final senderName = row['sender_name'] as String? ?? '';
    final text = row['message_text'] as String? ?? '';

    final String rawMessage =
        messageType == 'call' ? _parseGroupCallPreview(text) : text;

    _updateGroupInState(
      groupId: groupId,
      lastMessage: rawMessage,
      lastMessageType: messageType,
      lastMessageAt: createdAt,
      lastMessageSenderId: senderId,
      lastMessageSenderName: senderName,
      unreadCount: unreadCount,
    );
  }

  bool _isReadByMe(dynamic readByRaw) {
    if (readByRaw == null) return false;
    if (readByRaw is List) {
      return readByRaw.any((e) => e.toString() == _currentUserId);
    }
    if (readByRaw is String) {
      try {
        final decoded = jsonDecode(readByRaw);
        if (decoded is List) {
          return decoded.any((e) => e.toString() == _currentUserId);
        }
      } catch (_) {}
      return readByRaw.contains(_currentUserId);
    }
    return false;
  }

  // ─── Realtime subscriptions ───────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();

    final channelName = 'group_list_monitor_$_currentUserId';
    _channel = Supabase.instance.client.channel(channelName);

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_calls',
          callback: (payload) => _handleGroupCallChange(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          callback: (payload) {
            final newRow = payload.newRecord;
            final oldRow = payload.oldRecord;
            final affectedUserId =
                newRow[GroupMemberColumns.userId] ??
                oldRow[GroupMemberColumns.userId];
            if (affectedUserId == _currentUserId) {
              loadGroups(isRefresh: true);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.groups,
          callback: (payload) {
            final row = payload.newRecord;
            final groupId = row['id'] as String?;
            if (groupId == null) return;
            _updateGroupAvatarInState(
              groupId: groupId,
              name: row['name'] as String?,
              avatarUrl: row['avatar_url'] as String?,
            );
          },
        )
        .subscribe();
  }

  // ─── State helpers ────────────────────────────────────────────────────────

  void _updateGroupAvatarInState({
    required String groupId,
    String? name,
    String? avatarUrl,
  }) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(
      name: name ?? newList[idx].name,
      avatarUrl: avatarUrl ?? newList[idx].avatarUrl,
    );
    _cached = newList;
    emit(GroupListLoaded(newList));
  }

  void updateGroupAvatar({
    required String groupId,
    required String newAvatarUrl,
  }) {
    _updateGroupAvatarInState(groupId: groupId, avatarUrl: newAvatarUrl);
  }

  void _handleGroupCallChange(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) return;

    final groupId = row[GroupMemberColumns.groupId] as String?;
    final status = row['status'] as String?;
    final type = row['type'] as String?;
    final duration = row['duration'] as String?;
    final participants = (row['participant_count'] as int?) ?? 0;
    final updatedAtStr =
        row['ended_at'] as String? ?? row['started_at'] as String?;
    final updatedAt =
        updatedAtStr != null
            ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
            : DateTime.now();

    if (groupId == null || status == null) return;

    final typeIcon = type == 'video' ? '🎥' : '📞';
    final typeLabel = type == 'video' ? 'Group video call' : 'Group voice call';

    final preview = switch (status) {
      'missed' => '$typeIcon Missed $typeLabel',
      'ringing' => '$typeIcon $typeLabel',
      'accepted' || 'ongoing' =>
        participants > 0
            ? '$typeIcon $typeLabel • $participants'
            : '$typeIcon $typeLabel',
      'ended' =>
        duration != null && duration.isNotEmpty
            ? '$typeIcon $typeLabel • $duration'
            : '$typeIcon $typeLabel ended',
      _ => '$typeIcon $typeLabel',
    };

    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    _updateGroupInState(
      groupId: groupId,
      lastMessage: preview,
      lastMessageType: 'call',
      lastMessageAt: updatedAt,
      unreadCount: currentState.groups[idx].unreadCount,
    );
  }

  void _updateGroupInState({
    required String groupId,
    required String lastMessage,
    required String lastMessageType,
    required DateTime lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    required int unreadCount,
  }) {
    if (state is! GroupListLoaded) return;

    final currentState = state as GroupListLoaded;
    final newList = List<GroupModel>.from(currentState.groups);
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);

    if (idx == -1) {
      loadGroups(isRefresh: true);
      return;
    }

    newList[idx] = newList[idx].copyWith(
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageAt: lastMessageAt,
      lastMessageSenderId:
          lastMessageSenderId ?? newList[idx].lastMessageSenderId,
      lastMessageSenderName:
          lastMessageSenderName ?? newList[idx].lastMessageSenderName,
      unreadCount: unreadCount,
    );

    newList.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    _cached = newList;
    emit(GroupListLoaded(newList));
  }

  String _parseGroupCallPreview(String text) {
    try {
      if (text.trim().startsWith('{')) {
        final data = jsonDecode(text) as Map<String, dynamic>;
        final callType = data['call_type'] as String? ?? 'audio';
        final status = data['status'] as String? ?? 'ended';
        final icon = callType == 'video' ? '🎥' : '📞';
        final typeLabel =
            callType == 'video' ? 'Group video call' : 'Group voice call';
        return switch (status) {
          'ringing' || 'accepted' || 'ongoing' => '$icon $typeLabel',
          'missed' => '$icon Missed $typeLabel',
          'ended' => () {
            final duration = data['duration'] as String? ?? '';
            return duration.isNotEmpty
                ? '$icon $typeLabel • $duration'
                : '$icon $typeLabel ended';
          }(),
          _ => '$icon $typeLabel',
        };
      }
    } catch (_) {}
    return '📞 Group call';
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  Future<void> loadGroups({bool isRefresh = false}) async {
    if (!isRefresh) emit(GroupListLoading());
    try {
      final fetchedGroups = await _services.getMyGroups();

      _cached =
          fetchedGroups.map((newGroup) {
            final existingIndex = _cached.indexWhere(
              (g) => g.id == newGroup.id,
            );

            if (existingIndex != -1) {
              final existingGroup = _cached[existingIndex];
              final isNewMessageEmpty = newGroup.lastMessage?.isEmpty ?? true;
              return newGroup.copyWith(
                unreadCount: existingGroup.unreadCount,
                lastMessage:
                    isNewMessageEmpty
                        ? existingGroup.lastMessage
                        : newGroup.lastMessage,
                lastMessageType:
                    isNewMessageEmpty
                        ? existingGroup.lastMessageType
                        : newGroup.lastMessageType,
                lastMessageAt:
                    newGroup.lastMessageAt ?? existingGroup.lastMessageAt,
                lastMessageSenderId:
                    newGroup.lastMessageSenderId ??
                    existingGroup.lastMessageSenderId,
                lastMessageSenderName:
                    newGroup.lastMessageSenderName ??
                    existingGroup.lastMessageSenderName,
              );
            }
            return newGroup;
          }).toList();

      _cached.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      emit(GroupListLoaded(_cached));
    } catch (e) {
      emit(GroupListError(e.toString()));
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    String? avatarUrl,
    required List<String> memberIds,
  }) async {
    final group = await _services.createGroup(
      name: name,
      avatarUrl: avatarUrl,
      memberIds: memberIds,
    );
    await loadGroups(isRefresh: true);
    return group;
  }

  /// Called by GroupDetailsCubit when a new message arrives while inside chat.
  /// Never changes unread count — user is actively reading.
  void updateGroupLastMessage({
    required String groupId,
    required String message,
    required String messageId,
    required String messageType,
    required DateTime createdAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
  }) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final existingUnread = currentState.groups[idx].unreadCount;

    _updateGroupInState(
      groupId: groupId,
      lastMessage: message,
      lastMessageType: messageType,
      lastMessageAt: createdAt,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageSenderName: lastMessageSenderName,
      unreadCount: existingUnread,
    );
  }

  void resetGroupUnreadCount(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    if (newList[idx].unreadCount == 0) return;
    newList[idx] = newList[idx].copyWith(unreadCount: 0);
    _cached = newList;
    emit(GroupListLoaded(newList));
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    _messagesStreamSub?.cancel();
    _activeGroupTimer?.cancel();
    return super.close();
  }
}
