import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/widgets/post_actions_menu.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/home_cubit.dart';
import '../models/post_model.dart';

class PostHeaderWidget extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final HomeCubit homeCubit;
  const PostHeaderWidget({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.homeCubit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AuthorImageWidget(post: post),
      title: Text(
        post.authorName ?? 'Unknown',
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        FormattedDate.getFormattedDate(
          DateTime.parse(post.createdAt).toLocal().toIso8601String(),
        ),
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: AppColors.black54,
        ),
      ),
      trailing: PostActionsMenu(
        post: post,
        currentUserId: currentUserId,
        homeCubit: homeCubit,
      ),
    );
  }
}

class AuthorImageWidget extends StatelessWidget {
  const AuthorImageWidget({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl:
              (post.authorImageUrl != null && post.authorImageUrl!.isNotEmpty)
                  ? post.authorImageUrl!
                  : AppImages.defaultUserImg,

          fit: BoxFit.cover,
          placeholder: (context, url) => const CustomLoadingIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.person),
          maxWidthDiskCache: 200,
          maxHeightDiskCache: 200,
        ),
      ),
    );
  }
}
