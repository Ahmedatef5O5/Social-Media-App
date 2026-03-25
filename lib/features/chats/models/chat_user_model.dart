class ChatUserModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime? lastSeen;

  const ChatUserModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.lastSeen,
  });

  factory ChatUserModel.fromUserData(Map<String, dynamic> map) {
    return ChatUserModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Unknown').toString(),
      imageUrl: map['image_url'] as String?,
      lastMessage: map['last_message'] as String?, // from SQL
      lastMessageType: map['last_message_type'] ?? 'text',
      lastMessageTime:
          map['last_message_time'] != null
              ? DateTime.parse(map['last_message_time'].toString()) // from SQL
              : null,
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      lastSeen:
          map['last_seen'] != null
              ? DateTime.parse(map['last_seen'].toString())
              : null,
    );
  }

  ChatUserModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? lastSeen,
  }) {
    return ChatUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
