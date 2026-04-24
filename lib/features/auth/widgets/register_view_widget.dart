import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/utilities/app_formatters.dart';
import 'package:social_media_app/core/utilities/app_validators.dart';
import 'package:social_media_app/features/auth/cubit/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/auth/widgets/password_strength_bar.dart';
import 'package:social_media_app/features/auth/widgets/sign_text_section.dart';
import 'package:social_media_app/features/auth/widgets/social_sign_section.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';

class RegisterViewWidget extends StatefulWidget {
  const RegisterViewWidget({super.key});

  @override
  State<RegisterViewWidget> createState() => _RegisterViewWidgetState();
}

class _RegisterViewWidgetState extends State<RegisterViewWidget> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  bool _showStrenghtPasswordBar = false;
  final ValueNotifier<String> _passwordStrengthNotifier = ValueNotifier<String>(
    '',
  );

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      _passwordStrengthNotifier.value = _passwordController.text;
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _showStrenghtPasswordBar = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordStrengthNotifier.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Gap(4),
              CustomTextFormField(
                prefixIcon: Icon(Icons.person_rounded),
                controller: _fullNameController,
                labelText: 'Full Name',
                hintText: 'Your Full Name',
                inputFormatters: AppFormatters.noLeadingSpace,
                validator: AppValidators.validateName,
              ),
              Gap(18),
              CustomTextFormField(
                prefixIcon: Icon(Icons.email_rounded),
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter New Email',
                inputFormatters: AppFormatters.noSpaces,
                validator: AppValidators.validateEmail,
              ),
              Gap(18),
              CustomTextFormField(
                prefixIcon: Icon(Icons.lock_rounded),
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                labelText: 'Password',
                hintText: 'Type your password',
                isPassword: true,
                validator: AppValidators.validatePassword,
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 300),

                child:
                    _showStrenghtPasswordBar
                        ? Column(
                          children: [
                            const Gap(8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: MediaQuery.sizeOf(context).width * 0.5,
                                child: ValueListenableBuilder<String>(
                                  valueListenable: _passwordStrengthNotifier,
                                  builder: (context, value, child) {
                                    return PasswordStrengthBar(password: value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),
              Gap(18),
              CustomTextFormField(
                prefixIcon: Icon(Icons.lock_rounded),
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Retype your password',
                isPassword: true,
                validator:
                    (v) => AppValidators.validateConfirmPassword(
                      v,
                      _passwordController.text,
                    ),
              ),
              Gap(22),
              BlocConsumer<AuthCubit, AuthState>(
                listenWhen:
                    (previous, current) =>
                        current is AuthSuccess || current is AuthFailure,
                listener: (BuildContext context, AuthState state) {
                  if (state is AuthSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sign up Successfully',
                          style:
                              Theme.of(
                                context,
                              ).textTheme.titleSmall!.copyWith(),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );

                    if (context.mounted) {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamedAndRemoveUntil(
                        AppRoutes.homeRoute,
                        (route) => false,
                      );
                    }
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errMsg),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                buildWhen:
                    (previous, current) =>
                        current is AuthLoading ||
                        current is AuthSuccess ||
                        current is AuthFailure ||
                        current is AuthInitial ||
                        current is AuthSignedOut,

                builder: (context, state) {
                  if (state is AuthLoading) {
                    return CustomElevatedButton(
                      txtBtn: "Join Now",
                      onPressed: null,
                      isLoading: true,
                    );
                  }

                  return CustomElevatedButton(
                    txtBtn: "Join Now",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_passwordController.text ==
                            _confirmPasswordController.text) {
                          context.read<AuthCubit>().signUpWithEmail(
                            _fullNameController.text.trim(),
                            _emailController.text.trim(),
                            _passwordController.text,
                          );
                        }
                      }
                    },
                  );
                },
              ),
              Gap(18),
              SocialSignSection(label: 'Or Sign up with'),
              Gap(22),
              SignTextSection(
                staticText: 'By Using this app you agree with the\n',
                clickableText: 'Terms of Service',
              ),
              Gap(bottomInset > 0 ? bottomInset : 18),
              Gap(18),
            ],
          ),
        ),
      ),
    );
  }
}
