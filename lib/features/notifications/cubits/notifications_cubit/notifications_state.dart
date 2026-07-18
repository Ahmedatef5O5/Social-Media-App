import '../../models/app_notification_model.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final NotificationType? activeFilter;
  final Set<String> followingBackIds;

  const NotificationsState({
    required this.notifications,
    required this.isLoading,
    this.activeFilter,
    this.followingBackIds = const {},
  });

  factory NotificationsState.initial() =>
      const NotificationsState(notifications: [], isLoading: true);

  List<AppNotification> get filtered {
    if (activeFilter == null) return notifications;
    return notifications.where((n) => n.type == activeFilter).toList();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    NotificationType? activeFilter,
    bool clearFilter = false,
    Set<String>? followingBackIds,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      followingBackIds: followingBackIds ?? this.followingBackIds,
    );
  }
}
