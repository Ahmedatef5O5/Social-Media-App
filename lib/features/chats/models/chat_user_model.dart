import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../../auth/data/models/user_data.dart';

class ChatUserModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final bool lastMessageIsMe;
  final bool lastMessageIsRead;
  final bool? isTyping;
  final int unreadCount;
  final DateTime? lastSeen;
  final bool isOnline;

  const ChatUserModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.lastMessageIsMe = false,
    this.lastMessageIsRead = false,
    this.isTyping,
    this.unreadCount = 0,
    this.lastSeen,
    this.isOnline = false,
  });

  factory ChatUserModel.fromUserData(
    Map<String, dynamic> map,
    String currentUserId,
  ) {
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
      lastMessageIsMe: map['last_message_sender_id'] == currentUserId,
      lastMessageIsRead: map['last_message_is_read'] ?? false,
      isTyping: map[UserColumns.isTypingTo] == currentUserId,
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      lastSeen:
          map['last_seen'] != null
              ? DateTime.parse(map['last_seen'].toString())
              : null,
      isOnline: false,
    );
  }

  ChatUserModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? lastMessage,
    String? lastMessageType,
    bool? lastMessageIsMe,
    bool? lastMessageIsRead,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? lastSeen,
    bool? isTyping,
    bool? isOnline,
  }) {
    return ChatUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageIsMe: lastMessageIsMe ?? this.lastMessageIsMe,
      lastMessageIsRead: lastMessageIsRead ?? this.lastMessageIsRead,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory ChatUserModel.fromEntity(UserData userData) {
    return ChatUserModel(
      id: userData.id,
      name: userData.name,
      imageUrl: userData.imageUrl,
      unreadCount: 0,
      lastSeen: userData.lastSeen,
      lastMessageIsMe: false,
      lastMessageIsRead: false,
      isOnline: false,
    );
  }
}
