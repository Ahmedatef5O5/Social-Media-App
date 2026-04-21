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

  // Multiple reactions: { userId: emoji }
  final Map<String, String> reactions;

  // Set of userIds who read this message
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
    // Build reactions map from joined data
    final Map<String, String> reactionsMap = {};
    for (final r in reactionsList) {
      final userId = r['user_id'] as String?;
      final emoji = r['reaction'] as String?;
      if (userId != null && emoji != null) {
        reactionsMap[userId] = emoji;
      }
    }

    // read_by may come as a JSON array of user IDs
    final readByRaw = map['read_by'];
    Set<String> readBySet = {};
    if (readByRaw is List) {
      readBySet = readByRaw.map((e) => e.toString()).toSet();
    }

    return GroupMessageModel(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
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
      'group_id': groupId,
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
}
