import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/core/widgets/custom_text_form_field.dart';
import 'package:social_media_app/features/auth/widgets/sign_up_text_section.dart';
import 'package:social_media_app/features/auth/widgets/social_sign_in_section.dart';

class LoginViewWidget extends StatelessWidget {
  const LoginViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Gap(12),
          CustomTextFormField(
            labelText: 'Email/Phone',
            hintText: 'Email/Phone',
          ),
          Gap(22),
          CustomTextFormField(
            labelText: 'Password',
            hintText: 'Enter password',
          ),
          Gap(12),
          Align(alignment: Alignment.topRight, child: Text('Forgor Password?')),
          Gap(18),
          CustomElevatedButton(txtBtn: "Login", onPressed: () {}),
          Gap(14),
          SocialSignInSection(),
          Gap(22),
          SignUpTextSection(),
          Gap(18),
        ],
      ),
    );
  }
}
