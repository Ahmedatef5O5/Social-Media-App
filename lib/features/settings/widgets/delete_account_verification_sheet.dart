import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';

/// Result of the final security gate shown before an account is deleted.

class DeleteAccountVerification {
  final String? password;
  const DeleteAccountVerification({this.password});
}

abstract final class DeleteAccountVerificationSheet {
  static const String confirmationWord = 'DELETE';

  /// `true` when the current account can sign in with an email + password
  /// identity and therefore must re-enter its password.
  static bool get requiresPassword {
    final user = SupabaseProvider.user;
    if (user == null) return false;

    final identities = user.identities;
    if (identities != null && identities.isNotEmpty) {
      return identities.any((identity) => identity.provider == 'email');
    }
    return user.appMetadata['provider'] == 'email';
  }

  /// Returns `null` when the user dismisses the sheet.
  static Future<DeleteAccountVerification?> show(BuildContext context) {
    return showModalBottomSheet<DeleteAccountVerification>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => _DeleteAccountVerificationBody(
            requiresPassword: requiresPassword,
          ),
    );
  }
}

class _DeleteAccountVerificationBody extends StatefulWidget {
  final bool requiresPassword;
  const _DeleteAccountVerificationBody({required this.requiresPassword});

  @override
  State<_DeleteAccountVerificationBody> createState() =>
      _DeleteAccountVerificationBodyState();
}

class _DeleteAccountVerificationBodyState
    extends State<_DeleteAccountVerificationBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValid(String text) {
    if (widget.requiresPassword) return text.isNotEmpty;
    return text.trim() == DeleteAccountVerificationSheet.confirmationWord;
  }

  void _submit() {
    if (!_isValid(_controller.text)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context, rootNavigator: true).pop(
      DeleteAccountVerification(
        password: widget.requiresPassword ? _controller.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final red = Colors.red.shade500;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(20),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: red.withValues(alpha: isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever_rounded, color: red, size: 28),
            ),
          ),
          const Gap(16),
          Text(
            widget.requiresPassword
                ? 'Confirm your password'
                : 'One last confirmation',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Text(
            'Your profile will be anonymized as "Deleted Account" and you '
            'will be signed out on all devices. Your posts, comments and '
            'messages stay visible to others under that name. This cannot '
            'be undone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const Gap(20),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final canSubmit = _isValid(value.text);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextFormField(
                    controller: _controller,
                    isPassword: widget.requiresPassword,
                    headerText:
                        widget.requiresPassword
                            ? 'Current password'
                            : 'Type ${DeleteAccountVerificationSheet.confirmationWord} to confirm',
                    hintText:
                        widget.requiresPassword
                            ? 'Enter your password'
                            : DeleteAccountVerificationSheet.confirmationWord,
                    keyboardType:
                        widget.requiresPassword
                            ? TextInputType.visiblePassword
                            : TextInputType.text,
                    inputFormatters:
                        widget.requiresPassword
                            ? null
                            : [
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) => newValue.copyWith(
                                  text: newValue.text.toUpperCase(),
                                ),
                              ),
                            ],
                  ),
                  const Gap(20),
                  CustomElevatedButton(
                    txtBtn: 'Delete My Account',
                    bgColor: red,
                    txtColor: Colors.white,
                    onPressed: canSubmit ? _submit : null,
                  ),
                ],
              );
            },
          ),
          const Gap(8),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              'Cancel',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
