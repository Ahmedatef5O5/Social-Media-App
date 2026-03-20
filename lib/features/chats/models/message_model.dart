import 'package:social_media_app/core/utilities/app_tables_names.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json[MessagesColumns.id],
      senderId: json[MessagesColumns.senderId],
      receiverId: json[MessagesColumns.receiverId],
      text: json[MessagesColumns.messageText],
      createdAt: DateTime.parse(json[MessagesColumns.createdAt]),
    );
  }
}
