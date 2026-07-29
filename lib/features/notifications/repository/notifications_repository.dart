import '../../../core/supabase/supabase_provider.dart';
import '../models/app_notification_model.dart';

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
    required String messageType,
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
    required String callType,
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

  Future<void> notifyShare({
    required String receiverId,
    required String sharerId,
    required String sharerName,
    required String sharerImageUrl,
    required String postId,
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': sharerId,
      'type': 'share',
      'title': sharerName,
      'body': '🔁 shared your post',
      'sender_image_url': sharerImageUrl,
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
    await _removeNotification(
      receiverId: receiverId,
      senderId: followerId,
      type: 'follow',
    );
    await _insert({
      'receiver_id': receiverId,
      'sender_id': followerId,
      'type': 'follow',
      'title': followerName,
      'body': '👥 started following you',
      'sender_image_url': followerImageUrl,
      'reference_id': followerId,
      'is_read': false,
    });
  }

  Future<void> removeFollowNotification({
    required String receiverId,
    required String senderId,
  }) => _removeNotification(
    receiverId: receiverId,
    senderId: senderId,
    type: 'follow',
  );

  Future<void> notifyFriendRequest({
    required String receiverId,
    required String requesterId,
    required String requesterName,
    required String requesterImageUrl,
    required String friendshipId,
  }) async {
    await _removeNotification(
      receiverId: receiverId,
      senderId: requesterId,
      type: 'friend_request',
    );

    await _insert({
      'receiver_id': receiverId,
      'sender_id': requesterId,
      'type': 'friend_request',
      'title': requesterName,
      'body': '👤 sent you a friend request',
      'sender_image_url': requesterImageUrl,
      'reference_id': friendshipId,
      'is_read': false,
    });
  }

  Future<void> removeFriendRequestNotification({
    required String receiverId,
    required String senderId,
  }) => _removeNotification(
    receiverId: receiverId,
    senderId: senderId,
    type: 'friend_request',
  );

  Future<void> notifyFriendAccept({
    required String receiverId,
    required String accepterId,
    required String accepterName,
    required String accepterImageUrl,
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': accepterId,
      'type': 'friend_accept',
      'title': accepterName,
      'body': '🤝 accepted your friend request',
      'sender_image_url': accepterImageUrl,
      'reference_id': accepterId,
      'is_read': false,
    });
  }

  Future<void> _removeNotification({
    required String receiverId,
    required String senderId,
    required String type,
  }) async {
    try {
      await _db
          .from('notifications')
          .delete()
          .eq('receiver_id', receiverId)
          .eq('sender_id', senderId)
          .eq('type', type);
    } catch (_) {
      /// Silent - never crash the caller
    }
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

  Future<List<AppNotification>> fetchNotifications({int limit = 60}) async {
    final userId = SupabaseProvider.id;
    final data = await _db
        .from('notifications')
        .select()
        .eq('receiver_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromMap)
        .toList();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _db.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _db.from('notifications').delete().eq('id', id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final userId = SupabaseProvider.id;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }
}
