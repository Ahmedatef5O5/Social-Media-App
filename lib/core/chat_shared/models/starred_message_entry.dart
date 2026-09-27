import 'package:social_media_app/features/group_chats/models/groupe_message_model.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';

class StarredMessageEntry {
  final String id;
  final bool isMe;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String messageType;
  final String text;
  final String? caption;
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final DateTime createdAt;
  final bool isRead;
  final String? replyToStoryId;
  final String? replyToStoryAuthorId;
  final String? replyToStoryType;
  final String? replyToStoryMediaUrl;
  final String? replyToStoryText;
  final String? replyToStoryBgColor;
  final int? replyToStoryDurationSeconds;

  const StarredMessageEntry({
    required this.id,
    required this.isMe,
    this.senderId = '',
    required this.senderName,
    this.senderAvatar,
    required this.messageType,
    required this.text,
    this.caption,
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    required this.createdAt,
    this.isRead = false,
    this.replyToStoryId,
    this.replyToStoryAuthorId,
    this.replyToStoryType,
    this.replyToStoryMediaUrl,
    this.replyToStoryText,
    this.replyToStoryBgColor,
    this.replyToStoryDurationSeconds,
  });

  bool get isStoryReply => replyToStoryType != null;

  String get previewText {
    switch (messageType) {
      case 'image':
        return caption?.isNotEmpty == true ? caption! : 'Photo';
      case 'video':
        return caption?.isNotEmpty == true ? caption! : 'Video';
      case 'voice':
        return 'Voice message';
      case 'file':
        return fileName ?? 'File';
      case 'call':
        return text.isNotEmpty ? text : 'Call';
      case 'gif':
        return 'GIF';
      case 'sticker':
        return 'Sticker';
      default:
        return text;
    }
  }
}

extension MessageModelStarredX on MessageModel {
  StarredMessageEntry toStarredEntry({
    required String currentUserId,
    required String meName,
    required String receiverName,
    String? meAvatar,
    String? receiverAvatar,
  }) {
    final isMe = senderId == currentUserId;
    return StarredMessageEntry(
      id: id,
      isMe: isMe,
      senderId: senderId,
      senderName: isMe ? meName : receiverName,
      senderAvatar: isMe ? meAvatar : receiverAvatar,
      messageType: messageType,
      text: text,
      caption: caption,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      voiceUrl: voiceUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      isRead: isRead,
      replyToStoryId: replyToStoryId,
      replyToStoryAuthorId: replyToStoryAuthorId,
      replyToStoryType: replyToStoryType,
      replyToStoryMediaUrl: replyToStoryMediaUrl,
      replyToStoryText: replyToStoryText,
      replyToStoryBgColor: replyToStoryBgColor,
      replyToStoryDurationSeconds: replyToStoryDurationSeconds,
    );
  }
}

extension GroupMessageModelStarredX on GroupMessageModel {
  StarredMessageEntry toStarredEntry({
    required String currentUserId,
    String? fallbackAvatar,
  }) {
    final resolvedAvatar =
        (senderAvatar != null && senderAvatar!.isNotEmpty)
            ? senderAvatar
            : fallbackAvatar;
    return StarredMessageEntry(
      id: id,
      isMe: senderId == currentUserId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: resolvedAvatar,
      messageType: messageType,
      text: text,
      caption: caption,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      voiceUrl: voiceUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      isRead: false,
    );
  }
}
