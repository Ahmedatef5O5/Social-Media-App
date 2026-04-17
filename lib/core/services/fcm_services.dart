import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:googleapis_auth/auth_io.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static final String _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/${AppSecrets.fcmProjectId}/messages:send';

  final dio_pkg.Dio _dio = dio_pkg.Dio(
    dio_pkg.BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<String> _getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": AppSecrets.fcmProjectId,
      "private_key": AppSecrets.fcmPrivateKey.trim(),

      "client_email": AppSecrets.fcmClientEmail,
      "client_id": AppSecrets.fcmClientId,
      "token_uri": "https://oauth2.googleapis.com/token",
    };

    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(credentials, scopes);

    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  Future<void> sendNotification({
    required String receiverFcmToken,
    required String senderId,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
    String? attachmentUrl,
  }) async {
    final String displayBody = _buildDisplayBody(messageBody, messageType);

    try {
      final String accessToken = await _getAccessToken();

      final Map<String, dynamic> payload = {
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

      final response = await _dio.post(
        _fcmUrl,
        data: payload,
        options: dio_pkg.Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      debugPrint('✅ FCM V1 sent → status: ${response.statusCode}');
    } catch (e) {
      if (e is dio_pkg.DioException) {
        debugPrint('⚠️ FCM error details: ${e.response?.data}');
      }
      debugPrint('⚠️ FCM send failed: $e');
    }
  }

  String _buildDisplayBody(String text, String type) {
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
