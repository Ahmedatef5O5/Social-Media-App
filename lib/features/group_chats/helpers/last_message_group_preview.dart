import '../models/group_model.dart';
import '../models/groupe_message_model.dart';

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

  if (type == GroupMessageModel.systemEventType) {
    var eventText = group.lastMessage ?? '';
    if (isMe &&
        senderNameFromData != null &&
        senderNameFromData.trim().isNotEmpty &&
        eventText.startsWith(senderNameFromData)) {
      eventText = eventText.replaceFirst(senderNameFromData, 'You');
    }
    final targetId = group.lastMessageTargetId;
    final targetNameFromData = group.lastMessageTargetName;

    final isTargetMe =
        currentUserId != null && targetId != null && targetId == currentUserId;

    if (isTargetMe &&
        targetNameFromData != null &&
        targetNameFromData.trim().isNotEmpty &&
        eventText.contains(targetNameFromData)) {
      eventText = eventText.replaceFirst(targetNameFromData, 'you');
    }

    return eventText;
  }

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
    case 'gif':
      return '$senderName: 🎞️ GIF';
    case 'sticker':
      return '$senderName: 😊 Sticker';
    case 'voice':
      return '$senderName: 🎤 Voice message';
    case 'call':
      return '$senderName: 📞 Group Call';

    case 'file':
      final fileName =
          (group.lastMessage != null &&
                  group.lastMessage!.trim().isNotEmpty &&
                  group.lastMessage!.toLowerCase() != 'file')
              ? group.lastMessage!.trim()
              : 'File';
      return '$senderName: 📄 $fileName';
    case 'text':
    default:
      return '$senderName: ${group.lastMessage}';
  }
}
