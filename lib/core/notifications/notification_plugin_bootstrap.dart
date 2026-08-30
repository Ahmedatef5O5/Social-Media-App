import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/notifications/channels/notification_channel_setup.dart';

class NotificationPluginBootstrap {
  NotificationPluginBootstrap._();

  static bool _initialized = false;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final NotificationChannelSetup _channelSetup =
      NotificationChannelSetup();

  static Future<void> ensureInitialized({
    required void Function(NotificationResponse) onForegroundTap,
    required void Function(NotificationResponse) onBackgroundTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onForegroundTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundTap,
    );

    await _channelSetup.createAllChannels(_plugin);
  }

  static Future<void> requestPermissions() async {
    await _channelSetup.requestPermissions(_plugin, FirebaseMessaging.instance);
  }
}
