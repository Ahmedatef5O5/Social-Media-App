import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:like_button/like_button.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/home_cubit.dart';
import '../models/post_model.dart';
import 'comments_sheet_section.dart';

class PostInteractionsRow extends StatelessWidget {
  const PostInteractionsRow({
    super.key,
    required this.currentPost,
    required this.currUserId,
    required this.homeCubit,
    required this.post,
  });

  final PostModel currentPost;
  final String? currUserId;
  final HomeCubit homeCubit;
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  isLiked: currentPost.isLikedBy(currUserId!),
                  likeCount: currentPost.likesCount,
                  countPostion: CountPostion.right,
                  likeBuilder: (bool isLiked) {
                    return Icon(
                      isLiked
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                      color: isLiked ? AppColors.primaryColor : AppColors.grey6,
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
            const Gap(12),
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
    );
  }
}
