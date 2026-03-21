import 'package:social_media_app/core/utilities/supabase_constants.dart';

class ChatUserModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  const ChatUserModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatUserModel.fromUserData(Map<String, dynamic> map) {
    return ChatUserModel(
      id: (map[MessagesColumns.id] ?? '').toString(),
      name: (map[UserColumns.name] ?? 'Unknown').toString(),
      imageUrl: map[UserColumns.imageUrl] as String?,
      lastMessage: map['last_message'] as String?, // from SQL
      lastMessageTime:
          map['last_message_time'] != null
              ? DateTime.parse(map['last_message_time'].toString()) // from SQL
              : null,
    );
  }

  ChatUserModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return ChatUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
