import 'dart:typed_data';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/notifications/channels/notification_channel_setup.dart';
import 'package:social_media_app/core/notifications/helpers/notification_app_state_helper.dart';
import 'package:social_media_app/core/notifications/helpers/notification_avatar_builder.dart';
import 'package:social_media_app/core/notifications/helpers/notification_id_helper.dart';
import 'package:social_media_app/core/notifications/notification_navigator_key.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/incoming_call_navigation_guard.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';

class CallNotificationDispatcher {
  CallNotificationDispatcher._();
  static final CallNotificationDispatcher instance =
      CallNotificationDispatcher._();

  final NotificationAvatarBuilder _avatarBuilder = NotificationAvatarBuilder();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> showIncomingCallNotification({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callType,
  }) async {
    Uint8List profileBitmap;
    try {
      profileBitmap = await _avatarBuilder.getAvatarBitmap(callerAvatar);
    } catch (_) {
      profileBitmap = await _avatarBuilder.defaultBitmap();
    }

    final subtitle =
        callType == 'video' ? 'Incoming video call' : 'Incoming voice call';

    final androidDetails = AndroidNotificationDetails(
      NotificationChannelSetup.callChannel.id,
      NotificationChannelSetup.callChannel.name,
      channelDescription: NotificationChannelSetup.callChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(profileBitmap),
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 60000,
      actions: [
        const AndroidNotificationAction(
          'decline_call',
          'Decline',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'accept_call',
          'Accept',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );

    await _localNotifications.show(
      createNotificationId(callId),
      callerName,
      subtitle,
      NotificationDetails(android: androidDetails),
      payload: 'call|$callId|$callerId|$callerName|$callerAvatar|$callType',
    );
  }

  Future<void> cancelCallNotification(String callId) async {
    await _localNotifications.cancel(createNotificationId(callId));
  }

  Future<void> handleIncomingCallData(Map<String, dynamic> data) async {
    final callId = data['callId'] as String? ?? '';
    final callerId =
        (data['callerId'] ??
                data['initiatorId'] ??
                data['initiator_id'] ??
                data['senderId'])
            as String? ??
        '';
    final callerName = data['callerName'] as String? ?? 'Unknown';
    final callerAvatar = data['callerAvatar'] as String? ?? '';
    final callType = data['callType'] as String? ?? 'audio';

    if (callerId.isNotEmpty && callerId == SupabaseProvider.idOrNull) return;

    if (!isAppInForeground()) {
      await showIncomingCallNotification(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        callType: callType,
      );
    }

    if (!IncomingCallNavigationGuard.claim(callId)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState
          ?.pushNamed(
            AppRoutes.incomingCallRoute,
            arguments: {
              'callId': callId,
              'callerId': callerId,
              'callerName': callerName,
              'callerAvatar': callerAvatar,
              'callType': callType,
            },
          )
          .then((_) => IncomingCallNavigationGuard.release(callId));
    });
  }

  Future<void> rejectCallViaRest(String callId) async {
    try {
      final dio = dio_pkg.Dio();
      const supabaseUrl = String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      );
      const anonKey = String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      );

      if (supabaseUrl.isEmpty || anonKey.isEmpty) return;

      await dio.patch(
        '$supabaseUrl/rest/v1/calls?call_id=eq.$callId',
        data: {'status': 'rejected'},
        options: dio_pkg.Options(
          headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
        ),
      );
    } catch (e) {
      debugPrint('_rejectCallViaRest error: $e');
    }
  }
}
