import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignTextSection extends StatelessWidget {
  const SignTextSection({
    super.key,
    required this.staticText,
    required this.clickableText,
    this.onTap,
    this.textAlign = TextAlign.center,
  });
  final String staticText;
  final String clickableText;
  final TextAlign? textAlign;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textAlign: textAlign,
      TextSpan(
        text: staticText,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(),
        children: [
          TextSpan(
            text: clickableText,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).primaryColor,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}
