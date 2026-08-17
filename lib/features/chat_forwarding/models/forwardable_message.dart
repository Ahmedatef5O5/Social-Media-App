import '../../single_chats/models/message_model.dart';
import '../../group_chats/models/groupe_message_model.dart';
import '../../ai_chat/models/ai_chat_message.dart';

class ForwardableMessage {
  final String originalSenderId;
  final String originalSenderName;
  final String? originalSenderAvatar;
  final String text;
  final String messageType;
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final int? durationSeconds;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? caption;

  const ForwardableMessage({
    required this.originalSenderId,
    required this.originalSenderName,
    this.originalSenderAvatar,
    required this.text,
    required this.messageType,
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.durationSeconds,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.caption,
  });

  /// Sentinel stored in `forwarded_from_user_id` when the original sender
  /// was Syncra (the AI assistant), not a real user. Deliberately not a
  /// valid UUID — real user ids always are, so this can never collide
  /// with one. `ForwardedHeader` checks for this exact value to render
  /// the AI variant (icon avatar, no profile navigation) instead of
  /// trying to load a real user.
  ///
  /// This reuses the existing forwarded_from_user_id/_name/_avatar text
  /// columns rather than adding new ones — forwarded_from_user_name
  /// carries the real resolved model label (e.g. "Gemini 2.5 Flash"),
  /// and forwarded_from_user_avatar stays null since Syncra has an icon,
  /// not a photo.
  static const String aiSenderId = 'ai:syncra';

  /// Builds a forwardable copy of an assistant reply from Syncra. Only
  /// ever called for `AiChatRole.assistant` messages — forwarding the
  /// user's own prompts out of Syncra isn't part of this feature.
  factory ForwardableMessage.fromAiChatMessage(AiChatMessage message) {
    return ForwardableMessage(
      originalSenderId: aiSenderId,
      originalSenderName: message.model?.label ?? 'Syncra AI',
      originalSenderAvatar: null,
      text: message.text,
      messageType: 'text', // Syncra is text-only for forwarding, for now
    );
  }

  factory ForwardableMessage.fromSingleChatMessage(
    MessageModel message, {
    required String currentUserId,
    required String currentUserName,
    String? currentUserAvatar,
    required String otherUserName,
    String? otherUserAvatar,
  }) {
    final isMine = message.senderId == currentUserId;
    return ForwardableMessage(
      originalSenderId: message.forwardedFromUserId ?? message.senderId,
      originalSenderName:
          message.forwardedFromUserName ??
          (isMine ? currentUserName : otherUserName),
      originalSenderAvatar:
          message.forwardedFromUserAvatar ??
          (isMine ? currentUserAvatar : otherUserAvatar),
      text: message.text,
      messageType: message.messageType,
      imageUrl: message.imageUrl,
      videoUrl: message.videoUrl,
      voiceUrl: message.voiceUrl,
      durationSeconds: message.durationSeconds,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSizeBytes: message.fileSizeBytes,
      caption: message.caption,
    );
  }

  factory ForwardableMessage.fromGroupMessage(GroupMessageModel message) {
    return ForwardableMessage(
      originalSenderId: message.forwardedFromUserId ?? message.senderId,
      originalSenderName: message.forwardedFromUserName ?? message.senderName,
      originalSenderAvatar:
          message.forwardedFromUserAvatar ?? message.senderAvatar,
      text: message.text,
      messageType: message.messageType,
      imageUrl: message.imageUrl,
      videoUrl: message.videoUrl,
      voiceUrl: message.voiceUrl,
      durationSeconds: message.durationSeconds,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSizeBytes: message.fileSizeBytes,
      caption: message.caption,
    );
  }
}
