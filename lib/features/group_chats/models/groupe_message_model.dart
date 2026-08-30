import '../../../core/mentions/models/mention_ref.dart';
import '../../../core/utilities/supabase_constants.dart';

class GroupMessageModel {
  final String id;

  /// Client-generated correlation id (UUID v4), set once when the message
  /// is first created on this device and never regenerated afterwards —
  /// including on retry. Used by [MessageReconciler] to correlate the
  /// optimistic (temp) representation of a message with its
  /// server-confirmed representation regardless of which arrives first
  /// (API response vs Realtime), and as the DB idempotency key so a retry
  /// can never create a second row for the same logical message.
  ///
  /// `null` for legacy rows written before this field existed; those are
  /// correlated by [id] (server id) only — see `correlationKeyFor` in
  /// `message_reconciler.dart`.
  final String? clientMessageId;

  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;
  final String messageType;
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final int? durationSeconds;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? caption;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final String? replyToSenderName;
  final String? replyToMessageType;
  final String? replyToMediaUrl;
  final List<MentionRef> mentions;
  final Map<String, String> reactions;
  final Map<String, String>? reactionsCreatedAt;
  final Set<String> readBy;
  final bool isEdited;
  final List<String> deletedFor;
  final String? forwardedFromUserId;
  final String? forwardedFromUserName;
  final String? forwardedFromUserAvatar;
  final Map<String, dynamic>? systemEventData;
  final String? targetId;
  final String? targetName;

  bool get isForwarded => forwardedFromUserId != null;

  static const String systemEventType = 'system_event';
  bool get isSystemEvent => messageType == systemEventType;

  const GroupMessageModel({
    required this.id,
    this.clientMessageId,
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
    this.durationSeconds,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.caption,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToMessageType,
    this.replyToMediaUrl,
    this.mentions = const [],
    this.reactions = const {},
    this.reactionsCreatedAt,
    this.readBy = const {},
    this.isEdited = false,
    this.deletedFor = const [],
    this.forwardedFromUserId,
    this.forwardedFromUserName,
    this.forwardedFromUserAvatar,
    this.systemEventData,
    this.targetId,
    this.targetName,
  });

  static String? replyMediaUrlFrom(GroupMessageModel? original) {
    if (original == null) return null;
    switch (original.messageType) {
      case 'image':
      case 'gif':
      case 'sticker':
        return original.imageUrl;
      case 'video':
        return original.videoUrl;
      default:
        return null;
    }
  }

  GroupMessageModel copyWith({
    String? id,
    String? clientMessageId,
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
    int? durationSeconds,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    String? caption,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToMessageType,
    String? replyToMediaUrl,
    List<MentionRef>? mentions,
    Map<String, String>? reactions,
    Map<String, String>? reactionsCreatedAt,
    Set<String>? readBy,
    bool? isEdited,
    List<String>? deletedFor,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
    Map<String, dynamic>? systemEventData,
    String? targetId,
    String? targetName,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      clientMessageId: clientMessageId ?? this.clientMessageId,
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
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      caption: caption ?? this.caption,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToMessageType: replyToMessageType ?? this.replyToMessageType,
      replyToMediaUrl: replyToMediaUrl ?? this.replyToMediaUrl,
      mentions: mentions ?? this.mentions,
      reactions: reactions ?? this.reactions,
      reactionsCreatedAt: reactionsCreatedAt ?? this.reactionsCreatedAt,
      readBy: readBy ?? this.readBy,
      isEdited: isEdited ?? this.isEdited,
      deletedFor: deletedFor ?? this.deletedFor,
      forwardedFromUserId: forwardedFromUserId ?? this.forwardedFromUserId,
      forwardedFromUserName:
          forwardedFromUserName ?? this.forwardedFromUserName,
      forwardedFromUserAvatar:
          forwardedFromUserAvatar ?? this.forwardedFromUserAvatar,
      systemEventData: systemEventData ?? this.systemEventData,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
    );
  }

  static String? _nullIfEmpty(dynamic v) =>
      (v == null || v == '') ? null : v as String;

