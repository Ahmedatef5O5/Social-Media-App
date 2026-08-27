import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';
import 'package:social_media_app/core/design/tokens/radii.dart';
import 'package:social_media_app/core/design/tokens/shadows.dart';
import 'package:social_media_app/core/design/tokens/spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool hasElevation;
  final Color? customColor;
  final BoxBorder? customBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.borderRadius,
    this.hasElevation = false,
    this.customColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = borderRadius ?? AppRadii.radiusLg;

    final border =
        customBorder ??
        Border.all(
          color: palette.outline,
          width: AppDimensions.borderWidthDefault,
        );

    final shadows =
        hasElevation
            ? AppShadows.getLevel1(isDark: palette.isDark)
            : AppShadows.level0;

    return Container(
      decoration: BoxDecoration(
        color: customColor ?? palette.surface,
        borderRadius: radius,
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
