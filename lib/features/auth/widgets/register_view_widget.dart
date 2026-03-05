import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/auth/widgets/sign_text_section.dart';
import 'package:social_media_app/features/auth/widgets/social_sign_section.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';

class RegisterViewWidget extends StatelessWidget {
  const RegisterViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Gap(4),
            CustomTextFormField(
              labelText: 'Full Name',
              hintText: 'Your Full Name',
            ),
            Gap(18),
            CustomTextFormField(
              labelText: 'Email/Phone',
              hintText: 'Email/Phone',
            ),
            Gap(18),
            CustomTextFormField(
              labelText: 'Password',
              hintText: 'Type your password',
            ),
            Gap(18),
            CustomTextFormField(
              labelText: 'Confirm Password',
              hintText: 'Retype your password',
            ),
            Gap(22),
            CustomElevatedButton(txtBtn: "Join Now", onPressed: () {}),
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
    );
  }
}
