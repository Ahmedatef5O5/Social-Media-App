import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../services/group_chat_services.dart';
part 'group_list_state.dart';

class GroupListCubit extends Cubit<GroupListState> {
  final GroupChatServices _services;
  RealtimeChannel? _channel;
  List<GroupModel> _cached = [];

  List<GroupModel> get cachedGroupsChats => _cached;

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  GroupListCubit(this._services) : super(GroupListInitial());

  void monitorGroups() {
    loadGroups();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();

    final channelName = 'group_list_monitor_$_currentUserId';
    _channel = Supabase.instance.client.channel(channelName);

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_messages',
          callback: (payload) => _handleNewGroupMessage(payload),
        )
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

            final affectedUserId = newRow['user_id'] ?? oldRow['user_id'];

            if (affectedUserId == _currentUserId) {
              loadGroups(isRefresh: true);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'group_members',

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

  void _handleNewGroupMessage(PostgresChangePayload payload) {
    final newRow = payload.newRecord;
    if (newRow.isEmpty) {
      loadGroups(isRefresh: true);
      return;
    }

    final groupId = newRow['group_id'] as String?;
    if (groupId == null) return;

    final messageType = newRow['message_type'] as String? ?? 'text';
    final senderId = newRow['sender_id'] as String?;
    final senderName = newRow['sender_name'] as String? ?? '';
    final text = newRow['message_text'] as String? ?? '';
    final createdAtStr = newRow['created_at'] as String?;
    final createdAt =
        createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now();

    final isMe = senderId == _currentUserId;
    final prefix = isMe ? 'You' : senderName;
    final previewContent = switch (messageType) {
      'image' => '📷 Photo',
      'video' => '🎥 Video',
      'voice' => '🎤 Voice message',
      'call' => _parseGroupCallPreview(text),
      _ => text,
    };
    final preview = '$prefix: $previewContent';

    _updateGroupInState(
      groupId: groupId,
      lastMessage: preview,
      lastMessageType: messageType,
      lastMessageAt: createdAt,
      lastMessageSenderId: senderId,
      lastMessageSenderName: senderName,
    );
  }

  void _handleGroupCallChange(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) {
      loadGroups(isRefresh: true);
      return;
    }

    final groupId = row['group_id'] as String?;
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
    final typeLabel = type == 'video' ? 'Group video call' : 'Group Voice call';

    final preview = switch (status) {
      'missed' => '$typeIcon $typeLabel missed',

      'ringing' => '$typeIcon $typeLabel ringing…',

      'accepted' || 'ongoing' =>
        participants > 0
            ? '$typeIcon $typeLabel • $participants participants'
            : '$typeIcon $typeLabel ongoing',

      'ended' =>
        duration != null
            ? '$typeIcon $typeLabel • $participants participants • $duration'
            : '$typeIcon $typeLabel ended',

      _ => '$typeIcon $typeLabel',
    };

    _updateGroupInState(
      groupId: groupId,
      lastMessage: preview,
      lastMessageType: 'group_call',
      lastMessageAt: updatedAt,
    );
  }

  void _updateGroupInState({
    required String groupId,
    required String lastMessage,
    required String lastMessageType,
    required DateTime lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
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
      if (text.startsWith('{')) {
        return text;
      }
    } catch (_) {}
    return 'Group call 📞';
  }

  Future<void> loadGroups({bool isRefresh = false}) async {
    if (!isRefresh) emit(GroupListLoading());
    try {
      _cached = await _services.getMyGroups();
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

  void updateGroupLastMessage({
    required String groupId,
    required String message,
    required String messageType,
    required DateTime createdAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
  }) {
    _updateGroupInState(
      groupId: groupId,
      lastMessage: message,
      lastMessageType: messageType,
      lastMessageAt: createdAt,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageSenderName: lastMessageSenderName,
    );
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    return super.close();
  }
}
