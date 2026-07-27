import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_provider.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  Future<void> sendChatNotification({
    required String receiverFcmToken,
    required String senderId,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
    String? attachmentUrl,
  }) async {
    await _sendToEdgeFunction({
      'type': 'chat',
      'receiverFcmToken': receiverFcmToken,
      'senderId': senderId,
      'senderName': senderName,
      'messageBody': messageBody,
      'messageType': messageType,
      'senderImageUrl': senderImageUrl,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    });
  }

  Future<void> sendStoryReplyNotification({
    required String receiverFcmToken,
    required String senderId,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
    String? attachmentUrl,
    required String replyToStoryId,
    String? replyToStoryType,
    String? replyToStoryMediaUrl,
    String? replyToStoryText,
    String? replyToStoryBgColor,
  }) async {
    await _sendToEdgeFunction({
      'type': 'story_reply',
      'receiverFcmToken': receiverFcmToken,
      'senderId': senderId,
      'senderName': senderName,
      'messageBody': messageBody,
      'messageType': messageType,
      'senderImageUrl': senderImageUrl,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      'replyToStoryId': replyToStoryId,
      if (replyToStoryType != null) 'replyToStoryType': replyToStoryType,
      if (replyToStoryMediaUrl != null)
        'replyToStoryMediaUrl': replyToStoryMediaUrl,
      if (replyToStoryText != null) 'replyToStoryText': replyToStoryText,
      if (replyToStoryBgColor != null)
        'replyToStoryBgColor': replyToStoryBgColor,
    });
  }

  Future<void> sendCallNotification({
    required String receiverFcmToken,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callId,
    required String callType,
  }) async {
    await _sendToEdgeFunction({
      'type': 'call',
      'receiverFcmToken': receiverFcmToken,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'callId': callId,
      'callType': callType,
    });
  }

  Future<void> sendGroupNotification({
    required String receiverFcmToken,
    required String groupId,
    required String groupName,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
    String groupImageUrl = '',
    bool isMention = false,
  }) async {
    await _sendToEdgeFunction({
      'type': 'group',
      'receiverFcmToken': receiverFcmToken,
      'groupId': groupId,
      'groupName': groupName,
      'senderName': senderName,
      'messageBody': messageBody,
      'messageType': messageType,
      'senderImageUrl': senderImageUrl,
      'groupImageUrl': groupImageUrl,
      if (isMention) 'isMention': 'true',
    });
  }

  Future<void> sendGroupCallNotification({
    required String receiverFcmToken,
    required String callId,
    required String groupId,
    required String groupName,
    required String groupAvatarUrl,
    required String callerId,
    required String callerName,
    required String callType,
    required String startedAt,
  }) async {
    await _sendToEdgeFunction({
      'type': 'group_call',
      'receiverFcmToken': receiverFcmToken,
      'callId': callId,
      'groupId': groupId,
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
      'callerId': callerId,
      'callerName': callerName,
      'callType': callType,
      'startedAt': startedAt,
    });
  }

  Future<void> notifyPostReact({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String postId,
    String? reactionType,
    String? postThumbnailUrl,
  }) async {
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'post_react',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'postId': postId,
      if (reactionType != null) 'reactionType': reactionType,
      if (postThumbnailUrl != null) 'postThumbnailUrl': postThumbnailUrl,
    });
  }

  Future<void> notifyPostComment({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String postId,
    required String commentText,
    String? postThumbnailUrl,
  }) async {
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'post_comment',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'postId': postId,
      'commentText': commentText,
      if (postThumbnailUrl != null) 'postThumbnailUrl': postThumbnailUrl,
    });
  }

  Future<void> notifyPostReshare({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String postId,
    String? postThumbnailUrl,
  }) async {
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'post_reshare',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'postId': postId,
      if (postThumbnailUrl != null) 'postThumbnailUrl': postThumbnailUrl,
    });
  }

  Future<void> notifyPostSave({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String postId,
    String? postThumbnailUrl,
  }) async {
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'post_save',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'postId': postId,
      if (postThumbnailUrl != null) 'postThumbnailUrl': postThumbnailUrl,
    });
  }

  Future<void> notifyMention({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String context,
    String? postId,
    String? storyId,
  }) async {
    assert(context == 'post' || context == 'story');
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'mention',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'context': context,
      if (postId != null) 'postId': postId,
      if (storyId != null) 'storyId': storyId,
    });
  }

  Future<void> notifyCommentReply({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String postId,
    required String commentId,
    required String commentText,
  }) async {
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'comment_reply',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'postId': postId,
      'commentId': commentId,
      'commentText': commentText,
    });
  }

  Future<void> notifyCommentReact({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String postId,
    required String commentId,
    String? reactionType,
  }) async {
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'comment_react',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'postId': postId,
      'commentId': commentId,
      if (reactionType != null) 'reactionType': reactionType,
    });
  }

  Future<void> notifyStoryReact({
    required String receiverId,
    required String actorId,
    required String actorName,
    String actorImageUrl = '',
    required String storyId,
    String? reactionType,
    int? reactorCount,
  }) async {
    if (receiverId.isEmpty || receiverId == actorId) return;
    final token = await _fetchFcmToken(receiverId);
    if (token == null) return;
    await _sendToEdgeFunction({
      'type': 'story_react',
      'receiverFcmToken': token,
      'actorId': actorId,
      'actorName': actorName,
      'actorImageUrl': actorImageUrl,
      'storyId': storyId,
      if (reactionType != null) 'reactionType': reactionType,
      if (reactorCount != null) 'reactorCount': reactorCount.toString(),
    });
  }

  Future<void> notifyMessageReact({
    required String messageId,
    required bool isGroup,
    required String reactionType,
  }) async {
    await _sendToEdgeFunction({
      'type': 'message_react',
      'messageId': messageId,
      'isGroup': isGroup ? 'true' : 'false',
      'reactionType': reactionType,
    });
  }

  Future<String?> _fetchFcmToken(String userId) async {
    try {
      final data =
          await SupabaseProvider.client
              .from('users')
              .select('fcm_token')
              .eq('id', userId)
              .maybeSingle();
      final token = data?['fcm_token'] as String?;
      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      debugPrint('⚠️ FcmService._fetchFcmToken failed: $e');
      return null;
    }
  }

  Future<void> _sendToEdgeFunction(Map<String, dynamic> payload) async {
    try {
      final response = await SupabaseProvider.client.functions.invoke(
        'send-notification',
        body: payload,
      );

      debugPrint('✅ Notification sent via Edge Function: ${response.status}');
    } on FunctionException catch (e) {
      debugPrint('❌ Edge Function Error: ${e.reasonPhrase} - ${e.details}');
    } catch (e) {
      debugPrint('❌ General FCM Error: $e');
    }
  }
}
