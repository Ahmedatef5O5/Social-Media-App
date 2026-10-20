import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../models/two_factor_enrollment.dart';
import '../utils/clipboard_guard.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class TwoFactorQrStep extends StatelessWidget {
  final TwoFactorEnrollment enrollment;
  final VoidCallback onNext;
  const TwoFactorQrStep({
    super.key,
    required this.enrollment,
    required this.onNext,
  });

  Future<void> _openAuthenticator() async {
    final uri = Uri.tryParse(enrollment.otpauthUri);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      AppToast.info(AppL10n.current.noAuthenticatorAppFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Group the secret in blocks of four so it is easy to read and type.
    final grouped = RegExp(
      r'.{1,4}',
    ).allMatches(enrollment.secret).map((m) => m.group(0)).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.scanThisQrCode,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.openYourAuthenticatorApp,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 20),
        Center(
          // Always white: scanners need dark-on-light, also in dark mode.
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: SvgPicture.string(enrollment.qrSvg, width: 210, height: 210),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          context.l10n.cantScanEnterThis,
          style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  grouped,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: context.ls(1),
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.copySecret,
                icon: const Icon(CupertinoIcons.doc_on_doc, size: 20),
                onPressed: () async {
                  await ClipboardGuard.copySensitive(enrollment.secret);
                  AppToast.success(context.l10n.secretCopiedItWill);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _openAuthenticator,
          icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 18),
          label: Text(context.l10n.openInAuthenticatorApp),
        ),
        const SizedBox(height: 14),
        CustomElevatedButton(txtBtn: "I've added it", onPressed: onNext),
      ],
    );
  }
}
