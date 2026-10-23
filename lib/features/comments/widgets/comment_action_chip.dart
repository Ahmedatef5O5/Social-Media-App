import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/design/tokens/typography.dart';

class CommentActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isActive;
  final Color? activeColor;
  final bool? isEmoji;

  const CommentActionChip({
    super.key,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.isActive = false,
    this.activeColor,
    this.isEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsEmoji =
        isEmoji ??
        (isActive &&
            label.isNotEmpty &&
            label != 'Like' &&
            label != 'Reply' &&
            label != 'إعجاب' &&
            label != 'رد');

    if (effectiveIsEmoji) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            fontFamilyFallback: AppTypography.emojiFontFallback,
          ),
        ),
      );
    }

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
