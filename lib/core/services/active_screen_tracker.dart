import 'package:social_media_app/core/router/app_routes.dart';

class ActiveScreenTracker {
  static String? _currentRoute;
  static String? _activeChatReceiverId;
  static String? _activeGroupId;

  static void setCurrentRoute(String route) => _currentRoute = route;

  static void setActiveChatReceiver(String? receiverId) =>
      _activeChatReceiverId = receiverId;

  static void setActiveGroupId(String? groupId) => _activeGroupId = groupId;

  static bool isViewingChatWith(String senderId) {
    return _currentRoute == AppRoutes.chatDetailsViewRoute &&
        _activeChatReceiverId == senderId;
  }

  static bool isViewingGroup(String groupId) {
    return _activeGroupId == groupId;
  }
}
