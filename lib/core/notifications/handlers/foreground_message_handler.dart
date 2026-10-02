import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/notifications/dispatchers/call_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/chat_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/group_call_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/social_notification_dispatcher.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';

class ForegroundMessageHandler {
  void listen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final currentUserId = SupabaseProvider.idOrNull;
      if (currentUserId == null) return;

      final receiverId = message.data['receiverId'] as String?;
      if (receiverId != null &&
          receiverId.isNotEmpty &&
          receiverId != currentUserId) {
        debugPrint(
          '🛑 Notification ignored: intended for $receiverId but active session is $currentUserId',
        );
        return;
      }

      final senderId = message.data['senderId'] as String?;
      if (senderId != null && senderId == currentUserId) {
        return;
      }

      // Call pushes carry the initiator as `callerId` (not `senderId`). Without
      // this check the person who STARTED a call could receive their own
      // "incoming call" echo.
      final callerId = message.data['callerId'] as String?;
      if (callerId != null && callerId == currentUserId) {
        return;
      }

      final type = message.data['notificationType'] as String? ?? 'chat';

      if (type == 'incoming_group_call') {
        await GroupCallDispatcher.instance.handleIncomingGroupCallData(
          message.data,
        );
        return;
      }

      if (type == 'incoming_call') {
        await CallNotificationDispatcher.instance.handleIncomingCallData(
          message.data,
        );
        return;
      }

      if (type == 'group_call_cancelled') {
        final callId = message.data['callId'] as String?;
        if (callId != null && callId.isNotEmpty) {
          await GroupCallDispatcher.instance
              .cancelIncomingGroupCallNotification(callId);
        }
        return;
      }

      if (type == 'call_cancelled') {
        final callId = message.data['callId'] as String?;
        if (callId != null && callId.isNotEmpty) {
          await CallNotificationDispatcher.instance.cancelCallNotification(
            callId,
          );
        }
        return;
      }

      if (!SettingsRepository.instance.pushNotifications) return;

      if (type == 'chat') {
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
