import '../models/groupe_message_model.dart';

class GroupChatTranscriptBuilder {
  static String fromMessages({
    required List<GroupMessageModel> messages,
    required String currentUserId,
    required int maxMessages,
  }) {
    final recent =
        messages.length > maxMessages
            ? messages.sublist(messages.length - maxMessages)
            : messages;

    final buffer = StringBuffer();
    for (final message in recent) {
      final text = message.text.trim();
      if (text.isEmpty) continue;

      final who =
          message.senderId == currentUserId ? 'You' : message.senderName;
      buffer.writeln('$who: $text');
    }
    return buffer.toString().trim();
  }
}
