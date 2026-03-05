import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/core/widgets/custom_text_form_field.dart';
import 'package:social_media_app/features/auth/widgets/sign_text_section.dart';
import 'package:social_media_app/features/auth/widgets/social_sign_section.dart';

class LoginViewWidget extends StatelessWidget {
  const LoginViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Gap(12),
            CustomTextFormField(
              labelText: 'Email/Phone',
              hintText: 'Email/Phone',
            ),
            Gap(26),
            CustomTextFormField(
              labelText: 'Password',
              hintText: 'Enter password',
              isPassword: true,
            ),
            Gap(12),
            Align(
              alignment: Alignment.topRight,
              child: Text('Forgor Password?'),
            ),
            Gap(42),
            CustomElevatedButton(txtBtn: "Login", onPressed: () {}),
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
    );
  }
}
