import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/cloudinary_upload_result.dart';
import '../../../core/observability/realtime_diagnostics.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_add_members_result.dart';
import '../models/group_header_stats.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/groupe_message_model.dart';

class GroupMembershipService {
  final _supabase = SupabaseProvider.client;

  String get currentUserId => SupabaseProvider.idOrNull ?? '';

  CloudinaryStorageServices get storage => CloudinaryStorageServices.instance;

  static const int _membersPageSize = 20;

  // ═══════════════════════════════════════════════════════════
  // Group CRUD
  // ═══════════════════════════════════════════════════════════

  Future<GroupModel> createGroup({
    required String name,
    String? avatarUrl,
    String? avatarPublicId,
    required List<String> memberIds,
  }) async {
    final row =
        await _supabase
            .rpc(
              'create_group_with_members',
              params: {
                'p_creator_id': currentUserId,
                'p_name': name,
                'p_avatar_url': avatarUrl,
                'p_avatar_public_id': avatarPublicId,
                'p_member_ids': memberIds,
              },
            )
            .single();

    return GroupModel.fromMap(row);
  }

  Future<List<GroupModel>> getMyGroups() async {
    final userId = SupabaseProvider.idOrNull;
    if (userId == null) return [];
    final response = await _supabase.rpc(
      'get_my_groups',
      params: {'p_user_id': currentUserId},
    );
    if (response == null) return [];

    final groups = <GroupModel>[];
    for (final row in (response as List)) {
      try {
        groups.add(GroupModel.fromMap(row as Map<String, dynamic>));
      } catch (e) {
        debugPrint('⚠️ Skipping malformed group row: $e — data: $row');
      }
    }
    return groups;
  }

