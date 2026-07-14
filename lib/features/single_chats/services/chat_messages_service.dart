import 'package:flutter/material.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/message_model.dart';

/// Per-conversation message concerns: the messages stream, media gallery,
/// sending/deleting messages, marking read, and looking up a user's
/// name/avatar for a message's sender snapshot.
///
/// Extracted from the monolithic `ChatServices`. Logic is unchanged — this
/// is a pure structural extraction.
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

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String messageType = 'text',
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    String? caption,
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? replyToStoryId,
    String? replyToStoryAuthorId,
    String? replyToStoryType,
    String? replyToStoryMediaUrl,
    String? replyToStoryText,
    String? replyToStoryBgColor,
    int? replyToStoryDurationSeconds,
  }) async {
    await _supabase.from(SupabaseConstants.messages).insert({
      MessagesColumns.senderId: senderId,
      MessagesColumns.receiverId: receiverId,
      MessagesColumns.messageText: text,
      MessagesColumns.messageType: messageType,
      if (imageUrl != null) MessagesColumns.imageUrl: imageUrl,
      if (videoUrl != null) MessagesColumns.videoUrl: videoUrl,
      if (voiceUrl != null) MessagesColumns.voiceUrl: voiceUrl,
      if (caption != null) MessagesColumns.caption: caption,
      if (replyToMessageId != null)
        MessagesColumns.replyToMessageId: replyToMessageId,
      if (replyToText != null) MessagesColumns.replyToText: replyToText,
      if (replyToMessageType != null)
        MessagesColumns.replyToMessageType: replyToMessageType,
      if (replyToSenderId != null)
        MessagesColumns.replyToSenderId: replyToSenderId,
      if (imagePublicId != null) MessagesColumns.imagePublicId: imagePublicId,
      if (videoPublicId != null) MessagesColumns.videoPublicId: videoPublicId,
      if (voicePublicId != null) MessagesColumns.voicePublicId: voicePublicId,
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
    });
  }

  Future<void> deleteMessage({required String messageId}) async {
    await MediaCleanupService.instance.deleteWithMedia(
      table: SupabaseConstants.messages,
      id: messageId,
    );
  }

  Future<void> deleteMessagesForEveryone(List<String> messageIds) async {
    for (final id in messageIds) {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.messages,
        id: id,
      );
    }
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
}
