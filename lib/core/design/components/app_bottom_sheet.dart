import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';
import 'package:social_media_app/core/design/tokens/radii.dart';
import 'package:social_media_app/core/design/tokens/spacing.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
  });

  /// Static helper to present standard modal bottom sheets
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceElevated : palette.surface,
        borderRadius: AppRadii.bottomSheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.bottomSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                Center(
                  child: Container(
                    width: AppDimensions.bottomSheetHandleWidth,
                    height: AppDimensions.bottomSheetHandleHeight,
                    decoration: BoxDecoration(
                      color: palette.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: AppRadii.radiusXs,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
              ],
              if (title != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title!,
                    style: context.typography.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
