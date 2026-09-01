import 'dart:async';
import 'package:social_media_app/core/router/app_routes.dart';

class ActiveScreenTracker {
  static String? _currentRoute;
  static String? _activeChatReceiverId;
  static String? _activeGroupId;

  static String? get currentRoute => _currentRoute;

  static void setCurrentRoute(String route) => _currentRoute = route;

  static void setActiveChatReceiver(String? receiverId) =>
      _activeChatReceiverId = receiverId;

  static void setActiveGroupId(String? groupId) {
    _activeGroupId = groupId;
    if (groupId != null && _pendingGroupId == groupId) {
      _clearPendingGroupNavigation();
    }
  }

  static bool isViewingChatWith(String senderId) {
    return _currentRoute == AppRoutes.chatDetailsViewRoute &&
        _activeChatReceiverId == senderId;
  }

  static bool isViewingGroup(String groupId) {
    return _activeGroupId == groupId;
  }

  // --- Group navigation guard -----------------------------------------
  static String? _pendingGroupId;
  static Timer? _pendingGroupTimer;

  static bool claimGroupNavigation(String groupId) {
    if (isViewingGroup(groupId)) return false;
    if (_pendingGroupId == groupId) return false;

    _pendingGroupId = groupId;
    _pendingGroupTimer?.cancel();
    _pendingGroupTimer = Timer(
      const Duration(seconds: 2),
      _clearPendingGroupNavigation,
    );
    return true;
  }

  static void _clearPendingGroupNavigation() {
    _pendingGroupTimer?.cancel();
    _pendingGroupTimer = null;
    _pendingGroupId = null;
  }
}
