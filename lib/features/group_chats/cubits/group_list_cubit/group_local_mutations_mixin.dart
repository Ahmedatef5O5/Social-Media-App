part of 'group_list_cubit.dart';

mixin GroupLocalMutationsMixin on GroupListBase {
  Future<void> clearChatsLocally(Set<String> groupIds) async {
    if (groupIds.isEmpty) return;

    await GroupChatClearStore.instance.setClearedNow(groupIds);

    for (final groupId in groupIds) {
      await LocalSnapshotStore.instance.clear(
        'group_messages_snapshot_$groupId',
      );
    }

    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final newList =
        currentState.groups.where((g) => !groupIds.contains(g.id)).toList();
    cached = newList;
    emit(GroupListLoaded(newList));
    persistGroupsSnapshot(newList);
  }

  void setActiveGroupId(String? groupId) {
    activeGroupTimer?.cancel();

    if (groupId == null) {
      activeGroupTimer = Timer(const Duration(milliseconds: 800), () {
        activeGroupId = null;
      });
    } else {
      activeGroupId = groupId;
      resetGroupUnreadCount(groupId);
    }
  }

  List<GroupMemberModel> membersOf(String groupId) =>
      membersByGroupId[groupId] ?? const <GroupMemberModel>[];

  GroupPresenceSnapshot presenceOf(String groupId) {
    final match = cached.where((g) => g.id == groupId);
    return match.isEmpty ? GroupPresenceSnapshot.empty : match.first.presence;
  }

  @override
  void markGroupAsActive(String groupId) {
    if (state is! GroupListLoaded) {
      loadGroups(isRefresh: true);
      return;
    }
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) {
      loadGroups(isRefresh: true);
      return;
    }
    if (!currentState.groups[idx].isMember) {
      final newList = List<GroupModel>.from(currentState.groups);
      newList[idx] = newList[idx].copyWith(isMember: true);
      cached = newList;
      emit(GroupListLoaded(newList));
      persistGroupsSnapshot(newList);
    }
    scheduleReconcile();
  }

  @override
  void markGroupAsLeft(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx != -1 && currentState.groups[idx].isMember) {
      final newList = List<GroupModel>.from(currentState.groups);
      newList[idx] = newList[idx].copyWith(isMember: false);
      cached = newList;
      emit(GroupListLoaded(newList));
      persistGroupsSnapshot(newList);
    }
    scheduleReconcile();
  }

  void updateGroupMembership(String groupId, bool isMember) {
    if (isMember) {
      markGroupAsActive(groupId);
    } else {
      markGroupAsLeft(groupId);
    }
  }

  Future<void> removeGroupLocally(String groupId) async {
    locallyDeletedGroupIds.add(groupId);

    if (state is! GroupListLoaded) {
      await LocalSnapshotStore.instance.clear(
        'group_messages_snapshot_$groupId',
      );
      return;
    }

    final currentState = state as GroupListLoaded;
    final newList = currentState.groups.where((g) => g.id != groupId).toList();
    cached = newList;

    emit(GroupListLoaded(newList));

    await LocalSnapshotStore.instance.clear('group_messages_snapshot_$groupId');
    persistGroupsSnapshot(newList);
  }

  @override
  void removeGroupFromState(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final newList = currentState.groups.where((g) => g.id != groupId).toList();
    if (newList.length == currentState.groups.length) return;
    cached = newList;
    emit(GroupListLoaded(newList));
  }

  @override
  void updateGroupAvatarInState({
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
    cached = newList;
    emit(GroupListLoaded(newList));
  }

  void updateGroupAvatar({
    required String groupId,
    required String newAvatarUrl,
  }) {
    updateGroupAvatarInState(groupId: groupId, avatarUrl: newAvatarUrl);
  }

  void clearGroupAvatar(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(avatarUrl: null);
    cached = newList;
    emit(GroupListLoaded(newList));
    persistGroupsSnapshot(newList);
  }

  void updateGroupName({required String groupId, required String newName}) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(name: newName);
    cached = newList;
    emit(GroupListLoaded(newList));
    persistGroupsSnapshot(newList);
  }

  void updateGroupTitle({required String groupId, String? newTitle}) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(title: newTitle);
    cached = newList;
    emit(GroupListLoaded(newList));
    persistGroupsSnapshot(newList);
  }

  void toggleGroupMute(String groupId, bool muted) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(isMuted: muted);
    cached = newList;
    emit(GroupListLoaded(newList));
    persistGroupsSnapshot(newList);
  }

  @override
  void updateGroupInState({
    required String groupId,
    required String lastMessage,
    required String lastMessageType,
    required DateTime lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    String? lastMessageTargetId,
    String? lastMessageTargetName,
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
      lastMessageTargetId:
          lastMessageType == 'system_event' ? lastMessageTargetId : null,
      lastMessageTargetName:
          lastMessageType == 'system_event' ? lastMessageTargetName : null,
      unreadCount: unreadCount,
    );

    newList.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    cached = newList;
    emit(GroupListLoaded(newList));
  }

  void updateGroupLastMessage({
    required String groupId,
    required String message,
    required String messageId,
    required String messageType,
    required DateTime createdAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    String? lastMessageTargetId,
    String? lastMessageTargetName,
  }) {
    final currentState = state;
    if (currentState is! GroupListLoaded) return;

    final idx = currentState.groups.indexWhere((g) => g.id == groupId);

    if (idx == -1) {
      loadGroups(isRefresh: true);
      return;
    }

    final updatedGroups = List<GroupModel>.from(currentState.groups);
    updatedGroups[idx] = updatedGroups[idx].copyWith(
      lastMessage: message,
      lastMessageType: messageType,
      lastMessageAt: createdAt,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageSenderName: lastMessageSenderName,
      lastMessageTargetId: lastMessageTargetId,
      lastMessageTargetName: lastMessageTargetName,
    );

    updatedGroups.sort(
      (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
        a.lastMessageAt ?? a.createdAt,
      ),
    );

    cached = updatedGroups;
    emit(GroupListLoaded(updatedGroups));
  }

  void resetGroupUnreadCount(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    if (newList[idx].unreadCount == 0) return;
    newList[idx] = newList[idx].copyWith(unreadCount: 0);
    cached = newList;
    emit(GroupListLoaded(newList));
  }
}
