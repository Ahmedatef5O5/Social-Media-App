import 'package:social_media_app/core/utilities/supabase_constants.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool isRead;
  final String messageType;
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final String? caption;
  final String? reaction;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToMessageType;
  final String? replyToSenderId;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
    this.messageType = 'text',
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.caption,
    this.reaction,
    this.replyToMessageId,
    this.replyToText,
    this.replyToMessageType,
    this.replyToSenderId,
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? createdAt,
    bool? isRead,
    String? messageType,
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    String? caption,
    String? reaction,
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      caption: caption ?? this.caption,
      reaction: reaction ?? this.reaction,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToMessageType: replyToMessageType ?? this.replyToMessageType,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json[MessagesColumns.id],
      senderId: json[MessagesColumns.senderId],
      receiverId: json[MessagesColumns.receiverId],
      text: json[MessagesColumns.messageText],
      createdAt: DateTime.parse(json[MessagesColumns.createdAt]),
      isRead: json[MessagesColumns.isRead] ?? false,
      messageType: json[MessagesColumns.messageType] ?? 'text',
      imageUrl: json[MessagesColumns.imageUrl],
      videoUrl: json[MessagesColumns.videoUrl],
      voiceUrl: json[MessagesColumns.voiceUrl],
      caption: json[MessagesColumns.caption],
      reaction: json[MessagesColumns.reaction],
      replyToMessageId: json[MessagesColumns.replyToMessageId],
      replyToText: json[MessagesColumns.replyToText],
      replyToMessageType: json[MessagesColumns.replyToMessageType],
      replyToSenderId: json[MessagesColumns.replyToSenderId],
    );
  }
}
