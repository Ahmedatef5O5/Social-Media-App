import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_provider.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  Future<void> sendChatNotification({
    required String receiverFcmToken,
    required String senderId,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
    String? attachmentUrl,
  }) async {
    await _sendToEdgeFunction({
      'type': 'chat',
      'receiverFcmToken': receiverFcmToken,
      'senderId': senderId,
      'senderName': senderName,
      'messageBody': messageBody,
      'messageType': messageType,
      'senderImageUrl': senderImageUrl,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    });
  }

  Future<void> sendCallNotification({
    required String receiverFcmToken,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callId,
    required String callType,
  }) async {
    await _sendToEdgeFunction({
      'type': 'call',
      'receiverFcmToken': receiverFcmToken,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'callId': callId,
      'callType': callType,
    });
  }

  Future<void> sendGroupNotification({
    required String receiverFcmToken,
    required String groupId,
    required String groupName,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
  }) async {
    await _sendToEdgeFunction({
      'type': 'group',
      'receiverFcmToken': receiverFcmToken,
      'groupId': groupId,
      'groupName': groupName,
      'senderName': senderName,
      'messageBody': messageBody,
      'messageType': messageType,
      'senderImageUrl': senderImageUrl,
    });
  }

  Future<void> _sendToEdgeFunction(Map<String, dynamic> payload) async {
    try {
      final response = await SupabaseProvider.client.functions.invoke(
        'send-notification',
        body: payload,
      );

      debugPrint('✅ Notification sent via Edge Function: ${response.status}');
    } on FunctionException catch (e) {
      debugPrint('❌ Edge Function Error: ${e.reasonPhrase} - ${e.details}');
    } catch (e) {
      debugPrint('❌ General FCM Error: $e');
    }
  }
}
