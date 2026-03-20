import 'package:social_media_app/core/utilities/app_tables_names.dart';

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
      name: (map[UserColumns.name] ?? 'Unknown User').toString(),
      imageUrl: map[UserColumns.imageUrl] as String?,
      lastMessage: map[MessagesColumns.messageText] as String?,
      lastMessageTime:
          map[MessagesColumns.createdAt] != null
              ? DateTime.parse(map[MessagesColumns.createdAt].toString())
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
