import '../models/message_model.dart';

class ChatSystemEventTextBuilder {
  static String build({
    required MessageModel message,
    required String currentUserId,
    required String otherUserName,
  }) {
    final isMe = message.senderId == currentUserId;

    if (message.messageType == MessageModel.blockEventType) {
      return isMe ? 'You blocked $otherUserName' : '$otherUserName blocked you';
    }
    if (message.messageType == MessageModel.unblockEventType) {
      return isMe
          ? 'You unblocked $otherUserName'
          : '$otherUserName unblocked you';
    }
    return message.text;
  }
}
