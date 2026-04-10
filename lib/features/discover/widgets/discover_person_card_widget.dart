import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../profile/widgets/user_preview_dialog.dart';

class DiscoverPersonCardWidget extends StatelessWidget {
  final UserData userData;
  const DiscoverPersonCardWidget({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0.4,
      shadowColor:
          theme.brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.profileViewRoute, arguments: userData.id);
        },
        leading: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => UserPreviewDialog(
                    user: ChatUserModel.fromEntity(userData),
                  ),
            );
          },
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child:
                  (userData.imageUrl != null && userData.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                        imageUrl: userData.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CustomLoadingIndicator(),
                        errorWidget:
                            (context, url, error) => Image.asset(
                              AppImages.defaultUserImg,
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset(
                        AppImages.defaultUserImg,
                        fit: BoxFit.cover,
                      ),
            ),
          ),
        ),

        title: Text(
          userData.name,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          (userData.userName != null && userData.userName!.isNotEmpty)
              ? userData.userName!
              : '1K Followers',
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: AppColors.grey4,
          ),
        ),
        trailing: CustomElevatedButton(
          maximumSize: Size(95, 34),
          minimumSize: Size(95, 34),
          txtBtn: 'Follow',
          txtBtnStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.white.withValues(alpha: 0.75),
            fontSize: 15,
          ),
          onPressed: () {},
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
