import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/features/group_chats/services/group_notification_dispatcher.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/groupe_message_model.dart';

class GroupMessagingService {
  final _supabase = SupabaseProvider.client;

  String get currentUserId => SupabaseProvider.id;

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

    // Same idempotency pattern as ChatMessagesService.sendMessage (single
    // chat): `ignoreDuplicates: true` maps to
    // `INSERT ... ON CONFLICT (sender_id, client_message_id) DO NOTHING`,
    // so a retry that reuses the same clientMessageId never creates a
    // second row and never overwrites the original row's content.
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
      // Conflict: a row for this (senderId, clientMessageId) already
      // exists — recover it instead of treating this as a new send. Do
      // NOT re-insert mentions or re-fire the notification below: both
      // already happened on the original successful attempt.
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
