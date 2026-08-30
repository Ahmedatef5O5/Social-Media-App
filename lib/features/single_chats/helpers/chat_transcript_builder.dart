import '../models/message_model.dart';

/// This mapping is done here deterministically (not left to Gemini to
/// guess), since we already know exactly who "you" is.
class ChatTranscriptBuilder {
  static String fromMessages({
    required List<MessageModel> messages,
    required String currentUserId,
    required String otherUserName,
    required int maxMessages,
  }) {
    final recent =
        messages.length > maxMessages
            ? messages.sublist(messages.length - maxMessages)
            : messages;

    final buffer = StringBuffer();
    for (final message in recent) {
      final text = message.text.trim();
      if (text.isEmpty) continue; // skip media/voice messages with no text

      final who = message.senderId == currentUserId ? 'You' : otherUserName;
      buffer.writeln('$who: $text');
    }
    return buffer.toString().trim();
  }
}
