import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';
import 'package:social_media_app/core/design/tokens/radii.dart';
import 'package:social_media_app/core/design/tokens/spacing.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

enum AppButtonSize { standard, small }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.standard,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSmall = size == AppButtonSize.small;
    final height =
        isSmall ? AppDimensions.buttonHeightSmall : AppDimensions.buttonHeight;
    final radius = isSmall ? AppRadii.radiusSm : AppRadii.radiusMd;

    // Determine colors based on variant
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = palette.primary;
        textColor = palette.onPrimary;
        break;
      case AppButtonVariant.secondary:
        bgColor = Colors.transparent;
        textColor = palette.primary;
        borderSide = BorderSide(
          color: palette.primary,
          width: AppDimensions.borderWidthDefault,
        );
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = palette.onSurfaceVariant;
        break;
      case AppButtonVariant.destructive:
        bgColor = palette.error;
        textColor = Colors.white;
        break;
    }

    final effectiveOnPressed = isLoading ? null : onPressed;
    final textStyle =
        isSmall
            ? context.typography.titleSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            )
            : context.typography.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            );

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          prefixIcon!,
          const SizedBox(width: AppSpacing.space4),
        ],
        Text(text, style: textStyle),
        if (suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.space4),
          suffixIcon!,
        ],
      ],
    );

    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CustomLoadingIndicator(color: textColor, radius: 9),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: Material(
        color: effectiveOnPressed != null ? bgColor : palette.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: effectiveOnPressed != null ? borderSide : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: effectiveOnPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
