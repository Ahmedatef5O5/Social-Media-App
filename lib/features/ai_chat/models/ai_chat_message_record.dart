import 'package:hive/hive.dart';
import '../../../core/cache/constants/hive_type_ids.dart';
import 'ai_chat_message.dart';
import '../helpers/ai_model_display.dart';
part 'ai_chat_message_record.g.dart';

@HiveType(typeId: HiveTypeIds.aiChatMessage)
class AiChatMessageRecord extends HiveObject {
  AiChatMessageRecord({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    this.mediaType = 'none',
    this.mediaUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.provider,
    this.model,
    required this.degraded,
    this.requestId,
    required this.status,
    required this.createdAt,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderRole,
    this.replyToMediaType,
    this.replyToMediaUrl,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId;

  @HiveField(2)
  final String role; // 'user' | 'assistant' | 'system'

  @HiveField(3)
  final String text;

  @HiveField(4)
  final String mediaType; // 'none' | 'image' | 'video' | 'voice' | 'file'

  @HiveField(5)
  final String? mediaUrl;

  @HiveField(6)
  final String? fileName;

  @HiveField(7)
  final int? fileSizeBytes;

  @HiveField(8)
  final int? durationSeconds;

  @HiveField(9)
  final String? provider;

  @HiveField(10)
  final String? model;

  @HiveField(11)
  final bool degraded;

  @HiveField(12)
  final String? requestId;

  @HiveField(13)
  final String status; // 'sending' | 'sent' | 'failed'

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final String? replyToMessageId;

  @HiveField(16)
  final String? replyToText;

  @HiveField(17)
  final String? replyToSenderRole;

  @HiveField(18)
  final String? replyToMediaType;

  @HiveField(19)
  final String? replyToMediaUrl;

  factory AiChatMessageRecord.fromJson(Map<String, dynamic> json) =>
      AiChatMessageRecord(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        role: json['role'] as String,
        text: json['content'] as String,
        mediaType: json['attachment_type'] as String? ?? 'none',
        mediaUrl: json['attachment_url'] as String?,
        fileName: json['file_name'] as String?,
        fileSizeBytes: json['file_size_bytes'] as int?,
        durationSeconds: json['duration_seconds'] as int?,
        provider: json['provider'] as String?,
        model: json['model'] as String?,
        degraded: json['degraded'] as bool? ?? false,
        requestId: json['request_id'] as String?,
        status: json['status'] as String? ?? 'sent',
        createdAt: DateTime.parse(json['created_at'] as String),
        // [FIX] كانت ناقصة تمامًا
        replyToMessageId: json['reply_to_message_id'] as String?,
        replyToText: json['reply_to_message_text'] as String?,
        replyToSenderRole: json['reply_to_sender_role'] as String?,
        replyToMediaType: json['reply_to_media_type'] as String?,
        replyToMediaUrl: json['reply_to_media_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'role': role,
    'content': text,
    'attachment_type': mediaType == 'none' ? null : mediaType,
    'attachment_url': mediaUrl,
    'file_name': fileName,
    'file_size_bytes': fileSizeBytes,
    'duration_seconds': durationSeconds,
    'provider': provider,
    'model': model,
    'degraded': degraded,
    'request_id': requestId,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'reply_to_message_id': replyToMessageId,
    'reply_to_message_text': replyToText,
    'reply_to_sender_role': replyToSenderRole,
    'reply_to_media_type': replyToMediaType,
    'reply_to_media_url': replyToMediaUrl,
  };

  AiChatMessageRecord copyWith({
    String? status,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderRole,
    String? replyToMediaType,
    String? replyToMediaUrl,
  }) {
    return AiChatMessageRecord(
      id: id,
      sessionId: sessionId,
      role: role,
      text: text,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      provider: provider,
      model: model,
      degraded: degraded,
      requestId: requestId,
      status: status ?? this.status,
      createdAt: createdAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderRole: replyToSenderRole ?? this.replyToSenderRole,
      replyToMediaType: replyToMediaType ?? this.replyToMediaType,
      replyToMediaUrl: replyToMediaUrl ?? this.replyToMediaUrl,
    );
  }
}

extension AiChatMessageRecordMapping on AiChatMessageRecord {
  AiChatMessage toDomain() {
    return AiChatMessage(
      id: id,
      role: _roleFromString(role),
      text: text,
      status: _statusFromString(status),
      createdAt: createdAt,
      mediaType: _mediaTypeFromString(mediaType),
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      model:
          (provider != null && provider!.isNotEmpty && model != null)
              ? AiModelDisplay.fromRaw(provider!, model!)
              : null,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderRole: replyToSenderRole,
      replyToMediaType: replyToMediaType,
      replyToMediaUrl: replyToMediaUrl,
    );
  }

  static AiChatRole _roleFromString(String value) => switch (value) {
    'assistant' => AiChatRole.assistant,
    'system' => AiChatRole.system,
    _ => AiChatRole.user,
  };

  static AiChatDeliveryStatus _statusFromString(String value) =>
      switch (value) {
        'sending' => AiChatDeliveryStatus.sending,
        'failed' => AiChatDeliveryStatus.failed,
        _ => AiChatDeliveryStatus.sent,
      };

  static AiChatMediaType _mediaTypeFromString(String value) => switch (value) {
    'image' => AiChatMediaType.image,
    'video' => AiChatMediaType.video,
    'voice' => AiChatMediaType.voice,
    'file' => AiChatMediaType.file,
    _ => AiChatMediaType.none,
  };
}
