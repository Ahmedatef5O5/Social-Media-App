import 'dart:typed_data';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/services/notification_services.dart';
import 'package:social_media_app/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final type = message.data['notificationType'] as String? ?? 'chat';

  if (type == 'incoming_call') {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    await plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveBackgroundNotificationResponse: _bgNotificationTapped,
    );

    final androidPlugin =
        plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final callChannel = AndroidNotificationChannel(
      'incoming_call_channel',
      'Incoming Calls',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('incoming_ring'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );
    await androidPlugin?.createNotificationChannel(callChannel);

    final callId = message.data['callId'] ?? '';
    final callerId = message.data['callerId'] ?? '';
    final callerName = message.data['callerName'] ?? 'Unknown';
    final callerAvatar = message.data['callerAvatar'] ?? '';
    final callType = message.data['callType'] ?? 'audio';
    final subtitle =
        callType == 'video' ? 'Incoming video call' : 'Incoming voice call';

    Uint8List? avatarBytes;
    if (callerAvatar.isNotEmpty && callerAvatar.startsWith('http')) {
      try {
        final response = await dio_pkg.Dio().get<List<int>>(
          callerAvatar,
          options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
        );
        if (response.data != null) {
          avatarBytes = Uint8List.fromList(response.data!);
        }
      } catch (_) {}
    }

    final androidDetails = AndroidNotificationDetails(
      'incoming_call_channel',
      'Incoming Calls',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      icon: '@drawable/ic_notification',
      largeIcon:
          avatarBytes != null ? ByteArrayAndroidBitmap(avatarBytes) : null,
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

    final supabaseUrl = message.data['supabaseUrl'] ?? '';
    final supabaseAnonKey = message.data['supabaseAnonKey'] ?? '';

    await plugin.show(
      callId.hashCode,
      callerName,
      subtitle,
      NotificationDetails(android: androidDetails),
      payload:
          'call|$callId|$callerId|$callerName|$callerAvatar|$callType|$supabaseUrl|$supabaseAnonKey',
    );
    return;
  }

  await NotificationService.instance.initialize(isBackground: true);

  if (type == 'incoming_group_call') {
    await NotificationService.instance.showIncomingGroupCallNotification(
      callId: message.data['callId'] ?? '',
      groupId: message.data['groupId'] ?? '',
      groupName: message.data['groupName'] ?? 'Group',
      groupAvatarUrl: message.data['groupAvatarUrl'] ?? '',
      callerName: message.data['callerName'] ?? 'Unknown',
      callType: message.data['callType'] ?? 'audio',
    );
    return;
  }

  if (NotificationService.isSocialType(type)) {
    await NotificationService.instance.showSocialNotificationFromMessage(
      message,
    );
    return;
  }

  await NotificationService.instance.showNotificationFromMessage(message);
}

@pragma('vm:entry-point')
void _bgNotificationTapped(NotificationResponse response) {
  final payload = response.payload ?? '';
  final actionId = response.actionId;

  if (payload.startsWith('call|') && actionId == 'decline_call') {
    final parts = payload.split('|');
    if (parts.length >= 8) {
      final callId = parts[1];
      final supabaseUrl = parts[6];
      final anonKey = parts[7];
      if (supabaseUrl.isNotEmpty && anonKey.isNotEmpty) {
        _rejectCallRest(callId, supabaseUrl, anonKey);
      }
    }
  }
}

Future<void> _rejectCallRest(
  String callId,
  String supabaseUrl,
  String anonKey,
) async {
  try {
    await dio_pkg.Dio().patch(
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
    debugPrint('Background call reject error: $e');
  }
}
