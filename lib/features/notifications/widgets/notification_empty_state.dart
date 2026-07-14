import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../models/app_notification_model.dart';

class NotificationsEmptyState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final NotificationType? activeFilter;

  const NotificationsEmptyState({
    super.key,
    required this.isDark,
    required this.primary,
    required this.activeFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyFindingsThemedAnimation(
            animationPath: AppImages.emptyFindingsLot,
            width: 340,
            height: 280,
          ),
          const SizedBox(height: 20),
          Text(
            activeFilter == null
                ? 'No notifications yet'
                : 'No ${activeFilter!.name} notifications',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
