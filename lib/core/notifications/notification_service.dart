import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:social_media_app/core/notifications/dispatchers/call_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/chat_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/group_call_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/social_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/handlers/background_message_handler.dart';
import 'package:social_media_app/core/notifications/handlers/foreground_message_handler.dart';
import 'package:social_media_app/core/notifications/handlers/tap_action_handler.dart';
import 'package:social_media_app/core/notifications/helpers/notification_id_helper.dart';
import 'package:social_media_app/core/notifications/notification_plugin_bootstrap.dart';
export 'package:social_media_app/core/notifications/notification_navigator_key.dart';
export 'package:social_media_app/core/notifications/handlers/background_message_handler.dart'
    show
        ensureSupabaseReady,
        onBgNotificationActionTapped,
        handleBackgroundChatAction;
export 'package:social_media_app/core/notifications/dispatchers/social_notification_dispatcher.dart'
    show SocialNotificationDispatcher;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _listenersRegistered = false;

  Future<void> initialize({bool isBackground = false}) async {
    await NotificationPluginBootstrap.ensureInitialized(
      onForegroundTap: (response) async {
        final actionId = response.actionId;
        if (actionId == 'reply_action' ||
            actionId == 'mark_read_action' ||
            actionId == 'mute_action') {
          await handleBackgroundChatAction(response);
          return;
        }
        TapActionHandler.handleTap(response);
      },
      onBackgroundTap: onBgNotificationActionTapped,
    );

    if (!isBackground && !_listenersRegistered) {
      _listenersRegistered = true;
      await NotificationPluginBootstrap.requestPermissions();
      ForegroundMessageHandler().listen();
      TapActionHandler.instance.listenToNotificationOpenedApp();
      TapActionHandler.instance.handleTerminatedAppLaunch();
    }
  }

  Future<void> cancelNotificationsForSender(String senderId) =>
      ChatNotificationDispatcher.instance.cancelNotificationsForSender(
        senderId,
      );

  Future<void> cancelCallNotification(String callId) =>
      CallNotificationDispatcher.instance.cancelCallNotification(callId);

  Future<void> showIncomingCallNotification({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callType,
  }) => CallNotificationDispatcher.instance.showIncomingCallNotification(
    callId: callId,
    callerId: callerId,
    callerName: callerName,
    callerAvatar: callerAvatar,
    callType: callType,
  );

  Future<void> showIncomingGroupCallNotification({
    required String callId,
    required String groupId,
    required String groupName,
    required String groupAvatarUrl,
    required String callerName,
    required String callType,
  }) => GroupCallDispatcher.instance.showIncomingGroupCallNotification(
    callId: callId,
    groupId: groupId,
    groupName: groupName,
    groupAvatarUrl: groupAvatarUrl,
    callerName: callerName,
    callType: callType,
  );

  Future<void> showNotificationFromMessage(RemoteMessage message) =>
      ChatNotificationDispatcher.instance.showNotificationFromMessage(message);

  Future<void> showSocialNotificationFromMessage(RemoteMessage message) =>
      SocialNotificationDispatcher.instance.showSocialNotificationFromMessage(
        message,
      );

  static bool isSocialType(String type) =>
      SocialNotificationDispatcher.isSocialType(type);

  static int createUniqueId(String input) => createNotificationId(input);
}
