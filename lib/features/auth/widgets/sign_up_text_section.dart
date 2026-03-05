import 'package:flutter/material.dart';

class SignUpTextSection extends StatelessWidget {
  const SignUpTextSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Don\'t  have an account?',
        style: Theme.of(context).textTheme.titleSmall!.copyWith(),
        children: [
          TextSpan(
            text: '\t\tSign up',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).primaryColor,
            ),
            onEnter: (onClick) {},
          ),
        ],
      ),
    );
  }
}
