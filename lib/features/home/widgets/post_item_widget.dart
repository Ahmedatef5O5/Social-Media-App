import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:like_button/like_button.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/home/widgets/comments_sheet_section.dart';
import 'package:social_media_app/features/home/widgets/file_attachment_preview.dart';
import 'package:social_media_app/features/home/widgets/post_video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/home_cubit.dart';
import '../models/post_model.dart';

class PostItemWidget extends StatelessWidget {
  const PostItemWidget({super.key, required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return SizedBox.shrink();

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) {
        if (previous is PostsLoaded && current is PostsLoaded) {
          final oldPost = previous.posts.firstWhere((p) => p.id == post.id);
          final newPost = current.posts.firstWhere((p) => p.id == post.id);
          return oldPost.likesCount != newPost.likesCount ||
              oldPost.isLikedBy(userId) != newPost.isLikedBy(userId) ||
              oldPost.likersImages?.length != newPost.likersImages?.length;
        }
        return true;
      },
      builder: (context, state) {
        PostModel currentPost = post;
        if (state is PostsLoaded) {
          currentPost = state.posts.firstWhere(
            (p) => p.id == post.id,
            orElse: () => post,
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 1, color: AppColors.blueGrey1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                            (post.authorImageUrl != null &&
                                    post.authorImageUrl!.isNotEmpty)
                                ? post.authorImageUrl!
                                : AppImages.defaultUserImg,

                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CustomLoadingIndicator(),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.person),
                        maxWidthDiskCache: 200,
                        maxHeightDiskCache: 200,
                      ),
                    ),
                  ),
                  title: Text(
                    post.authorName ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    FormattedDate.getFormattedDate(
                      DateTime.parse(
                        post.createdAt,
                      ).toLocal().toIso8601String(),
                    ),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: AppColors.black54,
                    ),
                  ),
                ),
                const Gap(4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    post.text,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      // color: AppColors.black54,
                    ),
                  ),
                ),
                const Gap(8),
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  GestureDetector(
                    onTap:
                        () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed(
                          AppRoutes.fullScreenImageViewRoute,
                          arguments: post.imageUrl,
                        ),
                    child: Hero(
                      tag: post.imageUrl!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child:
                            post.imageUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: post.imageUrl!,
                                  width: double.infinity,

                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                            0.3,
                                        decoration: BoxDecoration(
                                          color: AppColors.grey7.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: const CustomLoadingIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) =>
                                          const Icon(Icons.error),
                                  filterQuality: FilterQuality.high,

                                  memCacheWidth: 800,
                                )
                                : null,
                      ),
                    ),
                  ),
                if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                  PostVideoPlayer(videoUrl: post.videoUrl!),

                if (post.fileUrl != null && post.fileUrl!.isNotEmpty)
                  FileAttachmentPreview(url: post.fileUrl!, onTap: () {}),
                const Gap(12),

                Row(
                  children: [
                    const Gap(12),
                    Row(
                      children: [
                        LikeButton(
                          size: 24,
                          circleColor: CircleColor(
                            start: AppColors.primaryColor,
                            end: AppColors.primaryColor.withValues(alpha: 0.5),
                          ),
                          bubblesColor: BubblesColor(
                            dotPrimaryColor: AppColors.primaryColor,
                            dotSecondaryColor: AppColors.bgColor,
                          ),
                          isLiked: currentPost.isLikedBy(userId),
                          likeCount: currentPost.likesCount,
                          countPostion: CountPostion.right,
                          likeBuilder: (bool isLiked) {
                            return Icon(
                              isLiked
                                  ? Icons.thumb_up_alt
                                  : Icons.thumb_up_alt_outlined,
                              color:
                                  isLiked
                                      ? AppColors.primaryColor
                                      : AppColors.grey6,
                              size: 24,
                            );
                          },
                          countBuilder:
                              (likeCount, isLiked, text) => Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  '${currentPost.likesCount}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                          onTap: (isLiked) async {
                            await homeCubit.toggleLike(currentPost);
                            return !isLiked;
                          },
                        ),

                        // Gap(4),
                      ],
                    ),

                    Gap(12),
                    InkWell(
                      onTap: () {
                        final homeCubit = context.read<HomeCubit>();
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: AppColors.white,
                          useSafeArea: false,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder:
                              (BuildContext context) => BlocProvider.value(
                                value: homeCubit,
                                child: CommentsSheetSection(postId: post.id),
                              ),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            AppImages.commentAtPostIcon,
                            width: 24,
                            height: 24,
                          ),

                          const Gap(4),
                          Text(
                            '${currentPost.comments?.length ?? 0}',

                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Image.asset(AppImages.sharePostIcon, width: 24, height: 24),

                    Spacer(),
                    Image.asset(AppImages.savePostIcon, width: 24, height: 24),

                    const Gap(8),
                  ],
                ),

                const Gap(8),
              ],
            ),
          ),
        );
      },
    );
  }
}
