import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';

class TwoFactorIntroStep extends StatelessWidget {
  final VoidCallback onContinue;
  const TwoFactorIntroStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget point(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.lock_shield_fill,
              size: 48,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          context.l10n.protectYourAccount,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.evenIfSomeoneLearns,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        point(
          CupertinoIcons.device_phone_portrait,
          context.l10n.twoFactorStep1Title,
          context.l10n.twoFactorStep1Desc,
        ),
        point(
          CupertinoIcons.qrcode,
          context.l10n.twoFactorStep2Title,
          context.l10n.twoFactorStep2Desc,
        ),
        point(
          CupertinoIcons.doc_on_clipboard,
          context.l10n.twoFactorStep3Title,
          context.l10n.twoFactorStep3Desc,
        ),
        const SizedBox(height: 16),
        CustomElevatedButton(
          txtBtn: context.l10n.continueLabel,
          onPressed: onContinue,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
