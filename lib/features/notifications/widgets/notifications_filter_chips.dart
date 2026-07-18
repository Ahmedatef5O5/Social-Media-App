import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_notification_model.dart';

class NotificationsFilterChips extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final NotificationType? activeFilter;
  final ValueChanged<NotificationType?> onFilterSelected;

  const NotificationsFilterChips({
    super.key,
    required this.isDark,
    required this.primary,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (null, 'All', Icons.notifications_rounded),
      (NotificationType.chat, 'Messages', Icons.chat_bubble_outline_rounded),
      (NotificationType.call, 'Calls', Icons.call_rounded),
      (NotificationType.like, 'Likes', Icons.favorite_border_rounded),
      (NotificationType.comment, 'Comments', Icons.comment_outlined),
      (NotificationType.follow, 'Follows', Icons.person_add_outlined),
      (
        NotificationType.friendRequest,
        'Friend Requests',
        Icons.person_add_alt_1_rounded,
      ),
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final (type, label, icon) = filters[i];
          final isActive = activeFilter == type;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onFilterSelected(type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border:
                    isActive
                        ? null
                        : Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade200,
                          width: 0.8,
                        ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color:
                        isActive
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color:
                          isActive
                              ? Colors.white
                              : (isDark
                                  ? Colors.white60
                                  : Colors.grey.shade700),
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
