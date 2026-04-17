import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/notification_services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ActiveScreenTracker {
  static String? _currentRoute;
  static String? _activeChatReceiverId;

  static void setCurrentRoute(String route) => _currentRoute = route;
  static void setActiveChatReceiver(String? receiverId) =>
      _activeChatReceiverId = receiverId;

  static bool isViewingChatWith(String senderId) {
    return _currentRoute == AppRoutes.chatDetailsViewRoute &&
        _activeChatReceiverId == senderId;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.initialize(isBackground: true);
  await NotificationService.instance.showNotificationFromMessage(message);
}
