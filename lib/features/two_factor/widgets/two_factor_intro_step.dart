import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 20),
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
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.lock_shield_fill,
              size: 42,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          context.l10n.protectYourAccount,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.evenIfSomeoneLearns,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 26),
        point(
          CupertinoIcons.device_phone_portrait,
          'Open your authenticator app',
          'Google Authenticator, Microsoft Authenticator, Authy or Apple '
              'Passwords all work.',
        ),
        point(
          CupertinoIcons.qrcode,
          'Scan a QR code',
          'Or type the secret key by hand if you are on the same phone.',
        ),
        point(
          CupertinoIcons.doc_on_clipboard,
          'Save your recovery codes',
          'They are the only way back in if you lose your phone.',
        ),
        const SizedBox(height: 10),
        CustomElevatedButton(txtBtn: 'Continue', onPressed: onContinue),
      ],
    );
  }
}
