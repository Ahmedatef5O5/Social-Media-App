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

      final mergedActive =
          fetchedGroups.map((newGroup) {
            final existingIndex = cached.indexWhere((g) => g.id == newGroup.id);
            if (existingIndex != -1) {
              final existingGroup = cached[existingIndex];
              final isNewMessageEmpty = newGroup.lastMessage?.isEmpty ?? true;
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
}
