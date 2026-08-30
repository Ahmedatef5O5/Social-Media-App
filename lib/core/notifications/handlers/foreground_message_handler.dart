import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:social_media_app/core/notifications/dispatchers/call_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/chat_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/group_call_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/social_notification_dispatcher.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';

class ForegroundMessageHandler {
  void listen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final type = message.data['notificationType'] as String? ?? 'chat';

      if (type == 'incoming_group_call') {
        if (!SettingsRepository.instance.callNotifications) return;
        await GroupCallDispatcher.instance.handleIncomingGroupCallData(
          message.data,
        );
        return;
      }

      if (type == 'incoming_call') {
        if (!SettingsRepository.instance.callNotifications) return;
        await CallNotificationDispatcher.instance.handleIncomingCallData(
          message.data,
        );
        return;
      }

      if (!SettingsRepository.instance.pushNotifications) return;

      if (type == 'chat') {
        final senderId = message.data['senderId'] as String?;
        if (senderId != null &&
            !ActiveScreenTracker.isViewingChatWith(senderId)) {
          await ChatNotificationDispatcher.instance.showNotificationFromMessage(
            message,
          );
        }
        return;
      }

      if (type == 'group_message') {
        final groupId = message.data['groupId'] as String?;
        if (groupId != null && !ActiveScreenTracker.isViewingGroup(groupId)) {
          await ChatNotificationDispatcher.instance.showNotificationFromMessage(
            message,
          );
        }
        return;
      }

      if (type == 'message_react') {
        final isGroup = message.data['isGroup'] == 'true';

        if (isGroup) {
          final groupId = message.data['groupId'] as String?;
          if (groupId != null && ActiveScreenTracker.isViewingGroup(groupId)) {
            return;
          }
        } else {
          final actorId = message.data['actorId'] as String?;
          if (actorId != null &&
              ActiveScreenTracker.isViewingChatWith(actorId)) {
            return;
          }
        }
      }

      if (SocialNotificationDispatcher.isSocialType(type)) {
        await SocialNotificationDispatcher.instance
            .showSocialNotificationFromMessage(message);
        return;
      }

      await ChatNotificationDispatcher.instance.showNotificationFromMessage(
        message,
      );
    });
  }
}
