import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/message_model.dart';
import 'chat_notification_dispatcher.dart';

class ChatMessagesService {
  final _supabase = SupabaseProvider.client;

  Stream<List<MessageModel>> getMessagesStream({
    required String senderId,
    required String receiverId,
  }) {
    final conversationId = ChatHelper.buildConversationId(senderId, receiverId);

    return _supabase
        .from(SupabaseConstants.messages)
        .stream(primaryKey: [MessagesColumns.id])
        .eq(MessagesColumns.conversationId, conversationId)
        .order(MessagesColumns.createdAt, ascending: false)
        .map(
          (data) =>
              data
                  .map(MessageModel.fromJson)
                  .where((m) => !m.deletedFor.contains(senderId))
                  .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getChatMedia(String receiverId) async {
    final currentUserId = SupabaseProvider.id;

    try {
      final response = await _supabase
          .from(SupabaseConstants.messages)
          .select(
            '${MessagesColumns.imageUrl}, ${MessagesColumns.videoUrl}, ${MessagesColumns.voiceUrl}, ${MessagesColumns.messageType}',
          )
          .or(
            '${MessagesColumns.senderId}.eq.$currentUserId,${MessagesColumns.senderId}.eq.$receiverId',
          )
          .or(
            '${MessagesColumns.receiverId}.eq.$currentUserId,${MessagesColumns.receiverId}.eq.$receiverId',
          )
          .filter(MessagesColumns.messageType, 'in', [
            'image',
            'video',
            'voice',
          ])
          .order(MessagesColumns.createdAt, ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching media: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getMediaPreview({
    required String senderId,
    required String receiverId,
    int limit = 6,
  }) async {
    final conversationId = ChatHelper.buildConversationId(senderId, receiverId);
    final response = await _supabase
        .from(SupabaseConstants.messages)
        .select()
        .eq(MessagesColumns.conversationId, conversationId)
        .inFilter(MessagesColumns.messageType, ['image', 'video', 'voice'])
        .order(MessagesColumns.createdAt, ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> getMediaMessages({
    required String senderId,
    required String receiverId,
    required String messageType,
    int limit = 100,
  }) async {
    final conversationId = ChatHelper.buildConversationId(senderId, receiverId);
    final response = await _supabase
        .from(SupabaseConstants.messages)
        .select()
        .eq(MessagesColumns.conversationId, conversationId)
        .eq(MessagesColumns.messageType, messageType)
        .order(MessagesColumns.createdAt, ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> getLinkMessages({
    required String senderId,
    required String receiverId,
    int limit = 100,
  }) async {
    final conversationId = ChatHelper.buildConversationId(senderId, receiverId);
    final response = await _supabase
        .from(SupabaseConstants.messages)
        .select()
        .eq(MessagesColumns.conversationId, conversationId)
        .eq(MessagesColumns.messageType, 'text')
        .ilike(MessagesColumns.messageText, '%http%')
        .order(MessagesColumns.createdAt, ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({String id, DateTime createdAt})> sendMessage({
    required String senderId,
    required String receiverId,
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
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
    String? replyToMediaUrl,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? filePublicId,
    String? replyToStoryId,
    String? replyToStoryAuthorId,
    String? replyToStoryType,
    String? replyToStoryMediaUrl,
    String? replyToStoryText,
    String? replyToStoryBgColor,
    int? replyToStoryDurationSeconds,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
  }) async {
    final insertData = {
      MessagesColumns.senderId: senderId,
      MessagesColumns.receiverId: receiverId,
      MessagesColumns.clientMessageId: clientMessageId,
      MessagesColumns.messageText: text,
      MessagesColumns.messageType: messageType,
      if (imageUrl != null) MessagesColumns.imageUrl: imageUrl,
      if (videoUrl != null) MessagesColumns.videoUrl: videoUrl,
      if (voiceUrl != null) MessagesColumns.voiceUrl: voiceUrl,
      if (durationSeconds != null)
        MessagesColumns.durationSeconds: durationSeconds,
      if (fileUrl != null) MessagesColumns.fileUrl: fileUrl,
      if (fileName != null) MessagesColumns.fileName: fileName,
      if (fileSizeBytes != null) MessagesColumns.fileSizeBytes: fileSizeBytes,
      if (caption != null) MessagesColumns.caption: caption,
      if (replyToMessageId != null)
        MessagesColumns.replyToMessageId: replyToMessageId,
      if (replyToText != null) MessagesColumns.replyToText: replyToText,
      if (replyToMessageType != null)
        MessagesColumns.replyToMessageType: replyToMessageType,
      if (replyToSenderId != null)
        MessagesColumns.replyToSenderId: replyToSenderId,
      if (replyToMediaUrl != null)
        MessagesColumns.replyToMediaUrl: replyToMediaUrl,
      if (imagePublicId != null) MessagesColumns.imagePublicId: imagePublicId,
      if (videoPublicId != null) MessagesColumns.videoPublicId: videoPublicId,
      if (voicePublicId != null) MessagesColumns.voicePublicId: voicePublicId,
      if (filePublicId != null) MessagesColumns.filePublicId: filePublicId,
      if (replyToStoryId != null)
        MessagesColumns.replyToStoryId: replyToStoryId,
      if (replyToStoryAuthorId != null)
        MessagesColumns.replyToStoryAuthorId: replyToStoryAuthorId,
      if (replyToStoryType != null)
        MessagesColumns.replyToStoryType: replyToStoryType,
      if (replyToStoryMediaUrl != null)
        MessagesColumns.replyToStoryMediaUrl: replyToStoryMediaUrl,
      if (replyToStoryText != null)
        MessagesColumns.replyToStoryText: replyToStoryText,
      if (replyToStoryBgColor != null)
        MessagesColumns.replyToStoryBgColor: replyToStoryBgColor,
      if (replyToStoryDurationSeconds != null)
        MessagesColumns.replyToStoryDurationSeconds:
            replyToStoryDurationSeconds,
      if (forwardedFromUserId != null)
        MessagesColumns.forwardedFromUserId: forwardedFromUserId,
      if (forwardedFromUserName != null)
        MessagesColumns.forwardedFromUserName: forwardedFromUserName,
      if (forwardedFromUserAvatar != null)
        MessagesColumns.forwardedFromUserAvatar: forwardedFromUserAvatar,
    };

    final upserted = await _supabase
        .from(SupabaseConstants.messages)
        .upsert(
          insertData,
          onConflict:
              '${MessagesColumns.senderId},${MessagesColumns.clientMessageId}',
          ignoreDuplicates: true,
        )
        .select('${MessagesColumns.id}, ${MessagesColumns.createdAt}');

    final String newMessageId;
    final DateTime serverCreatedAt;
    final bool isNewInsert;
    if (upserted.isNotEmpty) {
      newMessageId = upserted.first[MessagesColumns.id] as String;
      serverCreatedAt = DateTime.parse(
        upserted.first[MessagesColumns.createdAt] as String,
      );
      isNewInsert = true;
    } else {
      final existing =
          await _supabase
              .from(SupabaseConstants.messages)
              .select('${MessagesColumns.id}, ${MessagesColumns.createdAt}')
              .eq(MessagesColumns.senderId, senderId)
              .eq(MessagesColumns.clientMessageId, clientMessageId)
              .single();
      newMessageId = existing[MessagesColumns.id] as String;
      serverCreatedAt = DateTime.parse(
        existing[MessagesColumns.createdAt] as String,
      );
      isNewInsert = false;
    }

    if (isNewInsert && messageType != 'call') {
      final senderInfo = await getCurrentUserInfo(senderId);
      unawaited(
        ChatNotificationDispatcher.instance.notifyMessage(
          messageId: newMessageId,
          clientMessageId: clientMessageId,
          senderId: senderId,
          receiverId: receiverId,
          senderName: senderInfo['name'] ?? 'Unknown',
          senderImageUrl: senderInfo['imageUrl'] ?? '',
          messageBody: text,
          messageType: messageType,
          attachmentUrl: imageUrl ?? videoUrl ?? voiceUrl ?? fileUrl,
          caption: caption,
          durationSeconds: durationSeconds,
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
          replyToMessageId: replyToMessageId,
          replyToText: replyToText,
          replyToMessageType: replyToMessageType,
          replyToSenderId: replyToSenderId,
          replyToMediaUrl: replyToMediaUrl,
          replyToStoryId: replyToStoryId,
          replyToStoryAuthorId: replyToStoryAuthorId,
          replyToStoryType: replyToStoryType,
          replyToStoryMediaUrl: replyToStoryMediaUrl,
          replyToStoryText: replyToStoryText,
          replyToStoryBgColor: replyToStoryBgColor,
          replyToStoryDurationSeconds: replyToStoryDurationSeconds,
          forwardedFromUserId: forwardedFromUserId,
          forwardedFromUserName: forwardedFromUserName,
          forwardedFromUserAvatar: forwardedFromUserAvatar,
        ),
      );
    }

    return (id: newMessageId, createdAt: serverCreatedAt);
  }

  Future<void> editMessage({
    required String messageId,
    required String newText,
    required bool isCaptionEdit,
  }) async {
    await _supabase
        .from('messages')
        .update({
          if (isCaptionEdit) 'caption': newText else 'text': newText,
          'is_edited': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);
  }

  Future<void> deleteMessage({required String messageId}) async {
    await MediaCleanupService.instance.deleteWithMedia(
      table: SupabaseConstants.messages,
      id: messageId,
    );
  }

  Future<void> deleteMessageForMe({
    required String messageId,
    required String currentUserId,
  }) async {
    final row =
        await _supabase
            .from(SupabaseConstants.messages)
            .select(MessagesColumns.deletedFor)
            .eq(MessagesColumns.id, messageId)
            .maybeSingle();

    final current =
        (row?[MessagesColumns.deletedFor] as List?)?.cast<String>() ?? [];
    final updated = {...current, currentUserId}.toList();

    await _supabase
        .from(SupabaseConstants.messages)
        .update({MessagesColumns.deletedFor: updated})
        .eq(MessagesColumns.id, messageId);
  }

  Future<void> deleteMessagesForMe({
    required List<MessageModel> messages,
    required String currentUserId,
  }) async {
    for (final m in messages) {
      final updated = {...m.deletedFor, currentUserId}.toList();
      await _supabase
          .from(SupabaseConstants.messages)
          .update({MessagesColumns.deletedFor: updated})
          .eq(MessagesColumns.id, m.id);
    }
  }

  Future<void> deleteMessagesForEveryone(List<String> messageIds) async {
    for (final id in messageIds) {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.messages,
        id: id,
      );
    }
  }

  Future<void> markMessagesAsRead({
    required String senderId,
    required String currentUserId,
  }) async {
    await _supabase
        .from(SupabaseConstants.messages)
        .update({MessagesColumns.isRead: true})
        .eq(MessagesColumns.senderId, senderId)
        .eq(MessagesColumns.receiverId, currentUserId)
        .eq(MessagesColumns.isRead, false);
  }

  Future<Map<String, String?>> getCurrentUserInfo(String userId) async {
    try {
      final data =
          await _supabase
              .from(SupabaseConstants.users)
              .select('${UserColumns.name}, ${UserColumns.imageUrl}')
              .eq(UserColumns.id, userId)
              .single();
      return {
        'name': data[UserColumns.name] as String?,
        'imageUrl': data[UserColumns.imageUrl] as String?,
      };
    } catch (e) {
      debugPrint('Error fetching user info: $e');
      return {'name': null, 'imageUrl': null};
    }
  }

  Future<void> upsertCallMessage({
    required String callId,
    required String senderId,
    required String receiverId,
    required String status,
    required String callType,
    String duration = '',
  }) async {
    final callInfoJson = jsonEncode({
      'call_id': callId,
      'status': status,
      'call_type': callType,
      'duration': duration,
    });

    final existing =
        await _supabase
            .from(SupabaseConstants.messages)
            .select(MessagesColumns.id)
            .eq(MessagesColumns.messageType, 'call')
            .ilike(MessagesColumns.messageText, '%$callId%')
            .maybeSingle();

    if (existing != null) {
      await _supabase
          .from(SupabaseConstants.messages)
          .update({MessagesColumns.messageText: callInfoJson})
          .eq(MessagesColumns.id, existing[MessagesColumns.id] as String);
      return;
    }

    await sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: callInfoJson,
      clientMessageId: const Uuid().v4(),
      messageType: 'call',
    );
  }
}