  Future<List<GroupModel>> searchMyGroups({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc(
      'search_my_groups',
      params: {
        'p_query': query,
        'p_user_id': currentUserId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    if (response == null) return [];
    final groups = <GroupModel>[];
    for (final row in (response as List)) {
      try {
        groups.add(GroupModel.fromMap(row as Map<String, dynamic>));
      } catch (e) {
        debugPrint('⚠️ Skipping malformed group row: $e — data: $row');
      }
    }

    return groups;
  }

  Future<({List<GroupMemberModel> members, int totalCount})>
  getGroupMembersPaginated(
    String groupId, {
    int page = 0,
    int pageSize = _membersPageSize,
  }) async {
    final response = await _supabase.rpc(
      'get_group_members_paginated',
      params: {
        'p_group_id': groupId,
        'p_current_user_id': currentUserId,
        'p_page': page,
        'p_page_size': pageSize,
      },
    );

    final dataList = (response as List).cast<Map<String, dynamic>>();

    final members =
        dataList.map((row) => GroupMemberModel.fromMap(row)).toList();

    final total =
        dataList.isNotEmpty
            ? (dataList.first['total_count'] as num).toInt()
            : 0;

    return (members: members, totalCount: total);
  }

  Future<List<String>> getGroupMemberIds(String groupId) async {
    final response = await _supabase
        .from(SupabaseConstants.groupMembers)
        .select(GroupMemberColumns.userId)
        .eq(GroupMemberColumns.groupId, groupId)
        .eq(GroupMemberColumns.membershipStatus, 'active');
    return (response as List)
        .map((row) => row[GroupMemberColumns.userId] as String)
        .toList();
  }

  Future<bool> checkIsActiveMember({
    required String groupId,
    required String userId,
  }) async {
    final response =
        await _supabase
            .from(SupabaseConstants.groupMembers)
            .select(GroupMemberColumns.membershipStatus)
            .eq(GroupMemberColumns.groupId, groupId)
            .eq(GroupMemberColumns.userId, userId)
            .maybeSingle();

    return response?[GroupMemberColumns.membershipStatus] == 'active';
  }

  Future<Map<String, List<GroupMemberModel>>> getMembersForGroups(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return {};
    final rows = await _supabase
        .from(SupabaseConstants.groupMembers)
        .select(
          'id, ${GroupMemberColumns.groupId}, ${GroupMemberColumns.userId}, '
          'users(${UserColumns.name}, ${UserColumns.imageUrl})',
        )
        .inFilter(GroupMemberColumns.groupId, groupIds)
        .eq(GroupMemberColumns.membershipStatus, 'active');

    final Map<String, List<GroupMemberModel>> result = {};
    for (final row in (rows as List)) {
      try {
        final gId = row[GroupMemberColumns.groupId] as String;
        final userInfo = row['users'] as Map<String, dynamic>? ?? {};
        result
            .putIfAbsent(gId, () => [])
            .add(
              GroupMemberModel.fromMap({
                ...row,
                'user_name': userInfo[UserColumns.name],
                'user_avatar': userInfo[UserColumns.imageUrl],
              }),
            );
      } catch (e) {
        debugPrint('⚠️ Skipping malformed group-member row: $e — data: $row');
      }
    }
    return result;
  }

  Future<void> promoteToAdmin(String groupId, String targetUserId) async {
    await _supabase.rpc(
      'promote_group_member_to_admin',
      params: {'p_group_id': groupId, 'p_target_user_id': targetUserId},
    );
  }

  Future<void> demoteAdmin(String groupId, String targetUserId) async {
    await _supabase.rpc(
      'demote_group_admin',
      params: {'p_group_id': groupId, 'p_target_user_id': targetUserId},
    );
  }

  Future<void> addMember(String groupId, String userId) async {
    await _supabase.from(SupabaseConstants.groupMembers).upsert(
      {
        GroupMemberColumns.groupId: groupId,
        GroupMemberColumns.userId: userId,
        'role': 'member',
        GroupMemberColumns.membershipStatus: 'active',
        GroupMemberColumns.leftAt: null,
        GroupMemberColumns.joinedAt: DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: '${GroupMemberColumns.groupId},${GroupMemberColumns.userId}',
    );
  }

  Future<GroupAddMembersResult> addMembers(
    String groupId,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) {
      return const GroupAddMembersResult(added: [], failed: []);
    }

    final added = <String>[];
    final failed = <String>[];

    for (final uid in userIds) {
      try {
        await _supabase.from(SupabaseConstants.groupMembers).upsert(
          {
            GroupMemberColumns.groupId: groupId,
            GroupMemberColumns.userId: uid,
            'role': 'member',
            GroupMemberColumns.membershipStatus: 'active',
            GroupMemberColumns.leftAt: null,
            GroupMemberColumns.joinedAt:
                DateTime.now().toUtc().toIso8601String(),
          },
          onConflict:
              '${GroupMemberColumns.groupId},${GroupMemberColumns.userId}',
        );
        added.add(uid);
      } on PostgrestException catch (e) {
        if (e.code == '42501') {
          failed.add(uid);
        } else {
          rethrow;
        }
      }
    }

    if (added.isNotEmpty) {
      final names = await fetchUserNames([currentUserId, ...added]);
      final actorName = names[currentUserId] ?? 'Someone';
      for (final uid in added) {
        await sendSystemEvent(
          groupId: groupId,
          type: 'member_added',
          actorId: currentUserId,
          actorName: actorName,
          targetId: uid,
          targetName: names[uid] ?? 'Unknown',
        );
      }
    }

    return GroupAddMembersResult(added: added, failed: failed);
  }

  Future<void> removeMember(
    String groupId,
    String userId, {
    required String actorId,
  }) async {
    final names = await fetchUserNames([actorId, userId]);

    await sendSystemEvent(
      groupId: groupId,
      type: 'member_removed',
      actorId: actorId,
      actorName: names[actorId] ?? 'Someone',
      targetId: userId,
      targetName: names[userId] ?? 'Unknown',
    );

    final response =
        await _supabase
            .from(SupabaseConstants.groupMembers)
            .update({GroupMemberColumns.membershipStatus: 'removed'})
            .eq(GroupMemberColumns.groupId, groupId)
            .eq(GroupMemberColumns.userId, userId)
            .select();
    if (response.isEmpty) {
      throw Exception(
        'Membership row was not deleted — likely blocked by an RLS policy on group_members.',
      );
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final names = await fetchUserNames([currentUserId]);
    await sendSystemEvent(
      groupId: groupId,
      type: 'member_left',
      actorId: currentUserId,
      actorName: names[currentUserId] ?? 'Someone',
    );

    final response =
        await _supabase
            .from(SupabaseConstants.groupMembers)
            .update({GroupMemberColumns.membershipStatus: 'left'})
            .eq(GroupMemberColumns.groupId, groupId)
            .eq(GroupMemberColumns.userId, currentUserId)
            .eq(GroupMemberColumns.membershipStatus, 'active')
            .select();
    if (response.isEmpty) {
      throw Exception(
        'Membership row was not deleted — likely blocked by an RLS policy on group_members.',
      );
    }
  }

  Future<void> blockGroup(String groupId, {required bool wasMember}) async {
    if (wasMember) {
      final names = await fetchUserNames([currentUserId]);
      await sendSystemEvent(
        groupId: groupId,
        type: 'member_left',
        actorId: currentUserId,
        actorName: names[currentUserId] ?? 'Someone',
      );
    }

    final response =
        await _supabase
            .from(SupabaseConstants.groupMembers)
            .update({
              GroupMemberColumns.membershipStatus: 'left',
              GroupMemberColumns.isBlocked: true,
              GroupMemberColumns.blockedAt:
                  DateTime.now().toUtc().toIso8601String(),
            })
            .eq(GroupMemberColumns.groupId, groupId)
            .eq(GroupMemberColumns.userId, currentUserId)
            .select();

    if (response.isEmpty) {
      throw Exception(
        'Failed to block group — likely blocked by an RLS policy on group_members.',
      );
    }
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? avatarUrl,
  }) async {
    await _supabase
        .from(SupabaseConstants.groups)
        .update({
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        })
        .eq('id', groupId);
  }

  /// Permanently deletes the group and everything attached to it
  /// (messages, members, reactions, mentions, typing rows, calls, and the
  /// `groups` row itself) for **every** member, not just the caller.
  /// Owner-only — enforced server-side inside `delete_group_permanently`.
  Future<void> deleteGroupPermanently(String groupId) async {
    await _supabase.rpc(
      'delete_group_permanently',
      params: {'p_group_id': groupId},
    );
  }

  Future<CloudinaryUploadResult> uploadGroupAvatar(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    return await storage.uploadFile(
      file,
      'avatars',
      'groups',
      filePrefix: 'group_avatar_',
      onProgress: onProgress,
    );
  }

  Future<void> updateGroupAvatarUrl(
    String groupId,
    String newAvatarUrl,
    String? avatarPublicId,
  ) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConstants.groups)
              .update({
                'avatar_url': newAvatarUrl,
                if (avatarPublicId != null) 'avatar_public_id': avatarPublicId,
              })
              .eq('id', groupId)
              .select();

      if (response.isEmpty) {
        throw Exception('Database update blocked by RLS Policy!');
      }
    } catch (e) {
      debugPrint('Error updating group avatar: $e');
      rethrow;
    }
  }

