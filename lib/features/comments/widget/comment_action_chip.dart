import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class CommentActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isActive;
  final Color? activeColor;

  const CommentActionChip({
    super.key,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive
            ? (activeColor ?? Theme.of(context).primaryColor)
            : AppColors.grey6;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
