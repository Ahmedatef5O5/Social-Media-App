import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';

class HomeViewHeaderSection extends StatelessWidget {
  const HomeViewHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Image.asset(AppImages.headerLogo, height: 25),
          Spacer(),
          InkWell(
            onTap: () {},
            child: Image.asset(AppImages.searchIcon, width: 24),
          ),
          Gap(16),
          InkWell(
            onTap: () {},
            child: Image.asset(AppImages.notificationIcon, width: 24),
          ),
          Gap(16),
          InkWell(
            onTap: () {},
            child: Image.asset(AppImages.paperPlaneIcon, width: 24),
          ),
        ],
      ),
    );
  }
}