  factory GroupMessageModel.fromMap(
    Map<String, dynamic> map, {
    List<MentionRef> mentions = const [],
    List<Map<String, dynamic>> reactionsList = const [],
  }) {
    final Map<String, String> reactionsMap = {};
    final Map<String, String> reactionsCreatedAtMap = {};
    for (final r in reactionsList) {
      final userId = r[GroupMemberColumns.userId] as String?;
      final emoji = r['reaction'] as String?;
      final createdAt = r[MessageReactionColumns.createdAt] as String?;
      if (userId != null && emoji != null) {
        reactionsMap[userId] = emoji;
        if (createdAt != null) reactionsCreatedAtMap[userId] = createdAt;
      }
    }

    final readByRaw = map['read_by'];
    Set<String> readBySet = {};
    if (readByRaw is List) {
      readBySet = readByRaw.map((e) => e.toString()).toSet();
    }

    final deletedForRaw = map['deleted_for'];
    final List<String> deletedForList =
        deletedForRaw is List
            ? deletedForRaw.map((e) => e.toString()).toList()
            : const [];

    return GroupMessageModel(
      id: map['id'] as String,
      clientMessageId: _nullIfEmpty(map[GroupMessageColumns.clientMessageId]),
      groupId: map[GroupMemberColumns.groupId] as String,
      senderId: map['sender_id'] as String,
      senderName: (map['sender_name'] ?? 'Unknown') as String,
      senderAvatar: map['sender_avatar'] as String?,
      text: (map['message_text'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      messageType: (map['message_type'] ?? 'text') as String,
      imageUrl: _nullIfEmpty(map['image_url']),
      videoUrl: _nullIfEmpty(map['video_url']),
      voiceUrl: _nullIfEmpty(map['voice_url']),
      durationSeconds:
          (map[GroupMessageColumns.durationSeconds] as num?)?.toInt(),
      fileUrl: _nullIfEmpty(map['file_url']),

      fileName: map['file_name'] == '' ? null : map['file_name'] as String?,
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt(),
      caption: map['caption'] == '' ? null : map['caption'] as String?,
      replyToMessageId:
          map['reply_to_message_id'] == ''
              ? null
              : map['reply_to_message_id'] as String?,
      replyToText:
          map['reply_to_text'] == '' ? null : map['reply_to_text'] as String?,
      replyToSenderId:
          map['reply_to_sender_id'] == ''
              ? null
              : map['reply_to_sender_id'] as String?,
      replyToSenderName:
          map['reply_to_sender_name'] == ''
              ? null
              : map['reply_to_sender_name'] as String?,
      replyToMessageType:
          map['reply_to_message_type'] == ''
              ? null
              : map['reply_to_message_type'] as String?,
      replyToMediaUrl: _nullIfEmpty(map['reply_to_media_url']),
      mentions: mentions,
      reactions: reactionsMap,
      reactionsCreatedAt:
          reactionsCreatedAtMap.isEmpty ? null : reactionsCreatedAtMap,
      readBy: readBySet,
      isEdited: (map[GroupMessageColumns.isEdited] as bool?) ?? false,
      deletedFor: deletedForList,
      forwardedFromUserId:
          map['forwarded_from_user_id'] == ''
              ? null
              : map['forwarded_from_user_id'] as String?,
      forwardedFromUserName:
          map['forwarded_from_user_name'] == ''
              ? null
              : map['forwarded_from_user_name'] as String?,
      forwardedFromUserAvatar:
          map['forwarded_from_user_avatar'] == ''
              ? null
              : map['forwarded_from_user_avatar'] as String?,
      systemEventData: map['system_event_data'] as Map<String, dynamic>?,
      targetId: map['target_id'] as String?,
      targetName: map['target_name'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      GroupMemberColumns.groupId: groupId,
      'sender_id': senderId,
      // Omitted entirely (not sent as null) when absent, so this map is
      // byte-for-byte identical to before until a caller actually sets
      // clientMessageId AND the client_message_id column exists in the DB.
      if (clientMessageId != null)
        GroupMessageColumns.clientMessageId: clientMessageId,
      'message_text': text,
      'message_type': messageType,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (voiceUrl != null) 'voice_url': voiceUrl,
      if (durationSeconds != null)
        GroupMessageColumns.durationSeconds: durationSeconds,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (caption != null) 'caption': caption,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (replyToText != null) 'reply_to_text': replyToText,
      if (replyToSenderId != null) 'reply_to_sender_id': replyToSenderId,
      if (replyToSenderName != null) 'reply_to_sender_name': replyToSenderName,
      if (replyToMessageType != null)
        'reply_to_message_type': replyToMessageType,
      if (replyToMediaUrl != null) 'reply_to_media_url': replyToMediaUrl,
      if (targetId != null) 'target_id': targetId,
      if (targetName != null) 'target_name': targetName,
    };
  }

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    final mentionsRaw = json['mentions'];
    final List<MentionRef> mentionsList =
        mentionsRaw is List
            ? mentionsRaw
                .map((m) => MentionRef.fromCacheJson(m as Map<String, dynamic>))
                .toList()
            : const [];

    final reactionsRaw = json['reactions'];
    final Map<String, String> reactionsMap =
        reactionsRaw is Map
            ? reactionsRaw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
            : {};
    final reactionsCreatedAtRaw = json['reactionsCreatedAt'];
    final Map<String, String>? reactionsCreatedAtMap =
        reactionsCreatedAtRaw is Map
            ? reactionsCreatedAtRaw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
            : null;

    final readByRaw = json['read_by'];
    final Set<String> readBySet =
        readByRaw is List ? readByRaw.map((e) => e.toString()).toSet() : {};

    final deletedForRaw = json['deleted_for'];
    final List<String> deletedForList =
        deletedForRaw is List
            ? deletedForRaw.map((e) => e.toString()).toList()
            : const [];

    return GroupMessageModel(
      id: json['id'] as String,
      clientMessageId: _nullIfEmpty(json[GroupMessageColumns.clientMessageId]),
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
      durationSeconds:
          (json[GroupMessageColumns.durationSeconds] as num?)?.toInt(),
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] == '' ? null : json['file_name'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      caption: json['caption'] == '' ? null : json['caption'] as String?,
      replyToMessageId:
          json['reply_to_message_id'] == ''
              ? null
              : json['reply_to_message_id'] as String?,
      replyToText:
          json['reply_to_text'] == '' ? null : json['reply_to_text'] as String?,
      replyToSenderId:
          json['reply_to_sender_id'] == ''
              ? null
              : json['reply_to_sender_id'] as String?,
      replyToSenderName:
          json['reply_to_sender_name'] == ''
              ? null
              : json['reply_to_sender_name'] as String?,
      replyToMessageType:
          json['reply_to_message_type'] == ''
              ? null
              : json['reply_to_message_type'] as String?,
      replyToMediaUrl: _nullIfEmpty(json['reply_to_media_url']),
      mentions: mentionsList,
      reactions: reactionsMap,
      reactionsCreatedAt: reactionsCreatedAtMap,

      readBy: readBySet,
      isEdited: (json['is_edited'] as bool?) ?? false,
      deletedFor: deletedForList,
      forwardedFromUserId:
          json['forwarded_from_user_id'] == ''
              ? null
              : json['forwarded_from_user_id'] as String?,
      forwardedFromUserName:
          json['forwarded_from_user_name'] == ''
              ? null
              : json['forwarded_from_user_name'] as String?,
      forwardedFromUserAvatar:
          json['forwarded_from_user_avatar'] == ''
              ? null
              : json['forwarded_from_user_avatar'] as String?,
      systemEventData: json['system_event_data'] as Map<String, dynamic>?,
      targetId: json['target_id'] as String?,
      targetName: json['target_name'] as String?,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      GroupMessageColumns.clientMessageId: clientMessageId,
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
      GroupMessageColumns.durationSeconds: durationSeconds,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'caption': caption,
      'reply_to_message_id': replyToMessageId,
      'reply_to_text': replyToText,
      'reply_to_sender_id': replyToSenderId,
      'reply_to_sender_name': replyToSenderName,
      'reply_to_message_type': replyToMessageType,
      'reply_to_media_url': replyToMediaUrl,
      'mentions': mentions.map((m) => m.toCacheJson()).toList(),
      'reactions': reactions,
      'reactionsCreatedAt': reactionsCreatedAt,
      'read_by': readBy.toList(),
      'is_edited': isEdited,
      'deleted_for': deletedFor,
      'forwarded_from_user_id': forwardedFromUserId,
      'forwarded_from_user_name': forwardedFromUserName,
      'forwarded_from_user_avatar': forwardedFromUserAvatar,
      'system_event_data': systemEventData,
      'target_id': targetId,
      'target_name': targetName,
    };
  }
}
