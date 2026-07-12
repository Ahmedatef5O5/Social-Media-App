import '../../../core/supabase/supabase_provider.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final _db = SupabaseProvider.client;

  Future<void> _insert(Map<String, dynamic> row) async {
    try {
      await _db.from('notifications').insert(row);
    } catch (e) {
      // Silent – never crash the caller
    }
  }

  Future<void> notifyChatMessage({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String senderImageUrl,
    required String messageBody,
    required String messageType, // text | image | video | voice | call
    required String chatReferenceId,
  }) async {
    final String body = _chatBody(messageBody, messageType);
    await _insert({
      'receiver_id': receiverId,
      'sender_id': senderId,
      'type': 'chat',
      'title': senderName,
      'body': body,
      'sender_image_url': senderImageUrl,
      'reference_id': chatReferenceId,
      'is_read': false,
    });
  }

  Future<void> notifyGroupMessage({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String senderImageUrl,
    required String groupId,
    required String groupName,
    required String messageBody,
    required String messageType,
  }) async {
    final String body = _chatBody(messageBody, messageType);
    await _insert({
      'receiver_id': receiverId,
      'sender_id': senderId,
      'type': 'group_message',
      'title': groupName,
      'body': '$senderName: $body',
      'sender_image_url': senderImageUrl,
      'reference_id': groupId,
      'is_read': false,
    });
  }

  Future<void> notifyMissedCall({
    required String receiverId,
    required String callerId,
    required String callerName,
    required String callerImageUrl,
    required String callType, // 'audio' | 'video'
    required String callId,
  }) async {
    final icon = callType == 'video' ? '🎥' : '📞';
    await _insert({
      'receiver_id': receiverId,
      'sender_id': callerId,
      'type': 'call',
      'title': callerName,
      'body': '$icon Missed ${callType == 'video' ? 'video' : 'voice'} call',
      'sender_image_url': callerImageUrl,
      'reference_id': callId,
      'is_read': false,
    });
  }

  Future<void> notifyLike({
    required String receiverId,
    required String likerId,
    required String likerName,
    required String likerImageUrl,
    required String postId,
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': likerId,
      'type': 'like',
      'title': likerName,
      'body': '❤️ liked your post',
      'sender_image_url': likerImageUrl,
      'reference_id': postId,
      'is_read': false,
    });
  }

  Future<void> notifyComment({
    required String receiverId,
    required String commenterId,
    required String commenterName,
    required String commenterImageUrl,
    required String postId,
    required String commentPreview,
  }) async {
    final preview =
        commentPreview.length > 50
            ? '${commentPreview.substring(0, 50)}…'
            : commentPreview;
    await _insert({
      'receiver_id': receiverId,
      'sender_id': commenterId,
      'type': 'comment',
      'title': commenterName,
      'body': '💬 commented: $preview',
      'sender_image_url': commenterImageUrl,
      'reference_id': postId,
      'is_read': false,
    });
  }

  Future<void> notifyFollow({
    required String receiverId,
    required String followerId,
    required String followerName,
    required String followerImageUrl,
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': followerId,
      'type': 'follow',
      'title': followerName,
      'body': '👤 started following you',
      'sender_image_url': followerImageUrl,
      'reference_id': followerId,
      'is_read': false,
    });
  }

  String _chatBody(String text, String type) {
    switch (type) {
      case 'image':
        return text.isNotEmpty ? '📷 $text' : '📷 Photo';
      case 'video':
        return text.isNotEmpty ? '🎥 $text' : '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'call':
        return '📞 Missed call';
      default:
        return text;
    }
  }
}
