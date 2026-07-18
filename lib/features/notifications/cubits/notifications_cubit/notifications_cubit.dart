import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/cubits/home_cubit/home_cubit.dart';
import '../../../social_graph/services/follow_services.dart';
import '../../../social_graph/services/friendship_services.dart';
import '../../models/app_notification_model.dart';
import '../../repository/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final FriendshipServices _friendshipServices;
  final FollowServices _followServices;
  final HomeCubit _homeCubit;

  NotificationsCubit({
    required FriendshipServices friendshipServices,
    required FollowServices followServices,
    required HomeCubit homeCubit,
  }) : _friendshipServices = friendshipServices,
       _followServices = followServices,
       _homeCubit = homeCubit,
       super(NotificationsState.initial()) {
    loadNotifications();
  }

  final _repository = NotificationRepository.instance;

  Future<void> loadNotifications() async {
    try {
      final notifications = await _repository.fetchNotifications();

      final followerIds =
          notifications
              .where(
                (n) => n.type == NotificationType.follow && n.senderId != null,
              )
              .map((n) => n.senderId!)
              .toSet();

      final alreadyFollowing = await _followServices.getFollowingSubset(
        followerIds.toList(),
      );

      emit(
        state.copyWith(
          notifications: notifications,
          isLoading: false,
          followingBackIds: alreadyFollowing,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void setFilter(NotificationType? type) {
    emit(state.copyWith(activeFilter: type, clearFilter: type == null));
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    final updated =
        state.notifications
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    final updated = state.notifications.where((n) => n.id != id).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> acceptFriendRequest(AppNotification notif) async {
    if (notif.referenceId == null) return;
    try {
      await _friendshipServices.acceptFriendRequest(notif.referenceId!);

      final me = _homeCubit.currentUserData;
      if (me != null && notif.senderId != null) {
        await NotificationRepository.instance.notifyFriendAccept(
          receiverId: notif.senderId!,
          accepterId: me.id,
          accepterName: me.name,
          accepterImageUrl: me.imageUrl ?? '',
        );
      }
      await deleteNotification(notif.id);
    } catch (e) {
      debugPrint('acceptFriendRequest error: $e');
    }
  }

  Future<void> rejectFriendRequest(AppNotification notif) async {
    if (notif.referenceId == null) return;
    try {
      await _friendshipServices.rejectFriendRequest(notif.referenceId!);
      await deleteNotification(notif.id);
    } catch (e) {
      debugPrint('rejectFriendRequest error: $e');
    }
  }

  Future<void> followBack(AppNotification notif) async {
    if (notif.senderId == null) return;
    final userId = notif.senderId!;
    final updated = Set<String>.from(state.followingBackIds)..add(userId);
    emit(state.copyWith(followingBackIds: updated));
    try {
      await _followServices.followUser(userId);
      final me = _homeCubit.currentUserData;
      if (me != null) {
        await NotificationRepository.instance.notifyFollow(
          receiverId: userId,
          followerId: me.id,
          followerName: me.name,
          followerImageUrl: me.imageUrl ?? '',
        );
      }
    } catch (e) {
      final reverted = Set<String>.from(state.followingBackIds)..remove(userId);
      emit(state.copyWith(followingBackIds: reverted));
      debugPrint('followBack error: $e');
    }
  }
}
