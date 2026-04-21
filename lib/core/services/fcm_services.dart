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

  // ── Send chat message notification ──
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

      await _post(payload, accessToken);
      debugPrint('✅ Chat FCM sent');
    } catch (e) {
      debugPrint('❌ Chat FCM failed: $e');
    }
  }

  // ── Send incoming call notification ──
  // This wakes the device even when the app is killed
  Future<void> sendCallNotification({
    required String receiverFcmToken,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callId,
    required String callType, // 'audio' | 'video'
  }) async {
    try {
      final accessToken = await _tokenService.getValidToken();

      final payload = FcmPayloadBuilder.buildIncomingCallPayload(
        receiverFcmToken: receiverFcmToken,
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        callId: callId,
        callType: callType,
      );

      await _post(payload, accessToken);
      debugPrint('✅ Call FCM sent → $callerName');
    } catch (e) {
      debugPrint('❌ Call FCM failed: $e');
    }
  }

  // ── Send group message notification ──
  Future<void> sendGroupNotification({
    required String receiverFcmToken,
    required String groupId,
    required String groupName,
    required String senderName,
    required String messageBody,
    String messageType = 'text',
    String senderImageUrl = '',
  }) async {
    try {
      final accessToken = await _tokenService.getValidToken();

      final payload = FcmPayloadBuilder.buildGroupMessagePayload(
        receiverFcmToken: receiverFcmToken,
        groupId: groupId,
        groupName: groupName,
        senderName: senderName,
        messageBody: messageBody,
        messageType: messageType,
        senderImageUrl: senderImageUrl,
      );

      await _post(payload, accessToken);
      debugPrint('✅ Group FCM sent → $groupName');
    } catch (e) {
      debugPrint('❌ Group FCM failed: $e');
    }
  }

  Future<void> _post(Map<String, dynamic> payload, String accessToken) async {
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
    debugPrint('FCM response: ${response.statusCode}');
  }
}
