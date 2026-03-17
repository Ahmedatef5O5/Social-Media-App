import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/auth/logic/auth_cubit/auth_cubit.dart';
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Gap(4),
              CustomTextFormField(
                controller: _fullNameController,
                labelText: 'Full Name',
                hintText: 'Your Full Name',
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              Gap(18),
              CustomTextFormField(
                controller: _emailController,
                labelText: 'Email/Phone',
                hintText: 'Email/Phone',
                validator: (v) => v!.isEmpty ? 'Email is required' : null,
              ),
              Gap(18),
              CustomTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Type your password',
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password is required';
                  } else if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              Gap(18),
              CustomTextFormField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Retype your password',
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Confirm Password is required';
                  } else if (v != _passwordController.text) {
                    return 'Password does not match';
                  }
                  return null;
                },
                isPassword: true,
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
                        content: Text('Sign up Successfully'),
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
                        current is AuthFailure,

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
                            _fullNameController.text,
                            _emailController.text,
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
