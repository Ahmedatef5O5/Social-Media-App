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
  };

  AiChatMessageRecord copyWith({String? status}) {
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
