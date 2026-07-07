import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class CustomIconBtnWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double? size;
  final double? radius;
  final EdgeInsetsGeometry? padding;

  const CustomIconBtnWidget({
    super.key,
    required this.icon,
    required this.onTap,
    this.size,
    this.radius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: AppColors.transparent,
      borderRadius: BorderRadius.circular(radius ?? 12),
      onTap: onTap,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.85),
          size: size ?? 26,
        ),
      ),
    );
  }
}
