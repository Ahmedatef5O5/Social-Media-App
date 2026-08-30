import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/notifications/channels/notification_channel_setup.dart';
import 'package:social_media_app/core/notifications/helpers/notification_avatar_builder.dart';
import 'package:social_media_app/core/notifications/helpers/notification_id_helper.dart';

class SocialNotificationDispatcher {
  SocialNotificationDispatcher._();
  static final SocialNotificationDispatcher instance =
      SocialNotificationDispatcher._();

  final NotificationAvatarBuilder _avatarBuilder = NotificationAvatarBuilder();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const Set<String> _socialNotificationTypes = {
    'friend_request',
    'friend_accept',
    'follow',
    'post_react',
    'post_comment',
    'post_reshare',
    'post_save',
    'mention',
    'comment_reply',
    'comment_react',
    'story_react',
    'message_react',
  };

  static bool isSocialType(String type) =>
      _socialNotificationTypes.contains(type);

  static String resolveSocialReferenceId(Map<String, dynamic> data) {
    final postId = data['postId'] as String?;
    if (postId != null && postId.isNotEmpty) return postId;
    final storyId = data['storyId'] as String?;
    if (storyId != null && storyId.isNotEmpty) return storyId;
    return '';
  }

  Future<void> showSocialNotificationFromMessage(RemoteMessage message) async {
    final data = message.data;
    final String type = data['notificationType'] ?? 'general';

    final String actorId =
        data['actorId'] ?? data['requesterId'] ?? data['followerId'] ?? '';
    final String actorName =
        data['actorName'] ??
        data['requesterName'] ??
        data['followerName'] ??
        'Someone';
    final String actorImageUrl =
        data['actorImageUrl'] ??
        data['requesterImageUrl'] ??
        data['followerImageUrl'] ??
        '';
    final String referenceId = resolveSocialReferenceId(data);

    final String title =
        (data['title'] as String?)?.isNotEmpty == true
            ? data['title']!
            : actorName;
    final String body =
        (data['body'] as String?)?.isNotEmpty == true
            ? data['body']!
            : 'New notification';

    Uint8List avatarBitmap;
    try {
      avatarBitmap = await _avatarBuilder.getAvatarBitmap(actorImageUrl);
    } catch (_) {
      avatarBitmap = await _avatarBuilder.defaultBitmap();
    }

    final androidDetails = AndroidNotificationDetails(
      NotificationChannelSetup.socialChannel.id,
      NotificationChannelSetup.socialChannel.name,
      channelDescription: NotificationChannelSetup.socialChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(avatarBitmap),
      styleInformation: BigTextStyleInformation(body),
      autoCancel: true,
      color: const Color(0xFF2196F3),
    );

    final String mentionContext = data['context'] ?? '';

    await _localNotifications.show(
      createNotificationId('$type|$referenceId|$actorId'),
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload:
          type == 'message_react'
              ? 'message_react|${data['isGroup']}|${data['groupId']}|${data['groupName']}|${data['actorId']}|${data['actorName']}|${data['actorImageUrl']}'
              : 'social|$type|$referenceId|$actorId|$actorName|$actorImageUrl|$mentionContext',
    );
  }
}
