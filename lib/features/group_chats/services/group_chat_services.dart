import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/features/group_chats/services/group_notification_dispatcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/cloudinary_upload_result.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
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
    final groupData =
        await _supabase
            .from(SupabaseConstants.groups)
            .insert({
              GroupColumns.name: name,
              if (avatarUrl != null) GroupColumns.avatarUrl: avatarUrl,
              if (avatarPublicId != null)
                GroupColumns.avatarPublicId: avatarPublicId,
              GroupColumns.createdBy: currentUserId,
            })
            .select()
            .single();

    final newGroupId = groupData['id'] as String;

    await _supabase.from(SupabaseConstants.groupMembers).insert({
      GroupMemberColumns.groupId: newGroupId,
      GroupMemberColumns.userId: currentUserId,
      'role': 'admin',
    });

    if (memberIds.isNotEmpty) {
      await _supabase
          .from(SupabaseConstants.groupMembers)
          .insert(
            memberIds
                .map(
                  (uid) => {
                    GroupMemberColumns.groupId: newGroupId,
                    GroupMemberColumns.userId: uid,
                    'role': 'member',
                  },
                )
                .toList(),
          );
    }

    return GroupModel.fromMap(groupData);
  }

  Future<List<GroupModel>> getMyGroups() async {
    final response = await _supabase.rpc(
      'get_my_groups',
      params: {'p_user_id': currentUserId},
    );
    if (response == null) return [];
    return (response as List)
        .map((e) => GroupModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static const int _membersPageSize = 20;

  Future<({List<GroupMemberModel> members, int totalCount})>
  getGroupMembersPaginated(
    String groupId, {
    int page = 0,
    int pageSize = _membersPageSize,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await _supabase
        .from(SupabaseConstants.groupMembers)
        .select(
          'id, ${GroupMemberColumns.groupId}, ${GroupMemberColumns.userId}, '
          '${GroupMemberColumns.role}, ${GroupMemberColumns.joinedAt}, '
          'users!${SupabaseConstants.groupMembers}'
          '_${GroupMemberColumns.userId}_fkey'
          '(${UserColumns.name}, ${UserColumns.imageUrl})',
        )
        .eq(GroupMemberColumns.groupId, groupId)
        .order(GroupMemberColumns.role, ascending: true)
        .order(GroupMemberColumns.joinedAt, ascending: false)
        .range(from, to)
        .count(CountOption.exact);

    final dataList = response.data as List;

    final members =
        dataList.map((e) {
          final userInfo = e['users'] as Map<String, dynamic>? ?? {};
          return GroupMemberModel.fromMap({
            ...e,
            'user_name': userInfo[UserColumns.name],
            'user_avatar': userInfo[UserColumns.imageUrl],
          });
        }).toList();

    final total = response.count;

    return (members: members, totalCount: total);
  }

  Future<List<String>> getGroupMemberIds(String groupId) async {
    final response = await _supabase
        .from(SupabaseConstants.groupMembers)
        .select(GroupMemberColumns.userId)
        .eq(GroupMemberColumns.groupId, groupId);
    return (response as List)
        .map((row) => row[GroupMemberColumns.userId] as String)
        .toList();
  }

  Future<void> addMember(String groupId, String userId) async {
    await _supabase.from(SupabaseConstants.groupMembers).insert({
      GroupMemberColumns.groupId: groupId,
      GroupMemberColumns.userId: userId,
      'role': 'member',
    });
  }

  Future<void> addMembers(String groupId, List<String> userIds) async {
    if (userIds.isEmpty) return;
    await _supabase.from(SupabaseConstants.groupMembers).insert({
      userIds
          .map(
            (uid) => {
              GroupMemberColumns.groupId: groupId,
              GroupMemberColumns.userId: userIds,
              'role': 'member',
            },
          )
          .toList(),
    });
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _supabase
        .from(SupabaseConstants.groupMembers)
        .delete()
        .eq(GroupMemberColumns.groupId, groupId)
        .eq(GroupMemberColumns.userId, userId);
  }

  Future<void> leaveGroup(String groupId) async {
    await removeMember(groupId, currentUserId);
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

  Future<void> deleteGroup(String groupId) async {
    await _supabase.from(SupabaseConstants.groups).delete().eq('id', groupId);
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

  Future<GroupMessageModel> sendGroupMessage({
    required String groupId,
    required String groupName,
    required String text,
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
      },

      if (forwardedFromUserId != null)
        'forwarded_from_user_id': forwardedFromUserId,
      if (forwardedFromUserName != null)
        'forwarded_from_user_name': forwardedFromUserName,
      if (forwardedFromUserAvatar != null)
        'forwarded_from_user_avatar': forwardedFromUserAvatar,
    };

    final result =
        await _supabase
            .from(SupabaseConstants.groupMessages)
            .insert(insertData)
            .select()
            .single();

    final newMessageId = result['id'] as String;

    if (mentions.isNotEmpty) {
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

    unawaited(
      GroupNotificationDispatcher.instance.notifyMessage(
        groupId: groupId,
        groupName: groupName,
        senderId: currentUser.id,
        senderName: senderName,
        senderAvatar: senderAvatar,
        messageBody: text,
        messageType: messageType,
      ),
    );

    return GroupMessageModel.fromMap({
      ...result,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
    }).copyWith(mentions: mentions);
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

  Future<void> setTyping(String groupId, bool isTyping) async {
    await _supabase.from(SupabaseConstants.groupTypingStatus).upsert({
      GroupMemberColumns.groupId: groupId,
      GroupMemberColumns.userId: currentUserId,
      'is_typing': isTyping,
      PresenceColumns.updatedAt: DateTime.now().toIso8601String(),
    });
  }

  Stream<List<String>> getTypingUsersStream(String groupId) {
    return _supabase
        .from(SupabaseConstants.groupTypingStatus)
        .stream(
          primaryKey: [GroupMemberColumns.groupId, GroupMemberColumns.userId],
        )
        .eq(GroupMemberColumns.groupId, groupId)
        .map((data) {
          final cutoff = DateTime.now().subtract(const Duration(seconds: 10));
          return data
              .where((row) {
                final isTyping = row['is_typing'] as bool? ?? false;
                final updatedAt =
                    row[PresenceColumns.updatedAt] != null
                        ? DateTime.parse(
                          row[PresenceColumns.updatedAt] as String,
                        )
                        : DateTime.fromMillisecondsSinceEpoch(0);
                return isTyping &&
                    updatedAt.isAfter(cutoff) &&
                    row[GroupMemberColumns.userId] != currentUserId;
              })
              .map((row) => row[GroupMemberColumns.userId] as String)
              .toList();
        });
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
