import 'package:flutter/material.dart';
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
    // A new error means the last code was rejected: clear for the next try.
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
          'Enter the 6-digit code',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Type the code your authenticator app shows for Social Mate to '
          'confirm it is linked.',
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
            child: const Text('Paste code'),
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
            'Still not working? Make sure your phone’s date and time are set '
            'to automatic in your device settings.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
        const SizedBox(height: 24),
        CustomElevatedButton(
          txtBtn: 'Verify',
          isLoading: widget.verifying,
          onPressed: () => widget.onSubmit(_code),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: widget.verifying ? null : widget.onBack,
            child: const Text('Back to QR code'),
          ),
        ),
      ],
    );
  }
}
