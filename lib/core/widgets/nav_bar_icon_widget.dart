import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconBody,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              // color: Colors.green,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Center(
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
