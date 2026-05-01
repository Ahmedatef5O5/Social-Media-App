enum NotificationType {
  chat,
  call,
  groupMessage,
  like,
  comment,
  follow,
  general,
}

class AppNotification {
  final String id;
  final NotificationType type;
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
    required this.title,
    required this.body,
    this.senderImageUrl,
    this.senderId,
    this.referenceId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: _typeFromString(map['type'] as String? ?? 'general'),
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
      'type': _typeToString(type),
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
        return NotificationType.chat;
      case 'call':
        return NotificationType.call;
      case 'group_message':
        return NotificationType.groupMessage;
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
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
      case NotificationType.general:
        return 'general';
    }
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      senderImageUrl: senderImageUrl,
      senderId: senderId,
      referenceId: referenceId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
