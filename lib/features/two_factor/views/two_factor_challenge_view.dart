import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bootstrap/app_bootstrap.dart'
    show completeSignInBootstrap;
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_guard.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../../auth/cubits/auth_cubit/auth_cubit.dart';
import '../cubits/two_factor_challenge_cubit.dart';
import '../cubits/two_factor_challenge_state.dart';
import '../services/two_factor_lockout_store.dart';
import '../services/two_factor_service.dart';
import '../widgets/otp_code_field.dart';
import '../widgets/totp_window_indicator.dart';

class TwoFactorChallengeView extends StatelessWidget {
  const TwoFactorChallengeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => TwoFactorChallengeCubit(
            service: const TwoFactorService(),
            lockout: TwoFactorLockoutStore(),
            userId: SupabaseProvider.idOrNull ?? '',
          )..init(),
      child: const _ChallengeBody(),
    );
  }
}

class _ChallengeBody extends StatefulWidget {
  const _ChallengeBody();

  @override
  State<_ChallengeBody> createState() => _ChallengeBodyState();
}

class _ChallengeBodyState extends State<_ChallengeBody> {
  final GlobalKey<OtpCodeFieldState> _otp = GlobalKey<OtpCodeFieldState>();
  final TextEditingController _backupCtrl = TextEditingController();
  String _totpCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!SessionGuard.hasSession) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.authRoute, (r) => false);
      } else if (!SessionGuard.isMfaChallengePending) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.homeRoute, (r) => false);
      }
    });
  }

  @override
  void dispose() {
    _backupCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCompleted(bool reenroll) async {
    final nav = Navigator.of(context, rootNavigator: true);
    context.read<AuthCubit>().completeMfa();
    await completeSignInBootstrap();
    if (!mounted) return;
    nav.pushNamedAndRemoveUntil(AppRoutes.homeRoute, (r) => false);
    if (reenroll) {
      AppToast.warning(
        'Two-factor was turned off after you used a recovery code.',
        actionLabel: 'Set up again',
        onAction: () => nav.pushNamed(AppRoutes.twoFactorSetupRoute),
        duration: const Duration(seconds: 10),
      );
    }
  }

  Future<void> _submitTotp(TwoFactorChallengeCubit cubit, String code) async {
    await cubit.submitTotp(code);
    if (mounted && !cubit.state.completed) {
      _otp.currentState?.clear();
      _totpCode = '';
    }
  }

  Future<void> _signOut() async {
    final nav = Navigator.of(context);
    await context.read<AuthCubit>().signOutFromMfaChallenge();
    nav.pushNamedAndRemoveUntil(AppRoutes.authRoute, (r) => false);
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BackgroundThemeWidget(
          child: SafeArea(
            child: BlocConsumer<
              TwoFactorChallengeCubit,
              TwoFactorChallengeState
            >(
              listenWhen: (p, c) => !p.completed && c.completed,
              listener:
                  (context, state) => _onCompleted(state.reenrollRequired),
              builder: (context, state) {
                final cubit = context.read<TwoFactorChallengeCubit>();
                final isTotp = state.mode == TwoFactorChallengeMode.totp;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 48,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  size: 48,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Two-step verification',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isTotp
                                    ? 'Enter the 6-digit code from your authenticator app.'
                                    : 'Enter one of the recovery codes you saved. Using '
                                        'it turns two-factor off.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 28),
                              if (isTotp) ...[
                                OtpCodeField(
                                  key: _otp,
                                  enabled: !state.submitting && !state.isLocked,
                                  hasError: state.error != null,
                                  onChanged: (v) => _totpCode = v,
                                  onCompleted: (code) async {
                                    await _submitTotp(cubit, code);
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        state.submitting || state.isLocked
                                            ? null
                                            : () => _otp.currentState?.paste(),
                                    child: const Text('Paste code'),
                                  ),
                                ),
                                const Center(child: TotpWindowIndicator()),
                              ] else ...[
                                CustomTextFormField(
                                  controller: _backupCtrl,
                                  hintText: 'XXXXX-XXXXX',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Za-z0-9-]'),
                                    ),
                                    LengthLimitingTextInputFormatter(11),
                                  ],
                                ),
                              ],
                              if (state.isLocked) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.timer,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Too many attempts. Try again in '
                                          '${_mmss(state.lockRemaining!)}.',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (state.error != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  state.error!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                              if (state.showClockHint && !state.isLocked) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Still not working? Make sure your phone’s date and '
                                  'time are set to automatic in your device settings.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              CustomElevatedButton(
                                txtBtn: 'Verify',
                                isLoading: state.submitting,
                                onPressed:
                                    state.isLocked
                                        ? null
                                        : () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          if (isTotp) {
                                            _submitTotp(cubit, _totpCode);
                                          } else {
                                            cubit.submitBackup(
                                              _backupCtrl.text,
                                            );
                                          }
                                        },
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: TextButton(
                                  onPressed:
                                      state.submitting
                                          ? null
                                          : () {
                                            _backupCtrl.clear();
                                            cubit.setMode(
                                              isTotp
                                                  ? TwoFactorChallengeMode
                                                      .backup
                                                  : TwoFactorChallengeMode.totp,
                                            );
                                          },
                                  child: Text(
                                    isTotp
                                        ? 'Use a backup code'
                                        : 'Use authenticator code',
                                  ),
                                ),
                              ),
                              Center(
                                child: TextButton(
                                  onPressed: state.submitting ? null : _signOut,
                                  child: Text(
                                    'Not you? Sign out',
                                    style: TextStyle(color: theme.hintColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
