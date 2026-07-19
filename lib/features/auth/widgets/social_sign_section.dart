import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_grey_container.dart';
import '../cubit/auth_cubit/auth_cubit.dart';

class SocialSignSection extends StatelessWidget {
  const SocialSignSection({super.key, required this.label});
  final String label;
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(label),
            ),
            Expanded(child: Divider()),
          ],
        ),
        Gap(14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomGreyContainer(
              img: AppImages.google,
              onTap: () => context.read<AuthCubit>().signInWithGoogle(),
            ),
            CustomGreyContainer(
              img: AppImages.facebook,
              onTap: () => context.read<AuthCubit>().signInWithFacebook(),
            ),
            CustomGreyContainer(
              img: _isIOS ? AppImages.apple : AppImages.microsoft,
              onTap: () {
                if (_isIOS) {
                  // Apple Sign-In:
                } else {
                  context.read<AuthCubit>().signInWithMicrosoft();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
