import '../../../core/utilities/supabase_constants.dart';

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;
  final String messageType; // text | image | video | voice | call
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final String? caption;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final String? replyToSenderName;
  final String? replyToMessageType;

  final Map<String, String> reactions;

  final Set<String> readBy;

  const GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.createdAt,
    this.messageType = 'text',
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.caption,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToMessageType,
    this.reactions = const {},
    this.readBy = const {},
  });

  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? text,
    DateTime? createdAt,
    String? messageType,
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    String? caption,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToMessageType,
    Map<String, String>? reactions,
    Set<String>? readBy,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      caption: caption ?? this.caption,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToMessageType: replyToMessageType ?? this.replyToMessageType,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
    );
  }

  factory GroupMessageModel.fromMap(
    Map<String, dynamic> map, {
    List<Map<String, dynamic>> reactionsList = const [],
  }) {
    final Map<String, String> reactionsMap = {};
    for (final r in reactionsList) {
      final userId = r[GroupMemberColumns.userId] as String?;
      final emoji = r['reaction'] as String?;
      if (userId != null && emoji != null) {
        reactionsMap[userId] = emoji;
      }
    }

    final readByRaw = map['read_by'];
    Set<String> readBySet = {};
    if (readByRaw is List) {
      readBySet = readByRaw.map((e) => e.toString()).toSet();
    }

    return GroupMessageModel(
      id: map['id'] as String,
      groupId: map[GroupMemberColumns.groupId] as String,
      senderId: map['sender_id'] as String,
      senderName: (map['sender_name'] ?? 'Unknown') as String,
      senderAvatar: map['sender_avatar'] as String?,
      text: (map['message_text'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      messageType: (map['message_type'] ?? 'text') as String,
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      voiceUrl: map['voice_url'] as String?,
      caption: map['caption'] as String?,
      replyToMessageId: map['reply_to_message_id'] as String?,
      replyToText: map['reply_to_text'] as String?,
      replyToSenderId: map['reply_to_sender_id'] as String?,
      replyToSenderName: map['reply_to_sender_name'] as String?,
      replyToMessageType: map['reply_to_message_type'] as String?,
      reactions: reactionsMap,
      readBy: readBySet,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      GroupMemberColumns.groupId: groupId,
      'sender_id': senderId,
      'message_text': text,
      'message_type': messageType,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (voiceUrl != null) 'voice_url': voiceUrl,
      if (caption != null) 'caption': caption,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (replyToText != null) 'reply_to_text': replyToText,
      if (replyToSenderId != null) 'reply_to_sender_id': replyToSenderId,
      if (replyToSenderName != null) 'reply_to_sender_name': replyToSenderName,
      if (replyToMessageType != null)
        'reply_to_message_type': replyToMessageType,
    };
  }

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    final reactionsRaw = json['reactions'];
    final Map<String, String> reactionsMap =
        reactionsRaw is Map
            ? reactionsRaw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
            : {};

    final readByRaw = json['read_by'];
    final Set<String> readBySet =
        readByRaw is List ? readByRaw.map((e) => e.toString()).toSet() : {};
    return GroupMessageModel(
      id: json['id'] as String,
      groupId: json[GroupMemberColumns.groupId] as String,
      senderId: json['sender_id'] as String,
      senderName: (json['sender_name'] ?? 'Unknown') as String,
      senderAvatar: json['sender_avatar'] as String?,
      text: (json['message_text'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      messageType: (json['message_type'] ?? 'text') as String,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      voiceUrl: json['voice_url'] as String?,
      caption: json['caption'] as String?,
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyToText: json['reply_to_text'] as String?,
      replyToSenderId: json['reply_to_sender_id'] as String?,
      replyToSenderName: json['reply_to_sender_name'] as String?,
      replyToMessageType: json['reply_to_message_type'] as String?,
      reactions: reactionsMap,
      readBy: readBySet,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      GroupMemberColumns.groupId: groupId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'message_text': text,
      'created_at': createdAt.toIso8601String(),
      'message_type': messageType,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'voice_url': voiceUrl,
      'caption': caption,
      'reply_to_message_id': replyToMessageId,
      'reply_to_text': replyToText,
      'reply_to_sender_id': replyToSenderId,
      'reply_to_sender_name': replyToSenderName,
      'reply_to_message_type': replyToMessageType,
      'reactions': reactions,
      'read_by': readBy.toList(),
    };
  }
}
