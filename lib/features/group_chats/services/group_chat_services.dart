import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/features/group_chats/services/group_notification_dispatcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/presence/models/chat_action_type.dart';
import '../../../core/presence/services/presence_service.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/cloudinary_upload_result.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_add_members_result.dart';
import '../models/group_header_stats.dart';
import '../models/group_invite_preview.dart';
import '../models/group_invite_state.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/group_presence_entry.dart';
import '../models/groupe_message_model.dart';

class GroupChatServices {
  final _supabase = SupabaseProvider.client;

  String get currentUserId => SupabaseProvider.id;

  CloudinaryStorageServices get storage => CloudinaryStorageServices.instance;

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

  static const int _membersPageSize = 20;

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
      final names = await _fetchUserNames([currentUserId, ...added]);
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

  Future<Map<String, String>> _fetchUserNames(List<String> userIds) async {
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

  Future<void> removeMember(
    String groupId,
    String userId, {
    required String actorId,
  }) async {
    final names = await _fetchUserNames([actorId, userId]);

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
    final names = await _fetchUserNames([currentUserId]);
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
      final names = await _fetchUserNames([currentUserId]);
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

  // ═══════════════════════════════════════════════════════════
  // Invite Links
  // ═══════════════════════════════════════════════════════════

  final Map<String, GroupInviteState?> _inviteStateCache = {};

  bool hasCachedInviteState(String groupId) =>
      _inviteStateCache.containsKey(groupId);

  GroupInviteState? getCachedInviteState(String groupId) =>
      _inviteStateCache[groupId];

  Future<GroupInviteState?> getGroupInviteState(String groupId) async {
    final row =
        await _supabase
            .from(SupabaseConstants.groups)
            .select('invite_hash, invite_expires_at, invite_join_count')
            .eq('id', groupId)
            .maybeSingle();

    final state =
        (row == null || row['invite_hash'] == null)
            ? null
            : GroupInviteState.fromMap(row);

    _inviteStateCache[groupId] = state;
    return state;
  }

  Future<GroupInviteState> generateGroupInviteLink(
    String groupId, {
    Duration? expiresIn,
  }) async {
    try {
      final row =
          await _supabase
              .rpc(
                'generate_group_invite_link',
                params: {
                  'p_group_id': groupId,
                  'p_expires_in_hours': expiresIn?.inHours,
                },
              )
              .single();
      final state = GroupInviteState.fromMap(row);
      _inviteStateCache[groupId] = state;
      return state;
    } catch (e, s) {
      debugPrint('❌ generateGroupInviteLink Error: $e\n$s');
      throw Exception('Failed to generate group invite link: $e');
    }
  }

  Future<void> revokeGroupInviteLink(String groupId) async {
    await _supabase.rpc(
      'revoke_group_invite_link',
      params: {'p_group_id': groupId},
    );
    _inviteStateCache[groupId] = null;
  }

  Future<GroupInvitePreview> getGroupInvitePreview(String inviteHash) async {
    final row =
        await _supabase
            .rpc(
              'get_group_invite_preview',
              params: {'p_invite_hash': inviteHash},
            )
            .single();
    return GroupInvitePreview.fromMap(row);
  }

  Future<GroupModel> joinGroupViaInvite(String inviteHash) async {
    final row =
        await _supabase
            .rpc('join_group_via_invite', params: {'p_invite_hash': inviteHash})
            .single();
    final group = GroupModel.fromMap(row);

    final names = await _fetchUserNames([currentUserId]);
    await sendSystemEvent(
      groupId: group.id,
      type: 'member_joined_via_invite',
      actorId: currentUserId,
      actorName: names[currentUserId] ?? 'Someone',
    );

    return group;
  }

  Stream<List<GroupMessageModel>> getGroupMessagesStream(String groupId) {
    return _supabase
        .from(SupabaseConstants.groupMessages)
        .stream(primaryKey: ['id'])
        .eq(GroupMemberColumns.groupId, groupId)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data
                  .map((map) => GroupMessageModel.fromMap(map))
                  .where((m) => !m.deletedFor.contains(currentUserId))
                  .toList(),
        );
  }

  Future<({GroupMessageModel message, bool isNewInsert})> sendGroupMessage({
    required String groupId,
    required String groupName,
    String? groupImageUrl,
    required String text,
    required String clientMessageId,
    String messageType = 'text',
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    int? durationSeconds,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    String? caption,
    GroupMessageModel? replyTo,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? filePublicId,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
    List<MentionRef> mentions = const [],
  }) async {
    final currentUser = SupabaseProvider.user!;

    final userProfile =
        await _supabase
            .from('users')
            .select('name, image_url')
            .eq('id', currentUser.id)
            .maybeSingle();

    final senderName = (userProfile?['name'] as String?) ?? 'Unknown';
    final senderAvatar = (userProfile?['image_url'] as String?) ?? '';

    final insertData = {
      GroupMemberColumns.groupId: groupId,
      'sender_id': currentUser.id,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      GroupMessageColumns.clientMessageId: clientMessageId,
      'message_text': text,
      'message_type': messageType,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (voiceUrl != null) 'voice_url': voiceUrl,
      if (durationSeconds != null)
        GroupMessageColumns.durationSeconds: durationSeconds,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (caption != null) 'caption': caption,
      if (imagePublicId != null) 'image_public_id': imagePublicId,
      if (videoPublicId != null) 'video_public_id': videoPublicId,
      if (voicePublicId != null) 'voice_public_id': voicePublicId,
      if (filePublicId != null) 'file_public_id': filePublicId,
      if (replyTo != null) ...{
        'reply_to_message_id': replyTo.id,
        'reply_to_text':
            replyTo.text.isNotEmpty ? replyTo.text : (replyTo.caption ?? ''),
        'reply_to_sender_id': replyTo.senderId,
        'reply_to_sender_name': replyTo.senderName,
        'reply_to_message_type': replyTo.messageType,
        if (GroupMessageModel.replyMediaUrlFrom(replyTo) != null)
          'reply_to_media_url': GroupMessageModel.replyMediaUrlFrom(replyTo),
      },

      if (forwardedFromUserId != null)
        'forwarded_from_user_id': forwardedFromUserId,
      if (forwardedFromUserName != null)
        'forwarded_from_user_name': forwardedFromUserName,
      if (forwardedFromUserAvatar != null)
        'forwarded_from_user_avatar': forwardedFromUserAvatar,
    };

    final upserted =
        await _supabase
            .from(SupabaseConstants.groupMessages)
            .upsert(
              insertData,
              onConflict: 'sender_id,${GroupMessageColumns.clientMessageId}',
              ignoreDuplicates: true,
            )
            .select();

    final Map<String, dynamic> result;
    final bool isNewInsert;
    if (upserted.isNotEmpty) {
      result = upserted.first;
      isNewInsert = true;
    } else {
      result =
          await _supabase
              .from(SupabaseConstants.groupMessages)
              .select()
              .eq('sender_id', currentUser.id)
              .eq(GroupMessageColumns.clientMessageId, clientMessageId)
              .single();
      isNewInsert = false;
    }

    final newMessageId = result['id'] as String;

    if (isNewInsert && mentions.isNotEmpty) {
      await _supabase
          .from(SupabaseConstants.groupMessageMentions)
          .insert(
            mentions
                .map(
                  (m) => {
                    GroupMessageMentionColumns.groupMessageId: newMessageId,
                    GroupMessageMentionColumns.groupId: groupId,
                    GroupMessageMentionColumns.mentionedUserId:
                        m.mentionedUserId,
                    GroupMessageMentionColumns.startIndex: m.startIndex,
                    GroupMessageMentionColumns.endIndex: m.endIndex,
                  },
                )
                .toList(),
          );
    }

    if (isNewInsert) {
      unawaited(
        GroupNotificationDispatcher.instance.notifyMessage(
          messageId: newMessageId,
          clientMessageId: clientMessageId,
          groupId: groupId,
          groupName: groupName,
          groupImageUrl: groupImageUrl ?? '',
          senderId: currentUser.id,
          senderName: senderName,
          senderAvatar: senderAvatar,
          messageBody: text,
          messageType: messageType,
          attachmentUrl: imageUrl ?? videoUrl ?? fileUrl,
          mentionedUserIds: mentions.map((m) => m.mentionedUserId).toList(),
          caption: caption,
          durationSeconds: durationSeconds,
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
          replyToMessageId: replyTo?.id,
          replyToText:
              replyTo?.text.isNotEmpty == true
                  ? replyTo?.text
                  : replyTo?.caption,
          replyToMessageType: replyTo?.messageType,
          replyToSenderId: replyTo?.senderId,
          replyToMediaUrl: GroupMessageModel.replyMediaUrlFrom(replyTo),
          forwardedFromUserId: forwardedFromUserId,
          forwardedFromUserName: forwardedFromUserName,
          forwardedFromUserAvatar: forwardedFromUserAvatar,
        ),
      );
    }

    return (
      message: GroupMessageModel.fromMap({
        ...result,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
      }).copyWith(mentions: mentions),
      isNewInsert: isNewInsert,
    );
  }

  Future<void> editGroupMessage({
    required String messageId,
    required String newText,
    required bool isCaptionEdit,
    required String groupId,
    List<MentionRef> mentions = const [],
  }) async {
    await _supabase
        .from(SupabaseConstants.groupMessages)
        .update({
          if (isCaptionEdit) 'caption': newText else 'message_text': newText,
          'is_edited': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);

    await _supabase
        .from(SupabaseConstants.groupMessageMentions)
        .delete()
        .eq(GroupMessageMentionColumns.groupMessageId, messageId);

    if (mentions.isNotEmpty) {
      await _supabase
          .from(SupabaseConstants.groupMessageMentions)
          .insert(
            mentions
                .map(
                  (m) => {
                    GroupMessageMentionColumns.groupMessageId: messageId,
                    GroupMessageMentionColumns.groupId: groupId,
                    GroupMessageMentionColumns.mentionedUserId:
                        m.mentionedUserId,
                    GroupMessageMentionColumns.startIndex: m.startIndex,
                    GroupMessageMentionColumns.endIndex: m.endIndex,
                  },
                )
                .toList(),
          );
    }
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

  Future<void> deleteGroupMessage(String messageId) async {
    await MediaCleanupService.instance.deleteWithMedia(
      table: SupabaseConstants.groupMessages,
      id: messageId,
    );
  }

  Future<void> deleteGroupMessageForMe({
    required String messageId,
    required String currentUserId,
  }) async {
    final row =
        await _supabase
            .from(SupabaseConstants.groupMessages)
            .select(GroupMessageColumns.deletedFor)
            .eq('id', messageId)
            .maybeSingle();

    final current =
        (row?[GroupMessageColumns.deletedFor] as List?)?.cast<String>() ?? [];
    final updated = {...current, currentUserId}.toList();

    await _supabase
        .from(SupabaseConstants.groupMessages)
        .update({GroupMessageColumns.deletedFor: updated})
        .eq('id', messageId);
  }

  Future<void> deleteGroupMessagesForMe({
    required List<GroupMessageModel> messages,
    required String currentUserId,
  }) async {
    for (final m in messages) {
      final updated = {...m.deletedFor, currentUserId}.toList();
      await _supabase
          .from(SupabaseConstants.groupMessages)
          .update({GroupMessageColumns.deletedFor: updated})
          .eq('id', m.id);
    }
  }

  Future<void> deleteGroupMessagesForEveryone(List<String> messageIds) async {
    for (final id in messageIds) {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.groupMessages,
        id: id,
      );
    }
  }

  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required String groupId,
    String? currentEmoji,
  }) async {
    final query = _supabase
        .from(SupabaseConstants.groupMessageReactions)
        .delete()
        .eq('message_id', messageId)
        .eq(GroupMemberColumns.userId, currentUserId);

    await query;

    if (currentEmoji == emoji) {
      return;
    }

    await _supabase.from(SupabaseConstants.groupMessageReactions).insert({
      'message_id': messageId,
      GroupMemberColumns.userId: currentUserId,
      'reaction': emoji,
      GroupMemberColumns.groupId: groupId,
    });
  }

