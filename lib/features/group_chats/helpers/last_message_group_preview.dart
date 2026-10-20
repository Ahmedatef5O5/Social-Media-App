import '../models/group_model.dart';
import '../models/groupe_message_model.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

String buildGroupLastMessagePreview({
  required GroupModel group,
  required String? currentUserId,
}) {
  final type = group.lastMessageType ?? 'text';

  final hasNoMessage =
      (group.lastMessage == null || group.lastMessage!.trim().isEmpty) &&
      type == 'text';

  if (hasNoMessage) {
    return AppL10n.current.noMessagesYet2;
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
          ? AppL10n.current.you
          : (senderNameFromData?.trim().isNotEmpty == true
              ? senderNameFromData!
              : AppL10n.current.someone);

  switch (type) {
    case 'message_react':
      return group.lastMessage ?? '';
    case 'image':
      return AppL10n.current.photo3(senderName);
    case 'video':
      return AppL10n.current.video3(senderName);
    case 'gif':
      return AppL10n.current.gif2(senderName);
    case 'sticker':
      return AppL10n.current.sticker3(senderName);
    case 'voice':
      return AppL10n.current.voiceMessage4(senderName);
    case 'call':
      return AppL10n.current.groupCall(senderName);

    case 'file':
      final fileName =
          (group.lastMessage != null &&
                  group.lastMessage!.trim().isNotEmpty &&
                  group.lastMessage!.toLowerCase() != 'file')
              ? group.lastMessage!.trim()
              : AppL10n.current.file;
      return '$senderName: 📄 $fileName';
    case 'text':
    default:
      return '$senderName: ${group.lastMessage}';
  }
}
