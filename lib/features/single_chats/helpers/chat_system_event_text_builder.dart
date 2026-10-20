import '../models/message_model.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

class ChatSystemEventTextBuilder {
  static String build({
    required MessageModel message,
    required String currentUserId,
    required String otherUserName,
  }) {
    final isMe = message.senderId == currentUserId;

    if (message.messageType == MessageModel.blockEventType) {
      return isMe
          ? AppL10n.current.youBlocked(otherUserName)
          : AppL10n.current.blockedYou(otherUserName);
    }
    if (message.messageType == MessageModel.unblockEventType) {
      return isMe
          ? AppL10n.current.youUnblocked(otherUserName)
          : AppL10n.current.unblockedYou(otherUserName);
    }
    return message.text;
  }
}
