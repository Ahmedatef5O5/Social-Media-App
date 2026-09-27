part of 'group_list_cubit.dart';

const int kMaxCachedGroupsSnapshot = 50;

mixin GroupFetchPersistenceMixin on GroupListBase {
  @override
  Future<void> loadGroups({bool isRefresh = false}) async {
    final requestId = ++loadGroupsRequestId;

    if (!isRefresh) emit(GroupListLoading());
    try {
      final fetchedGroups =
          await services.getMyGroups()
            ..removeWhere((g) => locallyDeletedGroupIds.contains(g.id))
            ..removeWhere(isHiddenByLocalClear);

      final fetchedIds = fetchedGroups.map((g) => g.id).toList();
      try {
        membersByGroupId
          ..clear()
          ..addAll(await services.getMembersForGroups(fetchedIds));
      } catch (e) {
        debugPrint('⚠️ Failed to load group members (non-fatal): $e');
      }

      if (requestId != loadGroupsRequestId) return;

      final leftGroupsStillTracked = cached.where(
        (g) => !g.isMember && !fetchedIds.contains(g.id),
      );

      var mergedActive =
          fetchedGroups.map((newGroup) {
            final existingIndex = cached.indexWhere((g) => g.id == newGroup.id);
            if (existingIndex != -1) {
              final existingGroup = cached[existingIndex];
              final isExistingReaction =
                  existingGroup.lastMessageType == 'message_react';
              final isNewMessageEmpty =
                  !isExistingReaction &&
                  (newGroup.lastMessage?.isEmpty ?? true) &&
                  newGroup.lastMessageAt == null;
              return newGroup.copyWith(
                unreadCount:
                    existingGroup.unreadCount == 0 ? 0 : newGroup.unreadCount,
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

      mergedActive = await _enrichGroupsWithLatestReactions(mergedActive);

      if (requestId != loadGroupsRequestId) return;

      cached = [...mergedActive, ...leftGroupsStillTracked];
      cached.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      emit(GroupListLoaded(cached));
      persistGroupsSnapshot(cached);
    } catch (e) {
      if (requestId != loadGroupsRequestId) return;

      debugPrint('Error loading groups: $e');

      if (cached.isNotEmpty) {
        debugPrint('Silent error: no internet, showing cached groups.');
        emit(GroupListLoaded(cached));
        return;
      }

      final diskGroups = readGroupsSnapshot();
      if (diskGroups.isNotEmpty) {
        debugPrint(
          'Silent error: no internet, showing groups snapshot from disk.',
        );
        cached = diskGroups;
        emit(GroupListLoaded(diskGroups));
        return;
      }

      if (e.toString().contains('no-internet')) {
        emit(
          GroupListError("No internet connection. Please check your network."),
        );
      } else {
        emit(GroupListError(AuthExceptionHandler.handle(e)));
      }
    }
  }

  @override
  void persistGroupsSnapshot(List<GroupModel> groups) {
    unawaited(
      LocalSnapshotStore.instance.saveList(
        SnapshotKeys.groups,
        groups
            .take(kMaxCachedGroupsSnapshot)
            .map((group) => group.toCacheJson())
            .toList(),
      ),
    );
  }

  List<GroupModel> readGroupsSnapshot() {
    try {
      return LocalSnapshotStore.instance
          .readList(SnapshotKeys.groups)
          .map(GroupModel.fromCacheJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to read groups snapshot from disk: $e');
      return [];
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    String? avatarUrl,
    String? avatarPublicId,
    required List<String> memberIds,
  }) async {
    final group = await services.createGroup(
      name: name,
      avatarUrl: avatarUrl,
      avatarPublicId: avatarPublicId,
      memberIds: memberIds,
    );
    if (isClosed) return group;
    await loadGroups(isRefresh: true);
    return group;
  }

  Future<List<GroupModel>> _enrichGroupsWithLatestReactions(
    List<GroupModel> groups,
  ) async {
    if (groups.isEmpty) return groups;
    try {
      final groupIds = groups.map((g) => g.id).toList();
      final reactionRows = await SupabaseProvider.client
          .from(SupabaseConstants.groupMessageReactions)
          .select('message_id, user_id, reaction, group_id, created_at')
          .inFilter(GroupReactionColumns.groupId, groupIds)
          .order(MessageReactionColumns.createdAt, ascending: false);

      final latestReactionByGroup = <String, Map<String, dynamic>>{};
      for (final r in (reactionRows as List)) {
        final row = r as Map<String, dynamic>;
        final gId = row[GroupReactionColumns.groupId] as String?;
        if (gId != null && !latestReactionByGroup.containsKey(gId)) {
          latestReactionByGroup[gId] = row;
        }
      }

      if (latestReactionByGroup.isEmpty) return groups;

      final targetMessageIds = <String>{};
      final missingReactorUserIds = <String>{};

      for (final group in groups) {
        final reactionRow = latestReactionByGroup[group.id];
        if (reactionRow == null) continue;

        final createdAtStr =
            reactionRow[MessageReactionColumns.createdAt] as String?;
        final reactionTime =
            createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
        if (reactionTime == null) continue;

        if (group.lastMessageAt == null ||
            reactionTime.isAfter(group.lastMessageAt!)) {
          final msgId = reactionRow[GroupReactionColumns.messageId] as String?;
          if (msgId != null && msgId.isNotEmpty) {
            targetMessageIds.add(msgId);
          }
          final reactorId = reactionRow[GroupReactionColumns.userId] as String?;
          if (reactorId != null && reactorId != currentUserId) {
            final members = membersByGroupId[group.id] ?? const [];
            final foundInMembers = members.any((m) => m.userId == reactorId);
            if (!foundInMembers) {
              missingReactorUserIds.add(reactorId);
            }
          }
        }
      }

      if (targetMessageIds.isEmpty) return groups;

      final msgRows = await SupabaseProvider.client
          .from(SupabaseConstants.groupMessages)
          .select(
            'id, message_text, message_type, caption, file_name, deleted_for',
          )
          .inFilter('id', targetMessageIds.toList());

      final messagesById = <String, Map<String, dynamic>>{};
      for (final m in (msgRows as List)) {
        final map = m as Map<String, dynamic>;
        final deletedFor =
            (map['deleted_for'] as List?)?.cast<String>() ?? const [];
        if (deletedFor.contains(currentUserId)) continue;
        final id = map['id'] as String?;
        if (id != null) {
          messagesById[id] = map;
        }
      }

      if (messagesById.isEmpty) return groups;

      final fallbackUserNames = <String, String>{};
      if (missingReactorUserIds.isNotEmpty) {
        try {
          final userRows = await SupabaseProvider.client
              .from(SupabaseConstants.users)
              .select('id, name')
              .inFilter('id', missingReactorUserIds.toList());
          for (final u in (userRows as List)) {
            final map = u as Map<String, dynamic>;
            final id = map['id'] as String?;
            final name = map['name'] as String?;
            if (id != null && name != null) {
              fallbackUserNames[id] = name;
            }
          }
        } catch (_) {}
      }

      return groups.map((group) {
        final reactionRow = latestReactionByGroup[group.id];
        if (reactionRow == null) return group;

        final createdAtStr =
            reactionRow[MessageReactionColumns.createdAt] as String?;
        final reactionTime =
            createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
        if (reactionTime == null) return group;

        if (group.lastMessageAt != null &&
            !reactionTime.isAfter(group.lastMessageAt!)) {
          return group;
        }

        final msgId = reactionRow[GroupReactionColumns.messageId] as String?;
        final msg = msgId != null ? messagesById[msgId] : null;
        if (msg == null) return group;

        final reactorId =
            reactionRow[GroupReactionColumns.userId] as String? ?? '';
        final isMe = reactorId == currentUserId;
        String reactorName = 'Someone';
        if (!isMe) {
          final members = membersByGroupId[group.id] ?? const [];
          for (final m in members) {
            if (m.userId == reactorId && m.userName.trim().isNotEmpty) {
              reactorName = m.userName.trim();
              break;
            }
          }
          if (reactorName == 'Someone' &&
              fallbackUserNames.containsKey(reactorId)) {
            reactorName = fallbackUserNames[reactorId]!;
          }
        }

        final reactionEmoji =
            reactionRow[GroupReactionColumns.reaction] as String?;
        final previewText = MessageReactionPreviewHelper.formatReactionPreview(
          isMe: isMe,
          reactorName: reactorName,
          reactionType: reactionEmoji,
          messageType: msg['message_type'] as String?,
          messageText: msg['message_text'] as String?,
          fileName: msg['file_name'] as String?,
          caption: msg['caption'] as String?,
        );

        return group.copyWith(
          lastMessage: previewText,
          lastMessageType: 'message_react',
          lastMessageAt: reactionTime,
          lastMessageSenderId: reactorId,
          lastMessageSenderName: isMe ? 'You' : reactorName,
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ _enrichGroupsWithLatestReactions failed (non-fatal): $e');
      return groups;
    }
  }
}
