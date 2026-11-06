import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/notifications/campaign/campaign_push_payload.dart';
import 'package:social_media_app/core/notifications/channels/notification_channel_setup.dart';
import 'package:social_media_app/core/notifications/helpers/notification_id_helper.dart';

/// Shows a campaign push while the app is in the FOREGROUND. FCM does not
/// display `notification` messages on its own in that state; in the
/// background / terminated state the OS shows them (so
/// `firebaseMessagingBackgroundHandler` deliberately ignores campaigns).
class CampaignNotificationDispatcher {
  CampaignNotificationDispatcher._();
  static final CampaignNotificationDispatcher instance =
      CampaignNotificationDispatcher._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> showFromMessage(RemoteMessage message) async {
    final payload = CampaignPushPayload.fromData(message.data);
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final channel = NotificationChannelSetup.campaignChannel;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        styleInformation: BigTextStyleInformation(body),
        autoCancel: true,
        color: const Color(0xFF2196F3),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      createNotificationId('campaign|${payload.campaignId ?? title}'),
      title,
      body,
      details,
      payload: payload.toLocalPayload(),
    );
  }
}
