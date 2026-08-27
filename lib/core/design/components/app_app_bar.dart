import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';
import 'package:social_media_app/core/design/tokens/spacing.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final double? titleSpacing;

  const AppAppBar({
    super.key,
    this.titleText,
    this.titleWidget,
    this.showBackButton = true,
    this.onBackTap,
    this.actions,
    this.centerTitle = false,
    this.leading,
    this.titleSpacing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canPop = Navigator.of(context).canPop();

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showBackButton && canPop) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: palette.onSurface,
        onPressed: onBackTap ?? () => Navigator.of(context).pop(),
      );
    }

    return AppBar(
      centerTitle: centerTitle,
      titleSpacing:
          titleSpacing ?? (effectiveLeading != null ? 0 : AppSpacing.space7),
      leading: effectiveLeading,
      title:
          titleWidget ??
          (titleText != null
              ? Text(
                titleText!,
                style: context.typography.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.onSurface,
                ),
              )
              : null),
      actions:
          actions != null
              ? [...actions!, const SizedBox(width: AppSpacing.space4)]
              : null,
    );
  }
}
