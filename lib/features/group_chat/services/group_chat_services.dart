import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/group_chat/services/group_notification_dispatcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_storage_services.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/groupe_message_model.dart';

class GroupChatServices {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser!.id;

  SupabaseStorageServices get storage => SupabaseStorageServices.instance;

  Future<GroupModel> createGroup({
    required String name,
    String? avatarUrl,
    required List<String> memberIds,
  }) async {
    final groupData =
        await _supabase
            .from(SupabaseConstants.groups)
            .insert({
              'name': name,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
              'created_by': currentUserId,
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

  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final response = await _supabase
        .from(SupabaseConstants.groupMembers)
        .select(
          'id, group_id, user_id, role, joined_at, '
          'users!group_members_user_id_fkey(name, image_url)',
        )
        .eq(GroupMemberColumns.groupId, groupId);

    return (response as List).map((e) {
      final userInfo = e['users'] as Map<String, dynamic>? ?? {};
      return GroupMemberModel.fromMap({
        ...e,
        'user_name': userInfo['name'],
        'user_avatar': userInfo['image_url'],
      });
    }).toList();
  }

  Future<void> addMember(String groupId, String userId) async {
    await _supabase.from(SupabaseConstants.groupMembers).insert({
      GroupMemberColumns.groupId: groupId,
      GroupMemberColumns.userId: userId,
      'role': 'member',
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
          (data) => data.map((map) => GroupMessageModel.fromMap(map)).toList(),
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
    String? caption,
    GroupMessageModel? replyTo,
  }) async {
    final currentUser = _supabase.auth.currentUser!;

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
      if (caption != null) 'caption': caption,
      if (replyTo != null) ...{
        'reply_to_message_id': replyTo.id,
        'reply_to_text':
            replyTo.text.isNotEmpty ? replyTo.text : (replyTo.caption ?? ''),
        'reply_to_sender_id': replyTo.senderId,
        'reply_to_sender_name': replyTo.senderName,
        'reply_to_message_type': replyTo.messageType,
      },
    };

    final result =
        await _supabase
            .from(SupabaseConstants.groupMessages)
            .insert(insertData)
            .select()
            .single();

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
    });
  }

  Future<void> deleteGroupMessage(String messageId) async {
    await _supabase
        .from(SupabaseConstants.groupMessages)
        .delete()
        .eq('id', messageId);
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

  Future<void> updateGroupAvatarUrl(String groupId, String newAvatarUrl) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConstants.groups)
              .update({'avatar_url': newAvatarUrl})
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

  Future<String> uploadGroupAvatar(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName =
        'group_avatar_${_supabase.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    const bucket = 'avatars';
    final path = 'groups/$fileName';

    try {
      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('uploadGroupAvatar bucket=$bucket error: $e');

      try {
        final bytes = await file.readAsBytes();
        const fallbackBucket = 'chat-images';
        final fallbackPath = '${_supabase.auth.currentUser!.id}/$fileName';

        await _supabase.storage
            .from(fallbackBucket)
            .uploadBinary(
              fallbackPath,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );

        return _supabase.storage
            .from(fallbackBucket)
            .getPublicUrl(fallbackPath);
      } catch (e2) {
        debugPrint('uploadGroupAvatar fallback error: $e2');
        rethrow;
      }
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
}
