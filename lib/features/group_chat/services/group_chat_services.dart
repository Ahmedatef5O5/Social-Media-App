import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/fcm_services.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/groupe_message_model.dart';

class GroupChatServices {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser!.id;

  Future<GroupModel> createGroup({
    required String name,
    String? avatarUrl,
    required List<String> memberIds,
  }) async {
    final groupData =
        await _supabase
            .from('groups')
            .insert({
              'name': name,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
              'created_by': currentUserId,
            })
            .select()
            .single();

    final newGroupId = groupData['id'] as String;

    // Add creator as admin
    await _supabase.from('group_members').insert({
      'group_id': newGroupId,
      'user_id': currentUserId,
      'role': 'admin',
    });

    if (memberIds.isNotEmpty) {
      await _supabase
          .from('group_members')
          .insert(
            memberIds
                .map(
                  (uid) => {
                    'group_id': newGroupId,
                    'user_id': uid,
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
        .from('group_members')
        .select(
          'id, group_id, user_id, role, joined_at, '
          'users!group_members_user_id_fkey(name, image_url)',
        )
        .eq('group_id', groupId);

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
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
    });
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _supabase
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
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
        .from('groups')
        .update({
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        })
        .eq('id', groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _supabase.from('groups').delete().eq('id', groupId);
  }

  Stream<List<GroupMessageModel>> getGroupMessagesStream(String groupId) {
    return _supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
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

    // Get sender profile
    final userProfile =
        await _supabase
            .from('users')
            .select('name, image_url')
            .eq('id', currentUser.id)
            .maybeSingle();

    final senderName = (userProfile?['name'] as String?) ?? 'Unknown';
    final senderAvatar = (userProfile?['image_url'] as String?) ?? '';

    final insertData = {
      'group_id': groupId,
      'sender_id': currentUser.id,
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
            .from('group_messages')
            .insert(insertData)
            .select()
            .single();

    _notifyGroupMembers(
      groupId: groupId,
      groupName: groupName,
      senderId: currentUser.id,
      senderName: senderName,
      senderAvatar: senderAvatar,
      messageBody: text.isNotEmpty ? text : (caption ?? ''),
      messageType: messageType,
    );

    return GroupMessageModel.fromMap({
      ...result,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
    });
  }

  Future<void> _notifyGroupMembers({
    required String groupId,
    required String groupName,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String messageBody,
    required String messageType,
  }) async {
    try {
      final membersData = await _supabase
          .from('group_members')
          .select('user_id, users!group_members_user_id_fkey(fcm_token)')
          .eq('group_id', groupId)
          .neq('user_id', senderId);

      final fcmService = FcmService.instance;

      for (final member in membersData as List) {
        final userInfo = member['users'] as Map<String, dynamic>?;
        final token = userInfo?['fcm_token'] as String?;
        if (token == null || token.isEmpty) continue;

        await fcmService.sendGroupNotification(
          receiverFcmToken: token,
          groupId: groupId,
          groupName: groupName,
          senderName: senderName,
          messageBody: messageBody,
          messageType: messageType,
          senderImageUrl: senderAvatar,
        );
      }
    } catch (e) {
      debugPrint('Group FCM notify error: $e');
    }
  }

  Future<void> deleteGroupMessage(String messageId) async {
    await _supabase.from('group_messages').delete().eq('id', messageId);
  }

  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    String? currentEmoji,
  }) async {
    if (currentEmoji == emoji) {
      await _supabase
          .from('group_message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', currentUserId);
    } else {
      await _supabase.from('group_message_reactions').upsert({
        'message_id': messageId,
        'user_id': currentUserId,
        'reaction': emoji,
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getReactionsStream(String groupId) {
    return _supabase
        .from('group_message_reactions')
        .stream(primaryKey: ['id'])
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  Future<void> setTyping(String groupId, bool isTyping) async {
    await _supabase.from('group_typing_status').upsert({
      'group_id': groupId,
      'user_id': currentUserId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<String>> getTypingUsersStream(String groupId) {
    return _supabase
        .from('group_typing_status')
        .stream(primaryKey: ['group_id', 'user_id'])
        .eq('group_id', groupId)
        .map((data) {
          final cutoff = DateTime.now().subtract(const Duration(seconds: 10));
          return data
              .where((row) {
                final isTyping = row['is_typing'] as bool? ?? false;
                final updatedAt =
                    row['updated_at'] != null
                        ? DateTime.parse(row['updated_at'] as String)
                        : DateTime.fromMillisecondsSinceEpoch(0);
                return isTyping &&
                    updatedAt.isAfter(cutoff) &&
                    row['user_id'] != currentUserId;
              })
              .map((row) => row['user_id'] as String)
              .toList();
        });
  }

  Future<void> markGroupMessagesRead(String groupId) async {
    try {
      await _supabase.rpc(
        'mark_group_messages_read',
        params: {'p_group_id': groupId, 'p_user_id': currentUserId},
      );
    } catch (_) {}
  }

  Future<String> uploadGroupFile(
    File file,
    String type, {
    Function(double)? onProgress,
    dio_pkg.CancelToken? cancelToken,
  }) async {
    if (!await file.exists()) {
      throw Exception('File not found: ${file.path}');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'group_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket =
        type == 'image'
            ? 'chat-images'
            : type == 'video'
            ? 'chat-videos'
            : 'chat-voices';
    final path = '$currentUserId/$fileName';
    final storageUrl =
        '${AppSecrets.supabaseUrl}/storage/v1/object/$bucket/$path';

    final fileBytes = await file.readAsBytes();
    final dioInstance = dio_pkg.Dio();

    final response = await dioInstance.put(
      storageUrl,
      data: fileBytes,
      cancelToken: cancelToken,
      options: dio_pkg.Options(
        headers: {
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken}',
          'Content-Type':
              type == 'image'
                  ? 'image/$ext'
                  : type == 'video'
                  ? 'video/$ext'
                  : 'audio/$ext',
        },
      ),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusMessage}');
    }

    return '${AppSecrets.supabaseUrl}/storage/v1/object/public/$bucket/$path';
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
          table: 'group_messages',
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
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
