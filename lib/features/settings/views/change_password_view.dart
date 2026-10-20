import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utilities/app_formatters.dart';
import '../../../core/utilities/app_validators.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../../auth/data/models/account_auth_info.dart';
import '../../auth/widgets/password_strength_bar.dart';
import '../cubits/account_security_cubit.dart';
import '../utils/resend_cooldown.dart';
import '../widgets/settings_detail_sliver_app_bar.dart';
import '../widgets/settings_surface_card.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  // Server-side "wrong current password" is surfaced as a field error.
  String? _currentServerError;
  bool _success = false;

  final ResendCooldown _resetCooldown = ResendCooldown(
    storageKey: 'social_mate_change_pwd_reset_link_expiry',
  );

  late final String? _email;
  late final AccountAuthInfo? _info;

  @override
  void initState() {
    super.initState();
    final user = SupabaseProvider.user;
    _email = user?.email;
    _info = user == null ? null : AccountAuthInfo.fromUser(user);
    _resetCooldown.restore();
  }

  @override
  void dispose() {
    _resetCooldown.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── actions ─────────────────────────

  void _submit(bool needsCurrent) {
    _currentServerError = null;
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AccountSecurityCubit>().changePassword(
      currentPassword: needsCurrent ? _currentCtrl.text : null,
      newPassword: _newCtrl.text,
    );
  }

  Future<void> _confirmSendResetLink() async {
    final email = _email;
    if (email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(context.l10n.sendResetLink),
            content: Text(context.l10n.sendAPasswordReset(email)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.l10n.sendLink),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      context.read<AccountSecurityCubit>().sendPasswordResetLink();
    }
  }

  void _onCubitState(BuildContext context, AccountSecurityState state) {
    if (state is AccountSecuritySuccess) {
      switch (state.action) {
        case AccountAction.changePassword:
          AppToast.success(context.l10n.passwordChangedSuccessfully);
          setState(() => _success = true);
          Future<void>.delayed(const Duration(milliseconds: 600), () {
            if (mounted) Navigator.of(context).pop();
          });
        case AccountAction.sendResetLink:
          _resetCooldown.start();
          AppToast.success(context.l10n.resetLinkSentTo(_email ?? ''));
        default:
          break;
      }
    } else if (state is AccountSecurityFailure) {
      switch (state.action) {
        case AccountAction.changePassword:
          if (state.kind == AccountFailureKind.wrongCurrentPassword) {
            HapticFeedback.mediumImpact();
            setState(() => _currentServerError = state.message);
            _formKey.currentState?.validate();
          } else {
            AppToast.error(state.message);
          }
        case AccountAction.sendResetLink:
          if (state.kind == AccountFailureKind.rateLimited) {
            _resetCooldown.start(state.retryAfterSeconds ?? 60);
          }
          AppToast.error(state.message);
        default:
          AppToast.error(state.message);
      }
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _info;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SettingsDetailSliverAppBar(
              icon: CupertinoIcons.lock_fill,
              title: context.l10n.settingsChangePassword,
              subtitle: context.l10n.updateYourAccountPassword,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child:
                    info == null
                        ? Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(context.l10n.pleaseSignInAgain),
                          ),
                        )
                        : _buildForm(context, info),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AccountAuthInfo info) {
    final needsCurrent = info.hasPassword;

    return BlocConsumer<AccountSecurityCubit, AccountSecurityState>(
      listenWhen:
          (prev, curr) =>
              curr is AccountSecuritySuccess || curr is AccountSecurityFailure,
      listener: _onCubitState,
      builder: (context, state) {
        final busy = state is AccountSecurityBusy;
        final changing =
            state is AccountSecurityBusy &&
            state.action == AccountAction.changePassword;

        return PopScope(
          canPop: !busy,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.isOAuthOnly) ...[
                  SettingsInfoBanner(
                    icon: Icons.link_rounded,
                    title: context.l10n.linkedTo(info.oauthLabel),
                    message: context.l10n.yourAccountIsLinked(info.oauthLabel),
                  ),
                  const Gap(20),
                ],
                if (needsCurrent) ...[
                  CustomTextFormField(
                    controller: _currentCtrl,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    labelText: context.l10n.currentPassword,
                    hintText: context.l10n.enterYourCurrentPassword,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l10n.currentPasswordIsRequired;
                      }
                      return _currentServerError;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _resetCooldown.remaining,
                      builder: (context, secs, _) {
                        final disabled = secs > 0 || busy || _email == null;
                        return TextButton(
                          onPressed: disabled ? null : _confirmSendResetLink,
                          child: Text(
                            secs > 0
                                ? context.l10n.resetLinkSentResend(secs)
                                : context.l10n.forgotYourCurrentPassword,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(8),
                ],
                CustomTextFormField(
                  controller: _newCtrl,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  labelText: context.l10n.newPassword,
                  hintText: context.l10n.enterNewPassword,
                  isPassword: true,
                  inputFormatters: AppFormatters.noSpaces,
                  validator: (value) {
                    final base = AppValidators.validatePassword(value);
                    if (base != null) return base;
                    if (needsCurrent && value == _currentCtrl.text) {
                      return context.l10n.newPasswordMustBe;
                    }
                    return null;
                  },
                ),
                const Gap(8),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.6,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _newCtrl,
                      builder:
                          (context, value, _) =>
                              PasswordStrengthBar(password: value.text),
                    ),
                  ),
                ),
                const Gap(16),
                CustomTextFormField(
                  controller: _confirmCtrl,
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                  labelText: context.l10n.confirmNewPassword,
                  hintText: context.l10n.reEnterNewPassword,
                  isPassword: true,
                  inputFormatters: AppFormatters.noSpaces,
                  validator:
                      (value) => AppValidators.validateConfirmPassword(
                        value,
                        _newCtrl.text,
                      ),
                ),
                const Gap(24),
                SettingsInfoBanner(
                  icon: Icons.shield_outlined,
                  message: context.l10n.youWillStaySigned,
                ),
                const Gap(24),
                CustomElevatedButton(
                  txtBtn:
                      needsCurrent
                          ? context.l10n.updatePassword
                          : context.l10n.setPassword,
                  isLoading: changing,
                  isSuccess: _success,
                  onPressed: busy ? null : () => _submit(needsCurrent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
