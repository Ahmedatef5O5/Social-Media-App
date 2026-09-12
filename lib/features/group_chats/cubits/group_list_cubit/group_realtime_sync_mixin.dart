part of 'group_list_cubit.dart';

mixin GroupRealtimeSyncMixin on GroupListBase {
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadGroups(isRefresh: true);
    }
  }

  Future<void> monitorGroups() async {
    await loadGroups();
    _subscribeRealtime();
    _subscribeMessagesStream();
    _subscribeGroupsPresence();
  }

  void _subscribeMessagesStream() {
    messagesStreamSub?.cancel();

    messagesStreamSub = SupabaseProvider.client
        .from(SupabaseConstants.groupMessages)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .listen((data) {
          if (isClosed) return;
          if (data.isEmpty) return;
          if (state is! GroupListLoaded) return;

          final Map<String, Map<String, dynamic>> latestPerGroup = {};
          final Map<String, int> unreadPerGroup = {};

          for (final row in data) {
            final deletedFor =
                (row['deleted_for'] as List?)?.cast<String>() ?? [];
            if (deletedFor.contains(currentUserId)) continue;
            final gId = row[GroupMemberColumns.groupId] as String?;
            if (gId == null) continue;

            if (!latestPerGroup.containsKey(gId)) {
              latestPerGroup[gId] = row;
            }

            final senderId = row['sender_id'] as String?;
            if (senderId == currentUserId) continue;
            if (_isReadByMe(row['read_by'])) continue;
            unreadPerGroup[gId] = (unreadPerGroup[gId] ?? 0) + 1;
          }

          for (final entry in latestPerGroup.entries) {
            final groupId = entry.key;
            final row = entry.value;

            final cachedGroup = cached.firstWhere(
              (g) => g.id == groupId,
              orElse:
                  () => GroupModel(
                    id: groupId,
                    name: '',
                    createdBy: '',
                    createdAt: DateTime.now(),
                    isMember: true,
                  ),
            );
            if (!cachedGroup.isMember) continue;

            final isActiveGroup = activeGroupId == groupId;
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
    final targetId = row['target_id'] as String?;
    final targetName = row['target_name'] as String?;
    final text = row['message_text'] as String? ?? '';

    final String rawMessage =
        messageType == 'call' ? _parseGroupCallPreview(text) : text;

    updateGroupInState(
      groupId: groupId,
      lastMessage: rawMessage,
      lastMessageType: messageType,
      lastMessageAt: createdAt,
      lastMessageSenderId: senderId,
      lastMessageSenderName: senderName,
      lastMessageTargetId: targetId,
      lastMessageTargetName: targetName,
      unreadCount: unreadCount,
    );
  }

  bool _isReadByMe(dynamic readByRaw) {
    if (readByRaw == null) return false;
    if (readByRaw is List) {
      return readByRaw.any((e) => e.toString() == currentUserId);
    }
    if (readByRaw is String) {
      try {
        final decoded = jsonDecode(readByRaw);
        if (decoded is List) {
          return decoded.any((e) => e.toString() == currentUserId);
        }
      } catch (e) {
        debugPrint('[GroupListCubit] failed to parse readBy payload: $e');
      }
      return readByRaw.contains(currentUserId);
    }
    return false;
  }

  void _subscribeRealtime() {
    channel?.unsubscribe();

    final channelName = 'group_list_monitor_$currentUserId';
    channel = SupabaseProvider.client.channel(channelName);

    channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_calls',
          callback: (payload) => _handleGroupCallChange(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.groupMembers,
          callback: (payload) {
            final row = payload.newRecord;
            final userId = row[GroupMemberColumns.userId] as String?;
            final groupId = row[GroupMemberColumns.groupId] as String?;

            if (userId == currentUserId && groupId != null) {
              locallyDeletedGroupIds.remove(groupId);
              unawaited(GroupChatClearStore.instance.clear(groupId));
              loadGroups(isRefresh: true);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.groupMembers,
          callback: (payload) {
            final row = payload.newRecord;
            final userId = row[GroupMemberColumns.userId] as String?;
            final groupId = row[GroupMemberColumns.groupId] as String?;
            final status = row[GroupMemberColumns.membershipStatus] as String?;
            if (userId != currentUserId || groupId == null) return;

            if (status == 'left' || status == 'removed') {
              markGroupAsLeft(groupId);
            } else if (status == 'active') {
              locallyDeletedGroupIds.remove(groupId);
              unawaited(GroupChatClearStore.instance.clear(groupId));
              markGroupAsActive(groupId);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConstants.groupMembers,
          callback: (payload) {
            final row = payload.oldRecord;
            final userId = row[GroupMemberColumns.userId] as String?;
            final groupId = row[GroupMemberColumns.groupId] as String?;
            if (userId == currentUserId && groupId != null) {
              markGroupAsLeft(groupId);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConstants.groups,
          callback: (payload) {
            final groupId = payload.oldRecord['id'] as String?;
            if (groupId != null) removeGroupFromState(groupId);
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
            updateGroupAvatarInState(
              groupId: groupId,
              name: row['name'] as String?,
              avatarUrl: row['avatar_url'] as String?,
            );
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            loadGroups(isRefresh: true);
          }
          if (error != null) {
            debugPrint('[GroupListCubit] realtime channel error: $error');
          }
        });
  }

  void _subscribeGroupsPresence() {
    presenceSub?.cancel();
    if (state is! GroupListLoaded) return;

    presenceSub = services.watchAllGroupsPresence().listen((map) {
      if (state is! GroupListLoaded) return;
      final current = state as GroupListLoaded;
      final updated =
          current.groups.map((g) {
            final snapshot = map[g.id] ?? GroupPresenceSnapshot.empty;
            return g.copyWith(presence: snapshot);
          }).toList();
      cached = updated;
      emit(GroupListLoaded(updated));
    });
  }

  @override
  void scheduleReconcile() {
    reconcileDebounce?.cancel();
    reconcileDebounce = Timer(const Duration(milliseconds: 300), () {
      loadGroups(isRefresh: true);
    });
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

    if (!currentState.groups[idx].isMember) return;

    updateGroupInState(
      groupId: groupId,
      lastMessage: preview,
      lastMessageType: 'call',
      lastMessageAt: updatedAt,
      unreadCount: currentState.groups[idx].unreadCount,
    );
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
    } catch (e) {
      debugPrint('[GroupListCubit] failed to format group call label: $e');
    }
    return '📞 Group call';
  }
}
