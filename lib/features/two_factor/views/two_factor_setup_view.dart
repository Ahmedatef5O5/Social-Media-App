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
        return;
      case TwoFactorSetupStep.recoveryCodes:
        final leave = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Leave without saving?'),
                content: const Text(
                  'Your recovery codes will not be shown again. Two-factor stays '
                  'on, and you can generate new codes later from Settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Stay'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Leave'),
                  ),
                ],
              ),
        );
        if (leave == true && context.mounted) Navigator.of(context).pop(true);
      case TwoFactorSetupStep.codesError:
        Navigator.of(context).pop(true);
      default:
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
                            'Step ${_stepNumber(state.step)} of 4',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableHeight = constraints.maxHeight - 36;
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: availableHeight,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: KeyedSubtree(
                                  key: ValueKey(state.step),
                                  child: _content(
                                    context,
                                    cubit,
                                    state,
                                    availableHeight,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
    double availableHeight,
  ) {
    switch (state.step) {
      case TwoFactorSetupStep.intro:
        return TwoFactorIntroStep(onContinue: cubit.begin);

      case TwoFactorSetupStep.enrolling:
      case TwoFactorSetupStep.generatingCodes:
        return SizedBox(
          height: availableHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 22),
                const SizedBox(height: 20),
                Text(
                  state.step == TwoFactorSetupStep.enrolling
                      ? 'Preparing your secure key...'
                      : 'Generating recovery codes...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
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
            AppToast.success('Two-factor authentication is on');
            Navigator.of(context).pop(true);
          },
        );

      case TwoFactorSetupStep.failure:
        return _ErrorStep(
          title: 'Could not start setup',
          message: state.error ?? 'Please try again.',
          primaryLabel: 'Try again',
          onPrimary: cubit.begin,
        );

      case TwoFactorSetupStep.codesError:
        return _ErrorStep(
          title: 'Two-factor is on, but codes failed',
          message:
              '${state.error ?? 'Recovery codes could not be generated.'}\n\n'
              'Your account is already protected. Retry now, or generate codes '
              'later from Settings.',
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
