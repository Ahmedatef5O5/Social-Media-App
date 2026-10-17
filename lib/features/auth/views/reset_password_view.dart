import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utilities/app_formatters.dart';
import '../../../core/utilities/app_validators.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../cubits/auth_cubit/auth_cubit.dart';
import '../services/auth_recovery_coordinator.dart';
import '../widgets/password_strength_bar.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewCustomState();
}

class _ResetPasswordViewCustomState extends State<ResetPasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _newPwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verifyActiveRecoverySession();
  }

  void _verifyActiveRecoverySession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SupabaseProvider.isAuthenticated) {
        AppToast.error(
          'The recovery session is invalid or has expired. Please request a new link.',
        );
        AuthRecoveryCoordinator.consumeRecovery();
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil(AppRoutes.authRoute, (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  void _executePasswordUpdate() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AuthCubit>().updatePassword(_newPwdController.text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(AuthRecoveryCoordinator.abandon());
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil(AppRoutes.authRoute, (route) => false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: BackgroundThemeWidget(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Gap(20),
                    Image.asset(
                      AppImages.splashLogo,
                      width: 225,
                      height: 225,
                      fit: BoxFit.contain,
                    ),
                    const Gap(24),
                    Text(
                      'Create New Password',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Your new password must be at least 6 characters long.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey,
                        height: 1.4,
                      ),
                    ),
                    const Gap(32),
                    CustomTextFormField(
                      controller: _newPwdController,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      labelText: 'New Password',
                      hintText: 'Enter new password',
                      isPassword: true,
                      inputFormatters: AppFormatters.noSpaces,
                      validator: AppValidators.validatePassword,
                    ),
                    const Gap(8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.6,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _newPwdController,
                          builder:
                              (context, value, _) =>
                                  PasswordStrengthBar(password: value.text),
                        ),
                      ),
                    ),
                    const Gap(16),
                    CustomTextFormField(
                      controller: _confirmPwdController,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      isPassword: true,
                      inputFormatters: AppFormatters.noSpaces,
                      validator:
                          (val) => AppValidators.validateConfirmPassword(
                            val,
                            _newPwdController.text,
                          ),
                    ),
                    const Gap(32),
                    BlocConsumer<AuthCubit, AuthState>(
                      listenWhen:
                          (prev, curr) =>
                              curr is PasswordUpdateSuccess ||
                              curr is AuthFailure,
                      listener: (context, state) {
                        if (state is PasswordUpdateSuccess) {
                          AppToast.success('Password updated successfully');
                          AuthRecoveryCoordinator.consumeRecovery();
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamedAndRemoveUntil(
                            AppRoutes.homeRoute,
                            (route) => false,
                          );
                        } else if (state is AuthFailure) {
                          AppToast.error(state.errMsg);
                        }
                      },
                      builder: (context, state) {
                        return CustomElevatedButton(
                          txtBtn: 'Update Password',
                          isLoading: state is AuthLoading,
                          onPressed:
                              state is AuthLoading
                                  ? null
                                  : _executePasswordUpdate,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
