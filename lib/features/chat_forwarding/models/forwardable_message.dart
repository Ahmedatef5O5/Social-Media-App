import '../../single_chats/models/message_model.dart';
import '../../group_chats/models/groupe_message_model.dart';

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