  Future<void> updateGroupTitle(String groupId, String? title) async {
    await _supabase
        .from(SupabaseConstants.groups)
        .update({GroupColumns.title: title})
        .eq('id', groupId);
  }

  Future<void> removeGroupAvatar(String groupId) async {
    final response =
        await _supabase
            .from(SupabaseConstants.groups)
            .update({'avatar_url': null, 'avatar_public_id': null})
            .eq('id', groupId)
            .select();
    if (response.isEmpty) {
      throw Exception('Database update blocked by RLS Policy!');
    }
  }

  Future<bool> getMyMuteStatus(String groupId) async {
    final row =
        await _supabase
            .from(SupabaseConstants.groupMembers)
            .select(GroupMemberColumns.isMuted)
            .eq(GroupMemberColumns.groupId, groupId)
            .eq(GroupMemberColumns.userId, currentUserId)
            .maybeSingle();
    return (row?[GroupMemberColumns.isMuted] as bool?) ?? false;
  }

  Future<void> toggleMute(String groupId, bool muted) async {
    final response =
        await _supabase
            .from(SupabaseConstants.groupMembers)
            .update({GroupMemberColumns.isMuted: muted})
            .eq(GroupMemberColumns.groupId, groupId)
            .eq(GroupMemberColumns.userId, currentUserId)
            .select();

    if (response.isEmpty) {
      throw Exception('Update blocked by RLS or row not found');
    }
  }

  Stream<void> getGroupsListStream() {
    final controller = StreamController<void>.broadcast();
    final channelName = 'group_list_$currentUserId';
    _supabase.removeChannel(_supabase.channel(channelName));

    final channel = _supabase.channel(channelName);

    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.groupMessages,
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.groupMembers,
          callback: notify,
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  static final Map<String, _GroupHeaderStatsHub> _headerHubs = {};

  Stream<GroupHeaderStats> watchGroupHeaderStats(String groupId) {
    final hub = _headerHubs.putIfAbsent(
      groupId,
      () => _GroupHeaderStatsHub(
        supabase: _supabase,
        groupId: groupId,
        currentUserId: currentUserId,
      ),
    );
    return hub.stream;
  }

  Future<Map<String, String?>> getUserInfo(String userId) async {
    final userProfile =
        await _supabase
            .from('users')
            .select('name, image_url')
            .eq('id', userId)
            .maybeSingle();

    return {
      'name': userProfile?['name'] as String?,
      'imageUrl': userProfile?['image_url'] as String?,
    };
  }

  Future<Map<String, String>> fetchUserNames(List<String> userIds) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return {};
    final rows = await _supabase
        .from('users')
        .select('id, name')
        .inFilter('id', ids);
    return {
      for (final r in (rows as List))
        r['id'] as String: (r['name'] as String?) ?? 'Unknown',
    };
  }

