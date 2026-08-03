import 'package:social_media_app/features/group_chats/models/groupe_message_model.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';

class StarredMessageEntry {
  final String id;
  final bool isMe;
  final String senderName;
  final String messageType;
  final String text;
  final String? caption;
  final String? imageUrl;
  final String? videoUrl;
  final String? fileName;
  final int? durationSeconds;
  final DateTime createdAt;
  final bool isRead;

  const StarredMessageEntry({
    required this.id,
    required this.isMe,
    required this.senderName,
    required this.messageType,
    required this.text,
    this.caption,
    this.imageUrl,
    this.videoUrl,
    this.fileName,
    this.durationSeconds,
    required this.createdAt,
    this.isRead = false,
  });

  /// One-line preview used in the row (mirrors how WhatsApp previews a
  /// starred message: an icon + short label for non-text types).
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
  }) {
    final isMe = senderId == currentUserId;
    return StarredMessageEntry(
      id: id,
      isMe: isMe,
      senderName: isMe ? meName : receiverName,
      messageType: messageType,
      text: text,
      caption: caption,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      fileName: fileName,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}

extension GroupMessageModelStarredX on GroupMessageModel {
  StarredMessageEntry toStarredEntry({required String currentUserId}) {
    return StarredMessageEntry(
      id: id,
      isMe: senderId == currentUserId,
      senderName: senderName,
      messageType: messageType,
      text: text,
      caption: caption,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      fileName: fileName,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      isRead: false,
    );
  }
}
