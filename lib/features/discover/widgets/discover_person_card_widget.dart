import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class DiscoverPersonCardWidget extends StatelessWidget {
  final UserData userData;
  const DiscoverPersonCardWidget({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: AppColors.white,
      child: ListTile(
        leading: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl:
                  (userData.imageUrl != null && userData.imageUrl!.isNotEmpty)
                      ? userData.imageUrl!
                      : AppImages.defaultUserImg,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CustomLoadingIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.person),
              maxWidthDiskCache: 200,
              maxHeightDiskCache: 200,
            ),
          ),
        ),

        title: Text(
          userData.name,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          (userData.userName != null && userData.userName!.isNotEmpty)
              ? userData.userName!
              : '1K Followers',
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: AppColors.grey4,
          ),
        ),
        trailing: CustomElevatedButton(
          maximumSize: Size(95, 34),
          minimumSize: Size(95, 34),
          txtBtn: 'Follow',
          txtBtnStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.white,
            fontSize: 15,
          ),
          onPressed: () {},
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
