import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/cache/constants/snapshot_keys.dart';
import '../../../../core/cache/services/local_snapshot_store.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../../auth/handlers/auth_exception_handler.dart';
import '../../helpers/group_chat_clear_store.dart';
import '../../models/group_member_model.dart';
import '../../models/group_model.dart';
import '../../models/group_presence_entry.dart';
import '../../services/group_chat_services.dart';
part 'group_list_state.dart';

const int kMaxCachedGroupsSnapshot = 50;

class GroupListCubit extends Cubit<GroupListState> with WidgetsBindingObserver {
  final GroupChatServices _services;
  RealtimeChannel? _channel;
  StreamSubscription? _messagesStreamSub;
  StreamSubscription? _presenceSub;
  List<GroupModel> _cached = [];
  final Map<String, List<GroupMemberModel>> _membersByGroupId = {};
  Timer? _activeGroupTimer;
  String? _activeGroupId;
  int _loadGroupsRequestId = 0;
  Timer? _reconcileDebounce;

  final Set<String> _locallyDeletedGroupIds = {};
  List<GroupModel> get cachedGroupsChats => _cached;

  String get _currentUserId => SupabaseProvider.id;

  GroupListCubit(this._services) : super(GroupListInitial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadGroups(isRefresh: true);
    }
  }

  bool _isHiddenByLocalClear(GroupModel g) {
    final clearedAt = GroupChatClearStore.instance.clearedAtFor(g.id);
    if (clearedAt == null) return false;
    final lastMsgAt = g.lastMessageAt;
    if (lastMsgAt != null && lastMsgAt.isAfter(clearedAt)) {
      return false;
    }
    return true;
  }

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
    _cached = newList;
    emit(GroupListLoaded(newList));
    _persistGroupsSnapshot(newList);
  }

  void setActiveGroupId(String? groupId) {
    _activeGroupTimer?.cancel();

    if (groupId == null) {
      _activeGroupTimer = Timer(const Duration(milliseconds: 800), () {
        _activeGroupId = null;
      });
    } else {
      _activeGroupId = groupId;
      resetGroupUnreadCount(groupId);
    }
  }

  Future<void> monitorGroups() async {
    await loadGroups();
    _subscribeRealtime();
    _subscribeMessagesStream();
    _subscribeGroupsPresence();
  }

  void _subscribeMessagesStream() {
    _messagesStreamSub?.cancel();

    _messagesStreamSub = SupabaseProvider.client
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
            if (deletedFor.contains(_currentUserId)) continue;
            final gId = row[GroupMemberColumns.groupId] as String?;
            if (gId == null) continue;

            if (!latestPerGroup.containsKey(gId)) {
              latestPerGroup[gId] = row;
            }

            final senderId = row['sender_id'] as String?;
            if (senderId == _currentUserId) continue;
            if (_isReadByMe(row['read_by'])) continue;
            unreadPerGroup[gId] = (unreadPerGroup[gId] ?? 0) + 1;
          }

          for (final entry in latestPerGroup.entries) {
            final groupId = entry.key;
            final row = entry.value;

            final cachedGroup = _cached.firstWhere(
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
    final targetId = row['target_id'] as String?;
    final targetName = row['target_name'] as String?;
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
      lastMessageTargetId: targetId,
      lastMessageTargetName: targetName,
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
      } catch (e) {
        debugPrint('[GroupListCubit] failed to parse readBy payload: $e');
      }
      return readByRaw.contains(_currentUserId);
    }
    return false;
  }

  // ─── Realtime subscriptions ───────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();

    final channelName = 'group_list_monitor_$_currentUserId';
    _channel = SupabaseProvider.client.channel(channelName);

    _channel!
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

            if (userId == _currentUserId && groupId != null) {
              _locallyDeletedGroupIds.remove(groupId);
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
            if (userId != _currentUserId || groupId == null) return;

            if (status == 'left' || status == 'removed') {
              markGroupAsLeft(groupId);
            } else if (status == 'active') {
              _locallyDeletedGroupIds.remove(groupId);
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
            if (userId == _currentUserId && groupId != null) {
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
            if (groupId != null) _removeGroupFromState(groupId);
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
    _presenceSub?.cancel();
    if (state is! GroupListLoaded) return;

    _presenceSub = _services.watchAllGroupsPresence().listen((map) {
      if (state is! GroupListLoaded) return;
      final current = state as GroupListLoaded;
      final updated =
          current.groups.map((g) {
            final snapshot = map[g.id] ?? GroupPresenceSnapshot.empty;
            return g.copyWith(presence: snapshot);
          }).toList();
      _cached = updated;
      emit(GroupListLoaded(updated));
    });
  }

  List<GroupMemberModel> membersOf(String groupId) =>
      _membersByGroupId[groupId] ?? const <GroupMemberModel>[];

  GroupPresenceSnapshot presenceOf(String groupId) {
    final match = _cached.where((g) => g.id == groupId);
    return match.isEmpty ? GroupPresenceSnapshot.empty : match.first.presence;
  }

  // ─── State helpers ────────────────────────────────────────────────────────
  void _scheduleReconcile() {
    _reconcileDebounce?.cancel();
    _reconcileDebounce = Timer(const Duration(milliseconds: 300), () {
      loadGroups(isRefresh: true);
    });
  }

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
      _cached = newList;
      emit(GroupListLoaded(newList));
      _persistGroupsSnapshot(newList);
    }
    _scheduleReconcile();
  }

  void markGroupAsLeft(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx != -1 && currentState.groups[idx].isMember) {
      final newList = List<GroupModel>.from(currentState.groups);
      newList[idx] = newList[idx].copyWith(isMember: false);
      _cached = newList;
      emit(GroupListLoaded(newList));
      _persistGroupsSnapshot(newList);
    }
    _scheduleReconcile();
  }

  void updateGroupMembership(String groupId, bool isMember) {
    if (isMember) {
      markGroupAsActive(groupId);
    } else {
      markGroupAsLeft(groupId);
    }
  }

  Future<void> removeGroupLocally(String groupId) async {
    _locallyDeletedGroupIds.add(groupId);

    if (state is! GroupListLoaded) {
      await LocalSnapshotStore.instance.clear(
        'group_messages_snapshot_$groupId',
      );
      return;
    }

    final currentState = state as GroupListLoaded;
    final newList = currentState.groups.where((g) => g.id != groupId).toList();
    _cached = newList;

    emit(GroupListLoaded(newList));

    await LocalSnapshotStore.instance.clear('group_messages_snapshot_$groupId');
    _persistGroupsSnapshot(newList);
  }

  void _removeGroupFromState(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final newList = currentState.groups.where((g) => g.id != groupId).toList();
    if (newList.length == currentState.groups.length) return;
    _cached = newList;
    emit(GroupListLoaded(newList));
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

  void clearGroupAvatar(String groupId) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(avatarUrl: null);
    _cached = newList;
    emit(GroupListLoaded(newList));
    _persistGroupsSnapshot(newList);
  }

  void updateGroupName({required String groupId, required String newName}) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(name: newName);
    _cached = newList;
    emit(GroupListLoaded(newList));
    _persistGroupsSnapshot(newList);
  }

  void updateGroupTitle({required String groupId, String? newTitle}) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(title: newTitle);
    _cached = newList;
    emit(GroupListLoaded(newList));
    _persistGroupsSnapshot(newList);
  }

  void toggleGroupMute(String groupId, bool muted) {
    if (state is! GroupListLoaded) return;
    final currentState = state as GroupListLoaded;
    final idx = currentState.groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final newList = List<GroupModel>.from(currentState.groups);
    newList[idx] = newList[idx].copyWith(isMuted: muted);
    _cached = newList;
    emit(GroupListLoaded(newList));
    _persistGroupsSnapshot(newList);
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
    } catch (e) {
      debugPrint('[GroupListCubit] failed to format group call label: $e');
    }
    return '📞 Group call';
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  Future<void> loadGroups({bool isRefresh = false}) async {
    // Staleness guard: every call gets a ticket. If a *newer* loadGroups()
    // call has started by the time this one's network round-trip
    // completes, this result is discarded instead of applied. Without
    // this, an older in-flight fetch (e.g. kicked off right before a
    // member gets re-added) can resolve *after* a newer, fresher fetch (or
    // a realtime-driven local patch like markGroupAsActive) and silently
    // overwrite `_cached` with stale data — which is exactly what caused
    // a rejoined group to flash back to "not a member" until a manual
    // pull-to-refresh forced yet another (finally-fresh) fetch.
    final requestId = ++_loadGroupsRequestId;

    if (!isRefresh) emit(GroupListLoading());
    try {
      final fetchedGroups =
          await _services.getMyGroups()
            ..removeWhere((g) => _locallyDeletedGroupIds.contains(g.id))
            ..removeWhere(_isHiddenByLocalClear);

      final fetchedIds = fetchedGroups.map((g) => g.id).toList();
      try {
        _membersByGroupId
          ..clear()
          ..addAll(await _services.getMembersForGroups(fetchedIds));
      } catch (e) {
        debugPrint('⚠️ Failed to load group members (non-fatal): $e');
      }

      if (requestId != _loadGroupsRequestId) return;

      final leftGroupsStillTracked = _cached.where(
        (g) => !g.isMember && !fetchedIds.contains(g.id),
      );

      final mergedActive =
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

      _cached = [...mergedActive, ...leftGroupsStillTracked];
      _cached.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      emit(GroupListLoaded(_cached));
      _persistGroupsSnapshot(_cached);
    } catch (e) {
      if (requestId != _loadGroupsRequestId) return;

      debugPrint('Error loading groups: $e');

      if (_cached.isNotEmpty) {
        debugPrint('Silent error: no internet, showing cached groups.');
        emit(GroupListLoaded(_cached));
        return;
      }

      final diskGroups = _readGroupsSnapshot();
      if (diskGroups.isNotEmpty) {
        debugPrint(
          'Silent error: no internet, showing groups snapshot from disk.',
        );
        _cached = diskGroups;
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

  void _persistGroupsSnapshot(List<GroupModel> groups) {
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

  List<GroupModel> _readGroupsSnapshot() {
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
    final group = await _services.createGroup(
      name: name,
      avatarUrl: avatarUrl,
      avatarPublicId: avatarPublicId,
      memberIds: memberIds,
    );
    await loadGroups(isRefresh: true);
    return group;
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

    _cached = updatedGroups;
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
    _cached = newList;
    emit(GroupListLoaded(newList));
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _channel?.unsubscribe();
    _messagesStreamSub?.cancel();
    _activeGroupTimer?.cancel();
    _reconcileDebounce?.cancel();
    return super.close();
  }
}
