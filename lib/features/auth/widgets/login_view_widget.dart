import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/core/widgets/custom_text_form_field.dart';
import 'package:social_media_app/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/auth/widgets/sign_text_section.dart';
import 'package:social_media_app/features/auth/widgets/social_sign_section.dart';
import '../../../core/router/app_routes.dart';

class LoginViewWidget extends StatefulWidget {
  const LoginViewWidget({super.key});

  @override
  State<LoginViewWidget> createState() => _LoginViewWidgetState();
}

class _LoginViewWidgetState extends State<LoginViewWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            children: [
              Gap(12),
              CustomTextFormField(
                controller: _emailController,
                labelText: 'Email/Phone',
                hintText: 'Email/Phone',
                validator: (v) => v!.isEmpty ? 'Email is required' : null,
              ),
              Gap(26),
              CustomTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter password',
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
              Gap(12),
              Align(
                alignment: Alignment.topRight,
                child: Text('Forgor Password?'),
              ),
              Gap(42),
              BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login Successfully'),
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
                      txtBtn: "Login",
                      onPressed: null,
                      isLoading: true,
                    );
                  }
                  return CustomElevatedButton(
                    txtBtn: "Login",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<AuthCubit>().signInWithEmail(
                          _emailController.text,
                          _passwordController.text,
                        );
                      }
                    },
                  );
                },
              ),
              Gap(14),
              SocialSignSection(label: 'Or Sign in with'),
              Gap(22),
              SignTextSection(
                staticText: 'Don\'t  have an account?',
                clickableText: '\t\tSign up',
              ),
              Gap(18),
              Gap(bottomInset > 0 ? bottomInset : 18),
            ],
          ),
        ),
      ),
    );
  }
}
