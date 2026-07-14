import 'package:flutter/material.dart';

class NotificationsHeader extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final int unreadCount;
  final VoidCallback onMarkAllRead;

  const NotificationsHeader({
    super.key,
    required this.isDark,
    required this.primary,
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: onMarkAllRead,
              icon: Icon(Icons.done_all_rounded, size: 16, color: primary),
              label: Text(
                'Mark all read',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
        ],
      ),
    );
  }
}
