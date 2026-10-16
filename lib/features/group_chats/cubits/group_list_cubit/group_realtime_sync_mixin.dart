part of 'group_list_cubit.dart';

const int _kMessageChannelIdLimit = 100;
const int _kMaxMessageChannels = 3;

mixin GroupRealtimeSyncMixin on GroupListBase {
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadGroups(isRefresh: true);
    }
  }

  Future<void> monitorGroups() async {
    await loadGroups();
    _subscribeRealtime();
    syncMessageChannels();
    _subscribeGroupsPresence();
  }

  @override
  void syncMessageChannels() {
    if (isClosed) return;

    final ids =
        <String>[
          for (final g in cached)
            if (g.isMember) g.id,
        ].take(_kMessageChannelIdLimit * _kMaxMessageChannels).toList();
    final idSet = ids.toSet();

    final unchanged =
        idSet.length == messageChannelGroupIds.length &&
        idSet.containsAll(messageChannelGroupIds) &&
        (ids.isEmpty || messageChannels.isNotEmpty);
    if (unchanged) return;

    final old = List<RealtimeChannel>.of(messageChannels);
    messageChannels.clear();
    messageChannelGroupIds = idSet;
    for (final channel in old) {
      RealtimeDiagnostics.instance.onChannelClosed(channel.topic);
      unawaited(SupabaseProvider.client.removeChannel(channel));
    }
    if (ids.isEmpty) return;

    messageChannelEpoch++;
    for (var i = 0, n = 0; i < ids.length; i += _kMessageChannelIdLimit, n++) {
      final end =
          i + _kMessageChannelIdLimit > ids.length
              ? ids.length
              : i + _kMessageChannelIdLimit;
      final chunk = ids.sublist(i, end);

      final channel = SupabaseProvider.client.channel(
        'group_msgs_${currentUserId}_${messageChannelEpoch}_$n',
      );
      final topic = channel.topic;
      var hadError = false;

      RealtimeDiagnostics.instance.onChannelCreated(
        topic,
        ownerUserId: currentUserId,
      );

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConstants.groupMessages,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.inFilter,
              column: GroupMemberColumns.groupId,
              value: chunk,
            ),
            callback: _onGroupMessageInserted,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: SupabaseConstants.groupMessages,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.inFilter,
              column: GroupMemberColumns.groupId,
              value: chunk,
            ),
            callback: _onGroupMessageUpdated,
          )
          .subscribe((status, [error]) {
            switch (status) {
              case RealtimeSubscribeStatus.subscribed:
                RealtimeDiagnostics.instance.onChannelSubscribed(topic);
                if (hadError) {
                  hadError = false;
                  scheduleReconcile();
                }
              case RealtimeSubscribeStatus.channelError:
              case RealtimeSubscribeStatus.timedOut:
                hadError = true;
                // If the error is a normal disconnect (e.g. session refresh / token rotation),
                // do not report as a fatal crash to Firebase Crashlytics.
                final isTokenOrNormalClose =
                    error is RealtimeCloseEvent && error.code == 1000;
                if (!isTokenOrNormalClose) {
                  RealtimeDiagnostics.instance.onChannelError(
                    topic,
                    error ?? status,
                    StackTrace.current,
                  );
                }
              case RealtimeSubscribeStatus.closed:
                break;
            }
          });

      messageChannels.add(channel);
    }
  }

  @override
  Future<void> disposeMessageChannels() async {
    final old = List<RealtimeChannel>.of(messageChannels);
    messageChannels.clear();
    messageChannelGroupIds = <String>{};
    for (final channel in old) {
      RealtimeDiagnostics.instance.onChannelClosed(channel.topic);
      try {
        await SupabaseProvider.client.removeChannel(channel);
      } catch (e) {
        debugPrint('[GroupListCubit] failed to remove ${channel.topic}: $e');
      }
    }
  }

  void _onGroupMessageInserted(PostgresChangePayload payload) {
    if (isClosed || state is! GroupListLoaded) return;

    final row = payload.newRecord;
    final groupId = row[GroupMemberColumns.groupId] as String?;
    if (groupId == null) return;
    if (_containsMe(row['deleted_for'])) return;

    final idx = cached.indexWhere((g) => g.id == groupId);
    if (idx == -1) {
      // A group we have not loaded yet (e.g. just joined): let the
      // authoritative RPC decide instead of guessing from one row.
      scheduleReconcile();
      return;
    }

    final group = cached[idx];
    if (!group.isMember) return;

    final isMine = row['sender_id'] == currentUserId;
    final isActiveGroup = activeGroupId == groupId;
    final unread =
        isActiveGroup
            ? 0
            : (isMine ? group.unreadCount : group.unreadCount + 1);

    _processMessageRow(groupId, row, unread);
  }

  void _onGroupMessageUpdated(PostgresChangePayload payload) {
    if (isClosed || state is! GroupListLoaded) return;

    final row = payload.newRecord;
    final old = payload.oldRecord;
    final groupId = row[GroupMemberColumns.groupId] as String?;
    if (groupId == null) return;

    // I deleted a message for myself: previews/unread may change.
    if (_containsMe(row['deleted_for']) && !_containsMe(old['deleted_for'])) {
      scheduleReconcile();
      return;
    }

    // I read a message (possibly from another device): refresh unread counts.
    // Other members' reads also fire UPDATE events and are ignored on purpose.
    if (old.isNotEmpty &&
        row['sender_id'] != currentUserId &&
        _isReadByMe(row['read_by']) &&
        !_isReadByMe(old['read_by'])) {
      scheduleReconcile();
      return;
    }

    // The message currently shown as the group's preview was edited.
    final idx = cached.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final group = cached[idx];
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final previewAt = group.lastMessageAt;
    if (createdAt != null &&
        previewAt != null &&
        createdAt.isAtSameMomentAs(previewAt) &&
        old['message_text'] != row['message_text']) {
      _processMessageRow(groupId, row, group.unreadCount);
    }
  }

  bool _containsMe(dynamic raw) =>
      raw is List && raw.any((e) => e.toString() == currentUserId);

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

    final currentState = state as GroupListLoaded;
    final existingIdx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (existingIdx != -1) {
      final existingGroup = currentState.groups[existingIdx];
      if (existingGroup.lastMessageType == 'message_react' &&
          existingGroup.lastMessageAt != null &&
          existingGroup.lastMessageAt!.isAfter(createdAt)) {
        updateGroupInState(
          groupId: groupId,
          lastMessage: existingGroup.lastMessage ?? '',
          lastMessageType: 'message_react',
          lastMessageAt: existingGroup.lastMessageAt!,
          lastMessageSenderId: existingGroup.lastMessageSenderId,
          lastMessageSenderName: existingGroup.lastMessageSenderName,
          unreadCount: unreadCount,
        );
        return;
      }
    }

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
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.groupMessageReactions,
          callback: (_) => scheduleReconcile(),
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
