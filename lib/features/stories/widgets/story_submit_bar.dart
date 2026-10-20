import 'package:flutter/material.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../../core/themes/app_colors.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class StorySubmitBar extends StatelessWidget {
  final bool hasText;
  final bool loading;
  final VoidCallback onPressed;

  const StorySubmitBar({
    super.key,
    required this.hasText,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: loading ? null : onPressed,
      child:
          loading
              ? const CustomLoadingIndicator(radius: 10, color: AppColors.white)
              : Text(
                context.l10n.done,
                style: TextStyle(
                  color:
                      hasText
                          ? AppColors.white
                          : AppColors.grey2.withValues(alpha: 0.6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }
}
