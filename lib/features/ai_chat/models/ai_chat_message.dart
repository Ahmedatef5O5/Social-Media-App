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
    this.localId,
    this.mediaType = AiChatMediaType.none,
    this.mediaUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.uploadProgress,
    this.model,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderRole,
    this.replyToMediaType,
    this.replyToMediaUrl,
  });

  final String id;

  /// [FIX 1 - Flicker] Client-side identity that is minted once, before the
  /// message ever reaches Supabase, and never changes afterwards.
  ///
  /// [id] flips from the optimistic temp value to the real database UUID the
  /// moment append_ai_chat_message returns. Keying list items off [id] meant
  /// that flip destroyed and rebuilt the element (losing its keep-alive and
  /// blinking the bubble). Widgets key off [stableKey] instead, so the swap
  /// is invisible while [id] stays truthful for reply/forward references.
  final String? localId;

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

  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderRole;
  final String? replyToMediaType;
  final String? replyToMediaUrl;

  bool get isMe => role == AiChatRole.user;
  bool get hasReply => replyToMessageId != null;

  /// Stable across the optimistic -> persisted transition. Use this for
  /// widget keys, never [id].
  String get stableKey => localId ?? id;

  bool get hasMedia => mediaType != AiChatMediaType.none;

  AiChatMessage copyWith({
    required String id,
    String? localId,
    AiChatDeliveryStatus? status,
    double? uploadProgress,
    bool clearUploadProgress = false,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderRole,
    String? replyToMediaType,
    String? replyToMediaUrl,
  }) {
    return AiChatMessage(
      id: id,
      localId: localId ?? this.localId,
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
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderRole: replyToSenderRole ?? this.replyToSenderRole,
      replyToMediaType: replyToMediaType ?? this.replyToMediaType,
      replyToMediaUrl: replyToMediaUrl ?? this.replyToMediaUrl,
    );
  }
}
