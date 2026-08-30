import 'package:social_media_app/core/utilities/supabase_constants.dart';

class MessageModel {
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
  final int? durationSeconds;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? caption;
  final Map<String, String> reactions;
  final Map<String, String>? reactionsCreatedAt;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToMessageType;
  final String? replyToSenderId;
  final String? replyToMediaUrl;
  final List<String> deletedFor;
  final String? replyToStoryId;
  final String? replyToStoryAuthorId;
  final String? replyToStoryType;
  final String? replyToStoryMediaUrl;
  final String? replyToStoryText;
  final String? replyToStoryBgColor;
  final int? replyToStoryDurationSeconds;
  final String? forwardedFromUserId;
  final String? forwardedFromUserName;
  final String? forwardedFromUserAvatar;

  const MessageModel({
    required this.id,
    this.clientMessageId,
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
    this.durationSeconds,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.caption,
    this.reactions = const {},
    this.reactionsCreatedAt,
    this.replyToMessageId,
    this.replyToText,
    this.replyToMessageType,
    this.replyToSenderId,
    this.replyToMediaUrl,
    this.deletedFor = const [],
    this.replyToStoryId,
    this.replyToStoryAuthorId,
    this.replyToStoryType,
    this.replyToStoryMediaUrl,
    this.replyToStoryText,
    this.replyToStoryBgColor,
    this.replyToStoryDurationSeconds,
    this.forwardedFromUserId,
    this.forwardedFromUserName,
    this.forwardedFromUserAvatar,
  });

