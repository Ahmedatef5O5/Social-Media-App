import '../secrets/app_secrets.dart';

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
        // 'notification': {'title': senderName, 'body': displayBody},
        'data': {
          'notificationType': 'chat',
          'senderId': senderId,
          'senderName': senderName,
          'messageBody': displayBody,
          'messageType': messageType,
          'senderImageUrl': senderImageUrl,
          'messageImageUrl': attachmentUrl ?? '',
        },
        // 'android': {
        //   'priority': 'high',
        //   'notification': {
        //     'channel_id': 'chat_messages_channel',
        //     'sound': 'message_tone',
        //   },
        // },
      },
    };
  }

  static Map<String, dynamic> buildIncomingCallPayload({
    required String receiverFcmToken,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callId,
    required String callType,
  }) {
    return {
      'message': {
        'token': receiverFcmToken,
        'data': {
          'notificationType': 'incoming_call',
          'callId': callId,
          'callerId': callerId,
          'callerName': callerName,
          'callerAvatar': callerAvatar,
          'callType': callType,
          'supabaseUrl': AppSecrets.supabaseUrl,
          'supabaseAnonKey': AppSecrets.supabaseAnonKey,
        },
        'android': {'priority': 'high', 'ttl': '30s'},
        'apns': {
          'headers': {'apns-priority': '10', 'apns-push-type': 'voip'},
          'payload': {
            'aps': {
              'alert': {
                'title': callerName,
                'body':
                    callType == 'video'
                        ? 'Incoming video call...'
                        : 'Incoming voice call...',
              },
              'sound': 'default',
              'content-available': 1,
            },
          },
        },
      },
    };
  }

  static Map<String, dynamic> buildGroupMessagePayload({
    required String receiverFcmToken,
    required String groupId,
    required String groupName,
    required String senderName,
    required String messageBody,
    required String messageType,
    required String senderImageUrl,
  }) {
    final displayBody = _buildDisplayBody(messageBody, messageType);

    return {
      'message': {
        'token': receiverFcmToken,
        // 'notification': {
        //   'title': '$senderName @ $groupName',
        //   'body': displayBody,
        // },
        'data': {
          'notificationType': 'group_message',
          'groupId': groupId,
          'groupName': groupName,
          'senderName': senderName,
          'messageBody': displayBody,
          'messageType': messageType,
          'senderImageUrl': senderImageUrl,
        },
        // 'android': {
        //   'priority': 'high',
        //   'notification': {
        //     'channel_id': 'chat_messages_channel',
        //     'sound': 'message_tone',
        //   },
        // },
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
      case 'call':
        return '📞 Missed call';
      default:
        return text;
    }
  }
}