  /// Writes a system/audit message into the group's timeline
  /// (e.g. "Ahmed added Sara"). Public so other group services can log
  /// their own lifecycle events without duplicating this logic.
  Future<void> sendSystemEvent({
    required String groupId,
    required String type,
    required String actorId,
    required String actorName,
    String? targetId,
    String? targetName,
  }) async {
    await _supabase.from(SupabaseConstants.groupMessages).insert({
      GroupMemberColumns.groupId: groupId,
      'sender_id': actorId,
      'sender_name': actorName,
      'message_text': _buildFallbackEventText(
        type: type,
        actorName: actorName,
        targetName: targetName,
      ),
      'message_type': GroupMessageModel.systemEventType,
      if (targetId != null) 'target_id': targetId,
      if (targetName != null) 'target_name': targetName,

      'system_event_data': {
        'type': type,
        'actor_id': actorId,
        'actor_name': actorName,
        if (targetId != null) 'target_id': targetId,
        if (targetName != null) 'target_name': targetName,
      },
    });
  }

  String _buildFallbackEventText({
    required String type,
    required String actorName,
    String? targetName,
  }) {
    switch (type) {
      case 'member_added':
        return '$actorName added $targetName';
      case 'member_removed':
        return '$actorName removed $targetName';
      case 'member_left':
        return '$actorName left the group';
      case 'member_joined_via_invite':
        return '$actorName joined via invite link';
      default:
        return '$actorName updated the group';
    }
  }
}

class _GroupHeaderStatsHub {
  _GroupHeaderStatsHub({
    required SupabaseClient supabase,
    required this.groupId,
    required this.currentUserId,
  }) : _supabase = supabase {
    _controller = StreamController<GroupHeaderStats>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
  }

  static const Duration _pollInterval = Duration(seconds: 30);
  static const Duration _debounce = Duration(milliseconds: 500);
  static const Duration _closeGrace = Duration(seconds: 5);
  static int _seq = 0;

  final SupabaseClient _supabase;
  final String groupId;
  final String currentUserId;

  late final StreamController<GroupHeaderStats> _controller;
  RealtimeChannel? _channel;
  Timer? _pollTimer;
  Timer? _debounceTimer;
  Timer? _closeTimer;
  GroupHeaderStats? _last;
  bool _fetching = false;
  bool _refetchQueued = false;

  Stream<GroupHeaderStats> get stream async* {
    final last = _last;
    if (last != null) yield last;
    yield* _controller.stream;
  }

  void _onListen() {
    _closeTimer?.cancel();
    _closeTimer = null;
    if (_channel == null) {
      _start();
    } else {
      final last = _last;
      if (last != null) _controller.add(last);
    }
  }

  void _onCancel() {
    _closeTimer?.cancel();
    _closeTimer = Timer(_closeGrace, _stop);
  }

  void _start() {
    unawaited(_fetch());
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_fetch()));

    final channel = _supabase.channel(
      'group_header_members_${groupId}_${_seq++}',
    );
    final topic = channel.topic;
    RealtimeDiagnostics.instance.onChannelCreated(
      topic,
      ownerUserId: currentUserId,
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.groupMembers,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: GroupMemberColumns.groupId,
            value: groupId,
          ),
          callback: (_) => _scheduleFetch(),
        )
        .subscribe((status, [error]) {
          switch (status) {
            case RealtimeSubscribeStatus.subscribed:
              RealtimeDiagnostics.instance.onChannelSubscribed(topic);
            case RealtimeSubscribeStatus.channelError:
            case RealtimeSubscribeStatus.timedOut:
              RealtimeDiagnostics.instance.onChannelError(
                topic,
                error ?? status,
                StackTrace.current,
              );
            case RealtimeSubscribeStatus.closed:
              break;
          }
        });
    _channel = channel;
  }

  void _stop() {
    _closeTimer = null;
    if (_controller.hasListener) return; // someone came back in time

    _pollTimer?.cancel();
    _pollTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;

    final channel = _channel;
    _channel = null;
    if (channel != null) {
      RealtimeDiagnostics.instance.onChannelClosed(channel.topic);
      unawaited(_supabase.removeChannel(channel));
    }
  }

  void _scheduleFetch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => unawaited(_fetch()));
  }

  Future<void> _fetch() async {
    if (_fetching) {
      _refetchQueued = true;
      return;
    }
    _fetching = true;
    try {
      do {
        _refetchQueued = false;
        final raw = await _supabase.rpc(
          'get_group_header_stats',
          params: {'p_group_id': groupId},
        );
        if (_controller.isClosed || !_controller.hasListener) return;

        final row = raw is List ? (raw.isEmpty ? null : raw.first) : raw;
        if (row is Map) {
          final stats = GroupHeaderStats(
            totalMembers: (row['total_members'] as num?)?.toInt() ?? 0,
            onlineCount: (row['online_count'] as num?)?.toInt() ?? 0,
          );
          _last = stats;
          _controller.add(stats);
        }
      } while (_refetchQueued);
    } catch (e) {
      debugPrint('[GroupHeaderStats] fetch error: $e');
    } finally {
      _fetching = false;
    }
  }
}
