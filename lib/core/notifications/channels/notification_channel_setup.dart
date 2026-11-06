import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannelSetup {
  static final AndroidNotificationChannel messageChannel =
      AndroidNotificationChannel(
        'chat_messages_channel',
        'Chat Messages',
        importance: Importance.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('message_tone'),
        enableVibration: true,
      );

  static final AndroidNotificationChannel callChannel =
      AndroidNotificationChannel(
        'incoming_call_channel_v2',
        'Incoming Calls',
        description: 'Incoming call alerts',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('incoming_ring'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

  static final AndroidNotificationChannel socialChannel =
      AndroidNotificationChannel(
        'social_events_channel',
        'Social & Post Activity',
        description:
            'Friend requests, follows, reactions, comments, mentions, '
            'shares, saves and story reactions',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// Marketing / announcement pushes from the admin Notification Control
  /// Center. The id MUST match `ANDROID_CHANNEL_ID` in the dispatch-campaign
  /// Edge Function, or Android falls back to the default channel.
  static final AndroidNotificationChannel campaignChannel =
      AndroidNotificationChannel(
        'campaigns',
        'Announcements & Updates',
        description:
            'News, announcements and updates from the Social Mate team',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  Future<void> createAllChannels(
    FlutterLocalNotificationsPlugin localNotifications,
  ) async {
    final androidPlugin =
        localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(messageChannel);
    await androidPlugin?.createNotificationChannel(callChannel);
    await androidPlugin?.createNotificationChannel(socialChannel);
    await androidPlugin?.createNotificationChannel(campaignChannel);
  }

  Future<void> requestPermissions(
    FlutterLocalNotificationsPlugin localNotifications,
    FirebaseMessaging fcm,
  ) async {
    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
  }
}