  static String? replyMediaUrlFrom(MessageModel? original) {
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

  bool get isStoryReply => replyToStoryType != null;
  bool get isForwarded => forwardedFromUserId != null;

  static const String blockEventType = 'block_event';
  static const String unblockEventType = 'unblock_event';
  bool get isSystemEvent =>
      messageType == blockEventType || messageType == unblockEventType;

  MessageModel copyWith({
    String? id,
    String? clientMessageId,
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
    int? durationSeconds,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    String? caption,
    Map<String, String>? reactions,
    Map<String, String>? reactionsCreatedAt,
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
    String? replyToMediaUrl,
    List<String>? deletedFor,
    String? replyToStoryId,
    String? replyToStoryAuthorId,
    String? replyToStoryType,
    String? replyToStoryMediaUrl,
    String? replyToStoryText,
    String? replyToStoryBgColor,
    int? replyToStoryDurationSeconds,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
  }) {
    return MessageModel(
      id: id ?? this.id,
      clientMessageId: clientMessageId ?? this.clientMessageId,
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
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      caption: caption ?? this.caption,
      reactions: reactions ?? this.reactions,
      reactionsCreatedAt: reactionsCreatedAt ?? this.reactionsCreatedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToMessageType: replyToMessageType ?? this.replyToMessageType,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToMediaUrl: replyToMediaUrl ?? this.replyToMediaUrl,
      deletedFor: deletedFor ?? this.deletedFor,
      replyToStoryId: replyToStoryId ?? this.replyToStoryId,
      replyToStoryAuthorId: replyToStoryAuthorId ?? this.replyToStoryAuthorId,
      replyToStoryType: replyToStoryType ?? this.replyToStoryType,
      replyToStoryMediaUrl: replyToStoryMediaUrl ?? this.replyToStoryMediaUrl,
      replyToStoryText: replyToStoryText ?? this.replyToStoryText,
      replyToStoryBgColor: replyToStoryBgColor ?? this.replyToStoryBgColor,
      replyToStoryDurationSeconds:
          replyToStoryDurationSeconds ?? this.replyToStoryDurationSeconds,
      forwardedFromUserId: forwardedFromUserId ?? this.forwardedFromUserId,
      forwardedFromUserName:
          forwardedFromUserName ?? this.forwardedFromUserName,
      forwardedFromUserAvatar:
          forwardedFromUserAvatar ?? this.forwardedFromUserAvatar,
    );
  }

  static String? _nullIfEmpty(dynamic v) =>
      (v == null || v == '') ? null : v as String;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
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
    return MessageModel(
      id: json[MessagesColumns.id],
      clientMessageId: _nullIfEmpty(json[MessagesColumns.clientMessageId]),
      senderId: json[MessagesColumns.senderId],
      receiverId: json[MessagesColumns.receiverId],
      text: json[MessagesColumns.messageText],
      createdAt: DateTime.parse(json[MessagesColumns.createdAt]),
      isRead: json[MessagesColumns.isRead] ?? false,
      isEdited: json[MessagesColumns.isEdited] ?? false,
      messageType: json[MessagesColumns.messageType] ?? 'text',
      imageUrl: _nullIfEmpty(json[MessagesColumns.imageUrl]),
      videoUrl: _nullIfEmpty(json[MessagesColumns.videoUrl]),
      voiceUrl: _nullIfEmpty(json[MessagesColumns.voiceUrl]),
      durationSeconds: (json[MessagesColumns.durationSeconds] as num?)?.toInt(),
      fileUrl: _nullIfEmpty(json[MessagesColumns.fileUrl]),
      fileName:
          json[MessagesColumns.fileName] == ''
              ? null
              : json[MessagesColumns.fileName],
      fileSizeBytes: (json[MessagesColumns.fileSizeBytes] as num?)?.toInt(),
      caption:
          json[MessagesColumns.caption] == ''
              ? null
              : json[MessagesColumns.caption],
      reactions: reactionsMap,
      reactionsCreatedAt: reactionsCreatedAtMap,
      replyToMessageId:
          json[MessagesColumns.replyToMessageId] == ''
              ? null
              : json[MessagesColumns.replyToMessageId],
      replyToText:
          json[MessagesColumns.replyToText] == ''
              ? null
              : json[MessagesColumns.replyToText],
      replyToMessageType:
          json[MessagesColumns.replyToMessageType] == ''
              ? null
              : json[MessagesColumns.replyToMessageType],
      replyToSenderId:
          json[MessagesColumns.replyToSenderId] == ''
              ? null
              : json[MessagesColumns.replyToSenderId],
      replyToMediaUrl: _nullIfEmpty(
        json[MessagesColumns.replyToMediaUrl],
      ), // NEW

      deletedFor:
          (json[MessagesColumns.deletedFor] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      replyToStoryId:
          json[MessagesColumns.replyToStoryId] == ''
              ? null
              : json[MessagesColumns.replyToStoryId],
      replyToStoryAuthorId:
          json[MessagesColumns.replyToStoryAuthorId] == ''
              ? null
              : json[MessagesColumns.replyToStoryAuthorId],
      replyToStoryType:
          json[MessagesColumns.replyToStoryType] == ''
              ? null
              : json[MessagesColumns.replyToStoryType],
      replyToStoryMediaUrl:
          json[MessagesColumns.replyToStoryMediaUrl] == ''
              ? null
              : json[MessagesColumns.replyToStoryMediaUrl],
      replyToStoryText:
          json[MessagesColumns.replyToStoryText] == ''
              ? null
              : json[MessagesColumns.replyToStoryText],
      replyToStoryBgColor:
          json[MessagesColumns.replyToStoryBgColor] == ''
              ? null
              : json[MessagesColumns.replyToStoryBgColor],
      replyToStoryDurationSeconds:
          (json[MessagesColumns.replyToStoryDurationSeconds] as num?)?.toInt(),
      forwardedFromUserId:
          json[MessagesColumns.forwardedFromUserId] == ''
              ? null
              : json[MessagesColumns.forwardedFromUserId],
      forwardedFromUserName:
          json[MessagesColumns.forwardedFromUserName] == ''
              ? null
              : json[MessagesColumns.forwardedFromUserName],
      forwardedFromUserAvatar:
          json[MessagesColumns.forwardedFromUserAvatar] == ''
              ? null
              : json[MessagesColumns.forwardedFromUserAvatar],
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      MessagesColumns.id: id,
      MessagesColumns.clientMessageId: clientMessageId,
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
      MessagesColumns.durationSeconds: durationSeconds,
      MessagesColumns.fileUrl: fileUrl,
      MessagesColumns.fileName: fileName,
      MessagesColumns.fileSizeBytes: fileSizeBytes,
      MessagesColumns.caption: caption,
      'reactions': reactions,
      'reactionsCreatedAt': reactionsCreatedAt,
      MessagesColumns.replyToMessageId: replyToMessageId,
      MessagesColumns.replyToText: replyToText,
      MessagesColumns.replyToMessageType: replyToMessageType,
      MessagesColumns.replyToSenderId: replyToSenderId,
      MessagesColumns.replyToMediaUrl: replyToMediaUrl,
      MessagesColumns.deletedFor: deletedFor,
      MessagesColumns.replyToStoryId: replyToStoryId,
      MessagesColumns.replyToStoryAuthorId: replyToStoryAuthorId,
      MessagesColumns.replyToStoryType: replyToStoryType,
      MessagesColumns.replyToStoryMediaUrl: replyToStoryMediaUrl,
      MessagesColumns.replyToStoryText: replyToStoryText,
      MessagesColumns.replyToStoryBgColor: replyToStoryBgColor,
      MessagesColumns.replyToStoryDurationSeconds: replyToStoryDurationSeconds,
      MessagesColumns.forwardedFromUserId: forwardedFromUserId,
      MessagesColumns.forwardedFromUserName: forwardedFromUserName,
      MessagesColumns.forwardedFromUserAvatar: forwardedFromUserAvatar,
    };
  }
}
