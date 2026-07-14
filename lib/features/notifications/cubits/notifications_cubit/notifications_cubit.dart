import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/app_notification_model.dart';
import '../../repository/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsState.initial()) {
    loadNotifications();
  }

  final _repository = NotificationRepository.instance;

  Future<void> loadNotifications() async {
    try {
      final notifications = await _repository.fetchNotifications();
      emit(state.copyWith(notifications: notifications, isLoading: false));
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
}
