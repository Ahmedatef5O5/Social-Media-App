import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../cubits/two_factor_setup_cubit.dart';
import '../cubits/two_factor_setup_state.dart';
import '../services/two_factor_service.dart';
import '../widgets/recovery_codes_step.dart';
import '../widgets/two_factor_intro_step.dart';
import '../widgets/two_factor_qr_step.dart';
import '../widgets/two_factor_verify_step.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

/// Opened from Settings with `pushNamed<bool>`. Pops `true` once 2FA is active
/// so the caller refreshes the switch; `false` when the wizard was abandoned.
class TwoFactorSetupView extends StatelessWidget {
  const TwoFactorSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TwoFactorSetupCubit(const TwoFactorService()),
      child: const _SetupBody(),
    );
  }
}

class _SetupBody extends StatelessWidget {
  const _SetupBody();

  int _stepNumber(TwoFactorSetupStep s) => switch (s) {
    TwoFactorSetupStep.intro => 1,
    TwoFactorSetupStep.enrolling ||
    TwoFactorSetupStep.scan ||
    TwoFactorSetupStep.failure => 2,
    TwoFactorSetupStep.enterCode || TwoFactorSetupStep.verifying => 3,
    _ => 4,
  };

  Future<void> _onBack(BuildContext context, TwoFactorSetupState state) async {
    switch (state.step) {
      case TwoFactorSetupStep.enrolling:
      case TwoFactorSetupStep.verifying:
      case TwoFactorSetupStep.generatingCodes:
        return; // a request is in flight
      case TwoFactorSetupStep.recoveryCodes:
        final leave = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(context.l10n.leaveWithoutSaving),
                content: Text(context.l10n.yourRecoveryCodesWill),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(context.l10n.stay),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(context.l10n.leave),
                  ),
                ],
              ),
        );
        if (leave == true && context.mounted) Navigator.of(context).pop(true);
      case TwoFactorSetupStep.codesError:
        Navigator.of(context).pop(true); // 2FA is already active
      default:
        // Closing the cubit removes the unverified factor.
        Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<TwoFactorSetupCubit, TwoFactorSetupState>(
      builder: (context, state) {
        final cubit = context.read<TwoFactorSetupCubit>();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBack(context, state);
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BackgroundThemeWidget(
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.back),
                            onPressed: () => _onBack(context, state),
                          ),
                          const Spacer(),
                          Text(
                            context.l10n.stepOf4(_stepNumber(state.step)),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: KeyedSubtree(
                            key: ValueKey(state.step),
                            child: _content(context, cubit, state),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    TwoFactorSetupCubit cubit,
    TwoFactorSetupState state,
  ) {
    switch (state.step) {
      case TwoFactorSetupStep.intro:
        return TwoFactorIntroStep(onContinue: cubit.begin);

      case TwoFactorSetupStep.enrolling:
      case TwoFactorSetupStep.generatingCodes:
        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(radius: 16),
                    const SizedBox(height: 18),
                    Text(
                      state.step == TwoFactorSetupStep.enrolling
                          ? context.l10n.preparingYourSecureKey
                          : context.l10n.generatingRecoveryCodes,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case TwoFactorSetupStep.scan:
        return TwoFactorQrStep(
          enrollment: state.enrollment!,
          onNext: cubit.goToCodeEntry,
        );

      case TwoFactorSetupStep.enterCode:
      case TwoFactorSetupStep.verifying:
        return TwoFactorVerifyStep(
          verifying: state.step == TwoFactorSetupStep.verifying,
          error: state.error,
          showClockHint: state.showClockHint,
          onSubmit: cubit.verify,
          onBack: cubit.backToScan,
        );

      case TwoFactorSetupStep.recoveryCodes:
        return RecoveryCodesStep(
          codes: state.codes,
          onDone: () {
            AppToast.success(context.l10n.twoFactorAuthenticationIs2);
            Navigator.of(context).pop(true);
          },
        );

      case TwoFactorSetupStep.failure:
        return _ErrorStep(
          title: context.l10n.couldNotStartSetup,
          message: state.error ?? context.l10n.pleaseTryAgain,
          primaryLabel: 'Try again',
          onPrimary: cubit.begin,
        );

      case TwoFactorSetupStep.codesError:
        return _ErrorStep(
          title: context.l10n.twoFactorIsOn,
          message: context.l10n.yourAccountIsAlready(
            state.error ?? context.l10n.recoveryCodesCouldNot,
          ),
          primaryLabel: 'Retry',
          onPrimary: cubit.retryGenerateCodes,
          secondaryLabel: 'Skip for now',
          onSecondary: () => Navigator.of(context).pop(true),
        );
    }
  }
}

class _ErrorStep extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _ErrorStep({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        const Center(
          child: Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 56,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 24),
        CustomElevatedButton(txtBtn: primaryLabel, onPressed: onPrimary),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
