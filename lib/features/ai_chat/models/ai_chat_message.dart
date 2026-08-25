import 'package:flutter/foundation.dart';
import '../helpers/ai_model_display.dart';

enum AiChatRole { user, assistant, system }

enum AiChatDeliveryStatus { sending, sent, failed }

enum AiChatMediaType { none, image, video, voice, file }

@immutable
class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.status,
    required this.createdAt,
    this.mediaType = AiChatMediaType.none,
    this.mediaUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.uploadProgress,
    this.model,
  });

  final String id;
  final AiChatRole role;
  final String text;
  final AiChatDeliveryStatus status;
  final DateTime createdAt;

  final AiChatMediaType mediaType;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final double? uploadProgress;
  final AiModelDisplay? model;

  bool get isMe => role == AiChatRole.user;

  AiChatMessage copyWith({
    required String id,
    AiChatDeliveryStatus? status,
    double? uploadProgress,
    bool clearUploadProgress = false,
  }) {
    return AiChatMessage(
      id: id,
      role: role,
      text: text,
      status: status ?? this.status,
      createdAt: createdAt,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      uploadProgress:
          clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      model: model,
    );
  }
}
