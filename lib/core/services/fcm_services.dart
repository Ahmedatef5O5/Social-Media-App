import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/services/fcm_payload_builder.dart';
import 'package:social_media_app/core/services/fcm_token_service.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static final String _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/${AppSecrets.fcmProjectId}/messages:send';

  final _dio = dio_pkg.Dio(
    dio_pkg.BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final _tokenService = FcmTokenService();

  Future<void> sendChatNotification({
    required String receiverFcmToken,
    required String senderId,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
    String? attachmentUrl,
  }) async {
    try {
      final accessToken = await _tokenService.getValidToken();

      final payload = FcmPayloadBuilder.buildChatPayload(
        receiverFcmToken: receiverFcmToken,
        senderId: senderId,
        senderName: senderName,
        messageBody: messageBody,
        messageType: messageType,
        senderImageUrl: senderImageUrl,
        attachmentUrl: attachmentUrl,
      );

      final response = await _dio.post(
        _fcmUrl,
        data: payload,
        options: dio_pkg.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('✅ FCM sent → ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ FCM send failed: $e');
    }
  }
}
