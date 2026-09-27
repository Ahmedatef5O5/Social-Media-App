enum NotificationType {
  chat,
  call,
  groupMessage,
  like,
  comment,
  follow,
  friendRequest,
  friendAccept,
  general,
}

extension AppNotificationDisplayX on AppNotification {
  String get displaySubtitle {
    final trimmed = body.trim();
    if (trimmed.isNotEmpty) return trimmed;

    switch (type) {
      case NotificationType.chat:
        return '📄 Sent an attachment';
      case NotificationType.groupMessage:
        return '👥 Sent a new message';
      case NotificationType.call:
        return '📞 Missed call';
      case NotificationType.like:
        return '❤️ Liked your post';
      case NotificationType.comment:
        return '💬 Commented on your post';
      case NotificationType.follow:
        return '👤 Started following you';
      case NotificationType.friendRequest:
        return '👤 Sent you a friend request';
      case NotificationType.friendAccept:
        return '🤝 Accepted your friend request';
      case NotificationType.general:
        return '🔔 New notification';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String rawType;
  final String title;
  final String body;
  final String? senderImageUrl;
  final String? senderId;
  final String? referenceId;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    this.rawType = 'general',
    required this.title,
    required this.body,
    this.senderImageUrl,
    this.senderId,
    this.referenceId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final raw = map['type'] as String? ?? 'general';
    return AppNotification(
      id: map['id'] as String,
      type: _typeFromString(raw),
      rawType: raw,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      senderImageUrl: map['sender_image_url'] as String?,
      senderId: map['sender_id'] as String?,
      referenceId: map['reference_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': rawType.isNotEmpty ? rawType : _typeToString(type),
      'title': title,
      'body': body,
      'sender_image_url': senderImageUrl,
      'sender_id': senderId,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'chat':
      case 'story_reply':
        return NotificationType.chat;
      case 'call':
      case 'group_call':
        return NotificationType.call;
      case 'group_message':
      case 'group':
        return NotificationType.groupMessage;
      case 'like':
      case 'post_react':
        return NotificationType.like;
      case 'comment':
      case 'post_comment':
      case 'comment_reply':
      case 'comment_react':
      case 'share':
      case 'post_reshare':
      case 'mention':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'friend_request':
        return NotificationType.friendRequest;
      case 'friend_accept':
        return NotificationType.friendAccept;
      default:
        return NotificationType.general;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return 'chat';
      case NotificationType.call:
        return 'call';
      case NotificationType.groupMessage:
        return 'group_message';
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.friendRequest:
        return 'friend_request';
      case NotificationType.friendAccept:
        return 'friend_accept';
      case NotificationType.general:
        return 'general';
    }
  }

  AppNotification copyWith({
    bool? isRead,
    String? title,
    String? body,
    String? senderImageUrl,
  }) {
    return AppNotification(
      id: id,
      type: type,
      rawType: rawType,
      title: title ?? this.title,
      body: body ?? this.body,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      senderId: senderId,
      referenceId: referenceId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
