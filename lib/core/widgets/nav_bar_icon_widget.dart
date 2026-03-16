import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class NavBarIcon extends StatelessWidget {
  const NavBarIcon({super.key, this.icon, required this.isActive, this.child});
  final Widget? child;
  final IconData? icon;
  final bool isActive;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isActive
                ? Colors.blue.withValues(alpha: .175)
                : AppColors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          child ??
          Icon(
            icon,
            color: isActive ? Theme.of(context).primaryColor : AppColors.grey,
          ),
    );
  }
}