  Stream<List<Map<String, dynamic>>> getReactionsStream(String groupId) {
    return _supabase
        .from(SupabaseConstants.groupMessageReactions)
        .stream(primaryKey: ['id'])
        .eq(GroupMemberColumns.groupId, groupId)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  Stream<List<Map<String, dynamic>>> getMentionsStream(String groupId) {
    return _supabase
        .from(SupabaseConstants.groupMessageMentions)
        .stream(primaryKey: ['id'])
        .eq(GroupMemberColumns.groupId, groupId)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  static const int _presenceStaleAfterSeconds = 5;
  static const int _presenceWatchdogTickSeconds = 2;

  Stream<Map<String, GroupPresenceSnapshot>> watchAllGroupsPresence() {
    final controller =
        StreamController<Map<String, GroupPresenceSnapshot>>.broadcast();
    List<Map<String, dynamic>> latestRows = const [];

    final Map<String, Map<String, String?>> userCache = {};
    final Map<String, DateTime> localReceiveTime = {};
    final Map<String, String> lastUpdatedAt = {};

    Future<Map<String, GroupPresenceSnapshot>> computeSnapshot() async {
      final now = DateTime.now();
      final nowUtc = now.toUtc();
      final Map<String, Map<ChatActionType, List<GroupPresenceEntry>>> grouped =
          {};

      for (final row in latestRows) {
        final actionType = ChatActionTypeX.fromValue(row['action_type']);
        if (actionType == ChatActionType.none) continue;

        final groupId = row[GroupTypingColumns.groupId] as String;
        final userId = row[GroupTypingColumns.userId] as String;
        if (userId == currentUserId) continue;

        final updatedAtRaw = row[GroupTypingColumns.updatedAt];
        if (updatedAtRaw != null) {
          final updatedAt = DateTime.parse(updatedAtRaw.toString()).toUtc();
          if (nowUtc.difference(updatedAt).inMinutes > 5) {
            continue;
          }
        }

        if (!localReceiveTime.containsKey(userId)) continue;
        final receivedAt = localReceiveTime[userId]!;
        if (now.difference(receivedAt).inSeconds > _presenceStaleAfterSeconds) {
          continue;
        }

        if (!userCache.containsKey(userId)) {
          try {
            final data =
                await _supabase
                    .from('users')
                    .select('name, image_url')
                    .eq('id', userId)
                    .maybeSingle();
            userCache[userId] = {
              'name': data?['name'] as String? ?? 'Someone',
              'avatar': data?['image_url'] as String?,
            };
          } catch (_) {
            userCache[userId] = {'name': 'Someone', 'avatar': null};
          }
        }

        final userInfo = userCache[userId]!;
        grouped.putIfAbsent(groupId, () => {});
        grouped[groupId]!.putIfAbsent(actionType, () => []);
        grouped[groupId]![actionType]!.add(
          GroupPresenceEntry(
            userId: userId,
            userName: userInfo['name'] ?? 'Someone',
            userAvatar: userInfo['avatar'],
            actionType: actionType,
          ),
        );
      }
      return grouped.map((k, v) => MapEntry(k, GroupPresenceSnapshot(v)));
    }

    void emit() async {
      if (controller.isClosed) return;
      controller.add(await computeSnapshot());
    }

    final sub = SupabaseProvider.client
        .from(SupabaseConstants.groupTypingStatus)
        .stream(
          primaryKey: [GroupTypingColumns.groupId, GroupTypingColumns.userId],
        )
        .listen(
          (rows) {
            for (final row in rows) {
              final uId = row[GroupTypingColumns.userId] as String;
              if (row['action_type'] != 'none') {
                final updatedAtStr =
                    row[GroupTypingColumns.updatedAt]?.toString() ?? '';
                if (lastUpdatedAt[uId] != updatedAtStr) {
                  localReceiveTime[uId] = DateTime.now();
                  lastUpdatedAt[uId] = updatedAtStr;
                }
              }
            }
            latestRows = rows;
            emit();
          },
          onError:
              (e) => debugPrint('[watchAllGroupsPresence] stream error: $e'),
        );

    final watchdog = Timer.periodic(
      const Duration(seconds: _presenceWatchdogTickSeconds),
      (_) => emit(),
    );

    controller.onCancel = () {
      sub.cancel();
      watchdog.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> setGroupAction(
    String groupId,
    ChatActionType actionType, {
    required bool isMember,
  }) async {
    if (!isMember) return;
    try {
      await _supabase.from(SupabaseConstants.groupTypingStatus).upsert(
        {
          GroupTypingColumns.groupId: groupId,
          GroupTypingColumns.userId: currentUserId,
          'action_type': actionType.value,
          GroupTypingColumns.updatedAt:
              DateTime.now().toUtc().toIso8601String(),
        },
        onConflict:
            '${GroupTypingColumns.groupId},${GroupTypingColumns.userId}',
      );
    } catch (e) {
      debugPrint('[setGroupAction] FAILED to write presence: $e');
    }
  }

  Stream<GroupPresenceSnapshot> watchGroupPresence(String groupId) {
    final controller = StreamController<GroupPresenceSnapshot>.broadcast();
    List<Map<String, dynamic>> latestRows = const [];

    final Map<String, Map<String, String?>> userCache = {};
    final Map<String, DateTime> localReceiveTime = {};
    final Map<String, String> lastUpdatedAt = {};

    Future<GroupPresenceSnapshot> computeSnapshot() async {
      final Map<ChatActionType, List<GroupPresenceEntry>> grouped = {};
      final now = DateTime.now();
      final nowUtc = now.toUtc();

      for (final row in latestRows) {
        final actionType = ChatActionTypeX.fromValue(row['action_type']);
        if (actionType == ChatActionType.none) continue;

        final userId = row[GroupTypingColumns.userId] as String;
        if (userId == currentUserId) continue;

        final updatedAtRaw = row[GroupTypingColumns.updatedAt];
        if (updatedAtRaw != null) {
          final updatedAt = DateTime.parse(updatedAtRaw.toString()).toUtc();
          if (nowUtc.difference(updatedAt).inMinutes > 5) {
            continue;
          }
        }

        if (!localReceiveTime.containsKey(userId)) continue;
        final receivedAt = localReceiveTime[userId]!;
        if (now.difference(receivedAt).inSeconds > _presenceStaleAfterSeconds) {
          continue;
        }

        if (!userCache.containsKey(userId)) {
          try {
            final data =
                await _supabase
                    .from('users')
                    .select('name, image_url')
                    .eq('id', userId)
                    .maybeSingle();
            userCache[userId] = {
              'name': data?['name'] as String? ?? 'Someone',
              'avatar': data?['image_url'] as String?,
            };
          } catch (_) {
            userCache[userId] = {'name': 'Someone', 'avatar': null};
          }
        }

        final userInfo = userCache[userId]!;
        grouped.putIfAbsent(actionType, () => []);
        grouped[actionType]!.add(
          GroupPresenceEntry(
            userId: userId,
            userName: userInfo['name'] ?? 'Someone',
            userAvatar: userInfo['avatar'],
            actionType: actionType,
          ),
        );
      }
      return GroupPresenceSnapshot(grouped);
    }

    void emit() async {
      if (controller.isClosed) return;
      controller.add(await computeSnapshot());
    }

    final sub = _supabase
        .from(SupabaseConstants.groupTypingStatus)
        .stream(
          primaryKey: [GroupTypingColumns.groupId, GroupTypingColumns.userId],
        )
        .eq(GroupTypingColumns.groupId, groupId)
        .listen((rows) {
          for (final row in rows) {
            final uId = row[GroupTypingColumns.userId] as String;
            if (row['action_type'] != 'none') {
              final updatedAtStr =
                  row[GroupTypingColumns.updatedAt]?.toString() ?? '';
              if (lastUpdatedAt[uId] != updatedAtStr) {
                localReceiveTime[uId] = DateTime.now();
                lastUpdatedAt[uId] = updatedAtStr;
              }
            }
          }
          latestRows = rows;
          emit();
        }, onError: (e) => debugPrint('[watchGroupPresence] stream error: $e'));

    final watchdog = Timer.periodic(
      const Duration(seconds: _presenceWatchdogTickSeconds),
      (_) => emit(),
    );

    controller.onCancel = () {
      sub.cancel();
      watchdog.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // Group members and their status

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

  // Group Header stats

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

  Future<void> markGroupMessagesRead(String groupId) async {
    try {
      await _supabase.rpc(
        'mark_group_messages_read',
        params: {'p_group_id': groupId, 'p_user_id': currentUserId},
      );
    } catch (e) {
      debugPrint('markGroupMessagesRead error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getReadReceiptsStream(String groupId) {
    return _supabase
        .from(SupabaseConstants.groupMessages)
        .stream(primaryKey: ['id'])
        .eq(GroupMemberColumns.groupId, groupId)
        .map(
          (data) =>
              data
                  .where((m) => m['sender_id'] == currentUserId)
                  .map((m) => {'id': m['id'], 'read_by': m['read_by'] ?? []})
                  .toList(),
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

  Future<List<GroupMessageModel>> getGroupMediaPreview({
    required String groupId,
    int limit = 6,
  }) async {
    final response = await _supabase
        .from(SupabaseConstants.groupMessages)
        .select()
        .eq(GroupMemberColumns.groupId, groupId)
        .inFilter('message_type', ['image', 'video', 'voice'])
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => GroupMessageModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GroupMessageModel>> getGroupMediaMessages({
    required String groupId,
    required String messageType,
    int limit = 100,
  }) async {
    final response = await _supabase
        .from(SupabaseConstants.groupMessages)
        .select()
        .eq(GroupMemberColumns.groupId, groupId)
        .eq('message_type', messageType)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => GroupMessageModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GroupMessageModel>> getGroupLinkMessages({
    required String groupId,
    int limit = 100,
  }) async {
    final response = await _supabase
        .from(SupabaseConstants.groupMessages)
        .select()
        .eq(GroupMemberColumns.groupId, groupId)
        .eq('message_type', 'text')
        .ilike('message_text', '%http%')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => GroupMessageModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
