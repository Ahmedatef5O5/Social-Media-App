import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/notifications_cubit/notifications_cubit.dart';
import '../cubits/notifications_cubit/notifications_state.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_list_item.dart';
import '../widgets/notification_shimmer_list.dart';
import '../widgets/notifications_filter_chips.dart';
import '../widgets/notifications_header.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return BlocProvider(
      create: (_) => NotificationsCubit(),
      child: BlocConsumer<NotificationsCubit, NotificationsState>(
        listenWhen:
            (previous, current) => previous.isLoading && !current.isLoading,
        listener: (context, state) => _animController.forward(),
        builder: (context, state) {
          final cubit = context.read<NotificationsCubit>();
          final filtered = state.filtered;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  NotificationsHeader(
                    isDark: isDark,
                    primary: primary,
                    unreadCount: state.unreadCount,
                    onMarkAllRead: () {
                      HapticFeedback.lightImpact();
                      cubit.markAllAsRead();
                    },
                  ),
                  NotificationsFilterChips(
                    isDark: isDark,
                    primary: primary,
                    activeFilter: state.activeFilter,
                    onFilterSelected: cubit.setFilter,
                  ),
                  Expanded(
                    child:
                        state.isLoading
                            ? NotificationsShimmerList(isDark: isDark)
                            : filtered.isEmpty
                            ? NotificationsEmptyState(
                              isDark: isDark,
                              primary: primary,
                              activeFilter: state.activeFilter,
                            )
                            : RefreshIndicator(
                              onRefresh: cubit.loadNotifications,
                              color: primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 100,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  return NotificationListItem(
                                    notification: filtered[i],
                                    isDark: isDark,
                                    primary: primary,
                                    index: i,
                                    onMarkAsRead: cubit.markAsRead,
                                    onDelete: cubit.deleteNotification,
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
