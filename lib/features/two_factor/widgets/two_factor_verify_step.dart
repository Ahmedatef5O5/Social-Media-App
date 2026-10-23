import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import 'otp_code_field.dart';
import 'totp_window_indicator.dart';

class TwoFactorVerifyStep extends StatefulWidget {
  final bool verifying;
  final String? error;
  final bool showClockHint;
  final ValueChanged<String> onSubmit;
  final VoidCallback onBack;

  const TwoFactorVerifyStep({
    super.key,
    required this.verifying,
    required this.error,
    required this.showClockHint,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<TwoFactorVerifyStep> createState() => _TwoFactorVerifyStepState();
}

class _TwoFactorVerifyStepState extends State<TwoFactorVerifyStep> {
  final GlobalKey<OtpCodeFieldState> _otp = GlobalKey<OtpCodeFieldState>();
  String _code = '';

  @override
  void didUpdateWidget(covariant TwoFactorVerifyStep old) {
    super.didUpdateWidget(old);
    if (widget.error != null && widget.error != old.error) {
      _otp.currentState?.clear();
      _code = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.enterThe6Digit,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.typeTheCodeYour,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 26),
        OtpCodeField(
          key: _otp,
          enabled: !widget.verifying,
          hasError: widget.error != null,
          onChanged: (v) => _code = v,
          onCompleted: widget.onSubmit,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed:
                widget.verifying ? null : () => _otp.currentState?.paste(),
            child: Text(context.l10n.pasteCode),
          ),
        ),
        const SizedBox(height: 4),
        const Center(child: TotpWindowIndicator()),
        if (widget.error != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.redAccent,
            ),
          ),
        ],
        if (widget.showClockHint) ...[
          const SizedBox(height: 10),
          Text(
            context.l10n.stillNotWorkingMake,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
        const SizedBox(height: 24),
        CustomElevatedButton(
          txtBtn: context.l10n.verifyCode,
          isLoading: widget.verifying,
          onPressed: () => widget.onSubmit(_code),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: widget.verifying ? null : widget.onBack,
            child: Text(context.l10n.backToQrCode),
          ),
        ),
      ],
    );
  }
}
