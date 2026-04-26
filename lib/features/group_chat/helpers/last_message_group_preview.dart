import '../models/group_model.dart';

String buildGroupLastMessagePreview({
  required GroupModel group,
  required String? currentUserId,
}) {
  final type = group.lastMessageType ?? 'text';

  final hasNoMessage =
      (group.lastMessage == null || group.lastMessage!.trim().isEmpty) &&
      type == 'text';

  if (hasNoMessage) {
    return 'No messages yet';
  }

  final senderId = group.lastMessageSenderId;
  final senderNameFromData = group.lastMessageSenderName;

  final isMe =
      currentUserId != null && senderId != null && senderId == currentUserId;

  final senderName =
      isMe
          ? 'You'
          : (senderNameFromData?.trim().isNotEmpty == true
              ? senderNameFromData!
              : 'Someone');

  switch (type) {
    case 'image':
      return '$senderName: 📷 Photo';
    case 'video':
      return '$senderName: 🎬 Video';
    case 'voice':
      return '$senderName: 🎤 Voice message';
    case 'call':
      return '$senderName: 📞 Call';
    case 'text':
    default:
      return '$senderName: ${group.lastMessage}';
  }
}
