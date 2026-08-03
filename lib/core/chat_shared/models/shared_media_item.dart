import 'package:social_media_app/features/group_chats/models/groupe_message_model.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';

/// Chat-agnostic adapter model consumed by `SharedMediaView`.
///
/// Single chat's `MessageModel` and group chat's `GroupMessageModel` are
/// two different classes with different shapes (group messages embed
/// sender name/avatar directly since a group has many senders; single
/// chat messages don't, since the sender is always either "me" or "the
/// other person"). `SharedMediaItem` is the common shape both map to, so
/// one media-browsing UI can serve both features.
class SharedMediaItem {
  final String id;
  final String messageType;
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final String? fileUrl;
  final String? fileName;

  /// Raw message text (used for link detection/display in the Links tab).
  final String text;
  final int? durationSeconds;
  final int? fileSizeBytes;
  final DateTime createdAt;

  final String senderId;
  final String senderName;
  final String? senderAvatar;

  const SharedMediaItem({
    required this.id,
    required this.messageType,
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.fileUrl,
    this.fileName,
    required this.text,
    this.durationSeconds,
    this.fileSizeBytes,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
  });
}

extension MessageModelSharedMediaX on MessageModel {
  /// Single chat has no embedded sender name/avatar (it's always either
  /// "me" or "the receiver"), so the caller resolves it from context.
  SharedMediaItem toSharedMediaItem({
    required String currentUserId,
    required String currentUserName,
    String? currentUserAvatar,
    required String receiverName,
    String? receiverAvatar,
  }) {
    final isMe = senderId == currentUserId;
    return SharedMediaItem(
      id: id,
      messageType: messageType,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      voiceUrl: voiceUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      text: (caption != null && caption!.isNotEmpty) ? caption! : text,
      durationSeconds: durationSeconds,
      fileSizeBytes: fileSizeBytes,
      createdAt: createdAt,
      senderId: senderId,
      senderName: isMe ? currentUserName : receiverName,
      senderAvatar: isMe ? currentUserAvatar : receiverAvatar,
    );
  }
}

extension GroupMessageModelSharedMediaX on GroupMessageModel {
  SharedMediaItem toSharedMediaItem() {
    return SharedMediaItem(
      id: id,
      messageType: messageType,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      voiceUrl: voiceUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      text: (caption != null && caption!.isNotEmpty) ? caption! : text,
      durationSeconds: durationSeconds,
      fileSizeBytes: fileSizeBytes,
      createdAt: createdAt,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }
}
