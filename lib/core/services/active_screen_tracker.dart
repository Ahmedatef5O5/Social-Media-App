import 'package:social_media_app/core/router/app_routes.dart';

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
