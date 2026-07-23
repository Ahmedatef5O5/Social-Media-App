import 'package:social_media_app/core/utilities/supabase_constants.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool isRead;
  final bool isEdited;
  final String messageType;
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final String? caption;
  final Map<String, String> reactions;
  final Map<String, String>? reactionsCreatedAt;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToMessageType;
  final String? replyToSenderId;
  final List<String> deletedFor;
  final String? replyToStoryId;
  final String? replyToStoryAuthorId;
  final String? replyToStoryType;
  final String? replyToStoryMediaUrl;
  final String? replyToStoryText;
  final String? replyToStoryBgColor;
  final int? replyToStoryDurationSeconds;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
    this.isEdited = false,
    this.messageType = 'text',
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.caption,
    this.reactions = const {},
    this.reactionsCreatedAt,
    this.replyToMessageId,
    this.replyToText,
    this.replyToMessageType,
    this.replyToSenderId,
    this.deletedFor = const [],
    this.replyToStoryId,
    this.replyToStoryAuthorId,
    this.replyToStoryType,
    this.replyToStoryMediaUrl,
    this.replyToStoryText,
    this.replyToStoryBgColor,
    this.replyToStoryDurationSeconds,
  });

  bool get isStoryReply => replyToStoryType != null;

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? createdAt,
    bool? isRead,
    bool? isEdited,
    String? messageType,
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    String? caption,
    Map<String, String>? reactions,
    Map<String, String>? reactionsCreatedAt,
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
    List<String>? deletedFor,
    String? replyToStoryId,
    String? replyToStoryAuthorId,
    String? replyToStoryType,
    String? replyToStoryMediaUrl,
    String? replyToStoryText,
    String? replyToStoryBgColor,
    int? replyToStoryDurationSeconds,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      caption: caption ?? this.caption,
      reactions: reactions ?? this.reactions,
      reactionsCreatedAt: reactionsCreatedAt ?? this.reactionsCreatedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToMessageType: replyToMessageType ?? this.replyToMessageType,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      deletedFor: deletedFor ?? this.deletedFor,
      replyToStoryId: replyToStoryId ?? this.replyToStoryId,
      replyToStoryAuthorId: replyToStoryAuthorId ?? this.replyToStoryAuthorId,
      replyToStoryType: replyToStoryType ?? this.replyToStoryType,
      replyToStoryMediaUrl: replyToStoryMediaUrl ?? this.replyToStoryMediaUrl,
      replyToStoryText: replyToStoryText ?? this.replyToStoryText,
      replyToStoryBgColor: replyToStoryBgColor ?? this.replyToStoryBgColor,
      replyToStoryDurationSeconds:
          replyToStoryDurationSeconds ?? this.replyToStoryDurationSeconds,
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
      isEdited: json[MessagesColumns.isEdited] ?? false,
      messageType: json[MessagesColumns.messageType] ?? 'text',
      imageUrl: json[MessagesColumns.imageUrl],
      videoUrl: json[MessagesColumns.videoUrl],
      voiceUrl: json[MessagesColumns.voiceUrl],
      caption: json[MessagesColumns.caption],
      replyToMessageId: json[MessagesColumns.replyToMessageId],
      replyToText: json[MessagesColumns.replyToText],
      replyToMessageType: json[MessagesColumns.replyToMessageType],
      replyToSenderId: json[MessagesColumns.replyToSenderId],
      deletedFor:
          (json[MessagesColumns.deletedFor] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      replyToStoryId: json[MessagesColumns.replyToStoryId],
      replyToStoryAuthorId: json[MessagesColumns.replyToStoryAuthorId],
      replyToStoryType: json[MessagesColumns.replyToStoryType],
      replyToStoryMediaUrl: json[MessagesColumns.replyToStoryMediaUrl],
      replyToStoryText: json[MessagesColumns.replyToStoryText],
      replyToStoryBgColor: json[MessagesColumns.replyToStoryBgColor],
      replyToStoryDurationSeconds:
          (json[MessagesColumns.replyToStoryDurationSeconds] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      MessagesColumns.id: id,
      MessagesColumns.senderId: senderId,
      MessagesColumns.receiverId: receiverId,
      MessagesColumns.messageText: text,
      MessagesColumns.createdAt: createdAt.toIso8601String(),
      MessagesColumns.isRead: isRead,
      MessagesColumns.isEdited: isEdited,
      MessagesColumns.messageType: messageType,
      MessagesColumns.imageUrl: imageUrl,
      MessagesColumns.videoUrl: videoUrl,
      MessagesColumns.voiceUrl: voiceUrl,
      MessagesColumns.caption: caption,
      MessagesColumns.replyToMessageId: replyToMessageId,
      MessagesColumns.replyToText: replyToText,
      MessagesColumns.replyToMessageType: replyToMessageType,
      MessagesColumns.replyToSenderId: replyToSenderId,
      MessagesColumns.deletedFor: deletedFor,
      MessagesColumns.replyToStoryId: replyToStoryId,
      MessagesColumns.replyToStoryAuthorId: replyToStoryAuthorId,
      MessagesColumns.replyToStoryType: replyToStoryType,
      MessagesColumns.replyToStoryMediaUrl: replyToStoryMediaUrl,
      MessagesColumns.replyToStoryText: replyToStoryText,
      MessagesColumns.replyToStoryBgColor: replyToStoryBgColor,
      MessagesColumns.replyToStoryDurationSeconds: replyToStoryDurationSeconds,
    };
  }
}
