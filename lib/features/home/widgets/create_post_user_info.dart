import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';

class CreatePostUserInfo extends StatelessWidget {
  const CreatePostUserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(radius: 18, child: Icon(Icons.person)),
        Gap(12),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(width: 1, color: AppColors.black38),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                Text(
                  'Public',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: AppColors.black87,
                    fontSize: 17,
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
