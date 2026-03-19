import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import '../../../core/themes/app_colors.dart';

class CreatePostUserInfo extends StatelessWidget {
  const CreatePostUserInfo({
    super.key,
    required this.userName,
    this.userImageUrl,
  });
  final String userName;
  final String? userImageUrl;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Hero(
          tag: 'user-avatar-hero',
          child: MainUserAvatar(
            imageUrl: userImageUrl,
            size: 48,
            showBorder: true,
          ),
        ),

        Gap(12),
        Text(
          userName,
          // 'user name',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: AppColors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        Spacer(),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(width: 1.2, color: AppColors.black38),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Row(
              children: [
                Text(
                  'Public',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: AppColors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 26, color: AppColors.black38),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
