class FcmPayloadBuilder {
  static Map<String, dynamic> buildChatPayload({
    required String receiverFcmToken,
    required String senderId,
    required String senderName,
    required String messageBody,
    required String messageType,
    required String senderImageUrl,
    String? attachmentUrl,
  }) {
    final displayBody = _buildDisplayBody(messageBody, messageType);

    return {
      'message': {
        'token': receiverFcmToken,
        'notification': {'title': senderName, 'body': displayBody},
        'data': {
          'senderId': senderId,
          'senderName': senderName,
          'messageBody': displayBody,
          'messageType': messageType,
          'senderImageUrl': senderImageUrl,
          'messageImageUrl': attachmentUrl ?? '',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'chat_messages_channel',
            'sound': 'message_tone',
          },
        },
      },
    };
  }

  static String _buildDisplayBody(String text, String type) {
    switch (type) {
      case 'image':
        return text.isNotEmpty ? '📷 $text' : '📷 Photo';
      case 'video':
        return text.isNotEmpty ? '🎥 $text' : '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      default:
        return text;
    }
  }
}
