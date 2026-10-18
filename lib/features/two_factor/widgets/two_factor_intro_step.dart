import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
          'Protect your account',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Even if someone learns your password, they cannot sign in without '
          'a code from your phone.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
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
        const SizedBox(height: 16),
        CustomElevatedButton(txtBtn: 'Continue', onPressed: onContinue),
        const SizedBox(height: 12),
      ],
    );
  }
}
