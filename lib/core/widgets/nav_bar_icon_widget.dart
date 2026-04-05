import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_badge.dart';

class NavBarIcon extends StatelessWidget {
  const NavBarIcon({
    super.key,
    this.icon,
    required this.isActive,
    this.child,
    this.badgeCount = 0,
  });
  final Widget? child;
  final IconData? icon;
  final bool isActive;
  final int badgeCount;
  @override
  Widget build(BuildContext context) {
    final Widget iconBody = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isActive
                ? Theme.of(context).primaryColor.withValues(alpha: .175)
                : AppColors.transparent,
        shape: BoxShape.circle,
      ),
      child:
          child ??
          Icon(
            icon,
            color:
                isActive
                    ? Theme.of(context).primaryColor
                    : AppColors.grey6.withValues(alpha: 0.8),
          ),
    );
    if (badgeCount <= 0) return iconBody;

    return CustomBadge(count: badgeCount, top: 0, right: 0, child: iconBody);
  }
}
