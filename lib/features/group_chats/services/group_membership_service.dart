import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/presence/services/presence_service.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/cloudinary_upload_result.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_add_members_result.dart';
import '../models/group_header_stats.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/groupe_message_model.dart';

class GroupMembershipService {
  final _supabase = SupabaseProvider.client;

  String get currentUserId => SupabaseProvider.id;

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

  Stream<GroupHeaderStats> watchGroupHeaderStats(String groupId) {
    final controller = StreamController<GroupHeaderStats>.broadcast();
    Set<String> memberIds = {};
    final Map<String, bool> onlineMap = {};

    void emitStats() {
      if (controller.isClosed) return;
      final online = memberIds.where((id) => onlineMap[id] == true).length;
      controller.add(
        GroupHeaderStats(totalMembers: memberIds.length, onlineCount: online),
      );
    }

    Future<void> refreshMembers() async {
      final rows = await _supabase
          .from(SupabaseConstants.groupMembers)
          .select(GroupMemberColumns.userId)
          .eq(GroupMemberColumns.groupId, groupId)
          .eq(GroupMemberColumns.membershipStatus, 'active');
      memberIds =
          (rows as List)
              .map((r) => r[GroupMemberColumns.userId] as String)
              .toSet();
      emitStats();
    }

    refreshMembers();

    final membersChannel =
        _supabase
            .channel('group_header_members_$groupId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: SupabaseConstants.groupMembers,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: GroupMemberColumns.groupId,
                value: groupId,
              ),
              callback: (_) => refreshMembers(),
            )
            .subscribe();

    final presenceChannel =
        _supabase
            .channel('group_header_presence_$groupId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: SupabaseConstants.userPresence,
              callback: (payload) {
                final record =
                    payload.eventType == PostgresChangeEvent.delete
                        ? payload.oldRecord
                        : payload.newRecord;
                final userId = record[PresenceColumns.userId] as String?;
                if (userId == null || !memberIds.contains(userId)) return;
                final updatedAtRaw = record[PresenceColumns.updatedAt];
                onlineMap[userId] = PresenceService.isConsideredOnline(
                  isOnline: record[PresenceColumns.isOnline] as bool? ?? false,
                  updatedAt:
                      updatedAtRaw != null
                          ? DateTime.parse(updatedAtRaw.toString())
                          : null,
                );
                emitStats();
              },
            )
            .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(membersChannel);
      _supabase.removeChannel(presenceChannel);
      controller.close();
    };
    return controller.stream;
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

  /// Batched user-name lookup shared by every membership/audit action
  /// (and reused by [GroupInviteService] for the "joined via invite" event).
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
