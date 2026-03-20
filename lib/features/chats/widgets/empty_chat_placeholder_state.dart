import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';

class EmptyChatPlaceholderState extends StatelessWidget {
  const EmptyChatPlaceholderState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AppImages.blueSmileFaceLot,
              // width: 200,
              // height: 180,
              repeat: true,
              animate: true,
            ),
            const Gap(12),
            Text(
              'No messages yet.',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}
