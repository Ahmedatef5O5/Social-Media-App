import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../../auth/data/models/account_auth_info.dart';
import '../cubits/two_factor_disable_cubit.dart';
import '../services/two_factor_service.dart';
import 'otp_code_field.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

/// Returns `true` when 2FA was turned off, `null` when dismissed.
Future<bool?> showTwoFactorDisableSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _DisableSheetBody(),
  );
}

class _DisableSheetBody extends StatelessWidget {
  const _DisableSheetBody();

  @override
  Widget build(BuildContext context) {
    final user = SupabaseProvider.user;
    final hasPassword =
        user != null && AccountAuthInfo.fromUser(user).hasPassword;
    return BlocProvider(
      create:
          (_) => TwoFactorDisableCubit(
            const TwoFactorService(),
            hasPassword: hasPassword,
          ),
      child: _DisableForm(canUsePassword: hasPassword),
    );
  }
}

class _DisableForm extends StatefulWidget {
  final bool canUsePassword;
  const _DisableForm({required this.canUsePassword});

  @override
  State<_DisableForm> createState() => _DisableFormState();
}

class _DisableFormState extends State<_DisableForm> {
  final TextEditingController _password = TextEditingController();
  final GlobalKey<OtpCodeFieldState> _otp = GlobalKey<OtpCodeFieldState>();
  String _code = '';

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<TwoFactorDisableCubit, TwoFactorDisableState>(
      listenWhen:
          (p, c) =>
              (!p.done && c.done) || (c.error != null && c.error != p.error),
      listener: (context, state) {
        if (state.done) {
          AppToast.success(context.l10n.twoFactorAuthenticationIs);
          Navigator.of(context).pop(true);
        } else if (state.method == TwoFactorDisableMethod.totp) {
          _otp.currentState?.clear();
          _code = '';
        }
      },
      builder: (context, state) {
        final cubit = context.read<TwoFactorDisableCubit>();
        final isPassword = state.method == TwoFactorDisableMethod.password;

        // Elegant, modern destructive red tokens
        const destructiveRed = Color(0xFFDC2626);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: destructiveRed.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_open_fill,
                          color: destructiveRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.turnOffTwoFactor,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.yourAccountWillBe,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isPassword)
                    CustomTextFormField(
                      controller: _password,
                      hintText: context.l10n.currentPassword2,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                    )
                  else
                    OtpCodeField(
                      key: _otp,
                      enabled: !state.submitting,
                      hasError: state.error != null,
                      onChanged: (v) => _code = v,
                      onCompleted: cubit.submitTotp,
                    ),
                  if (state.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: destructiveRed,
                      ),
                    ),
                  ],
                  if (widget.canUsePassword)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed:
                            state.submitting
                                ? null
                                : () => cubit.setMethod(
                                  isPassword
                                      ? TwoFactorDisableMethod.totp
                                      : TwoFactorDisableMethod.password,
                                ),
                        child: Text(
                          isPassword
                              ? context.l10n.useAnAuthenticatorCode
                              : context.l10n.useMyPasswordInstead,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomElevatedButton(
                    txtBtn: 'Turn off',
                    bgColor: destructiveRed,
                    isLoading: state.submitting,
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (isPassword) {
                        cubit.submitPassword(_password.text);
                      } else {
                        cubit.submitTotp(_code);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed:
                          state.submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
