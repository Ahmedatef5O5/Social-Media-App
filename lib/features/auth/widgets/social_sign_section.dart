import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_grey_container.dart';

class SocialSignSection extends StatelessWidget {
  const SocialSignSection({super.key, required this.label});
  final String label;
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
            CustomGreyContainer(img: AppImages.google),
            CustomGreyContainer(img: AppImages.facebook),
            CustomGreyContainer(img: AppImages.apple),
          ],
        ),
      ],
    );
  }
}
