import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';
import 'package:social_media_app/core/design/tokens/radii.dart';
import 'package:social_media_app/core/design/tokens/spacing.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool isSmall;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final height =
        isSmall ? AppDimensions.chipHeight : AppDimensions.filterPillHeight;

    final bgColor = isSelected ? palette.primary : Colors.transparent;
    final textColor = isSelected ? palette.onPrimary : palette.onSurfaceVariant;
    final border =
        isSelected
            ? Border.all(color: Colors.transparent, width: 0)
            : Border.all(
              color: palette.outline,
              width: AppDimensions.borderWidthDefault,
            );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.radiusFull,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadii.radiusFull,
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppSpacing.space3),
              ],
              Text(
                label,
                style: context.typography.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
