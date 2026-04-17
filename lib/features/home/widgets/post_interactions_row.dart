import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:like_button/like_button.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../cubits/home_cubit/home_cubit.dart';
import '../models/post_model.dart';
import '../services/home_services.dart';
import '../../comments/widget/comments_sheet_section.dart';

class PostInteractionsRow extends StatelessWidget {
  const PostInteractionsRow({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) {
        if (prev is PostsLoaded && curr is PostsLoaded) {
          final oldPost = prev.posts.firstWhere(
            (p) => p.id == postId,
            orElse: () => prev.posts.first,
          );
          final newPost = curr.posts.firstWhere(
            (p) => p.id == postId,
            orElse: () => curr.posts.first,
          );

          return countAllComments(oldPost.comments) !=
              countAllComments(newPost.comments);
        }
        return false;
      },
      builder: (context, state) {
        if (state is! PostsLoaded) {
          return const SizedBox.shrink();
        }

        final post = state.posts.firstWhere((p) => p.id == postId);

        final totalComments = countAllComments(post.comments);

        return _InteractionsContent(post: post, totalComments: totalComments);
      },
    );
  }
}

class _InteractionsContent extends StatelessWidget {
  const _InteractionsContent({required this.post, required this.totalComments});

  final PostModel post;
  final int totalComments;

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final currUserId = homeCubit.currentUserData?.id;

    return Column(
      children: [
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Gap(18),
            _LikeButtonWidget(post: post, currUserId: currUserId),

            const Gap(20),

            _CommentButtonWidget(post: post, totalComments: totalComments),

            const Gap(20),

            const _ShareButtons(),

            const Spacer(),

            const _SaveButtons(),

            const Gap(12),
          ],
        ),
        const Gap(8),
      ],
    );
  }
}

class _LikeButtonWidget extends StatelessWidget {
  const _LikeButtonWidget({required this.post, required this.currUserId});

  final PostModel post;
  final String? currUserId;

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final state = context.watch<HomeCubit>().state;

    final currentPost =
        (state is PostsLoaded)
            ? state.posts.firstWhere((p) => p.id == post.id)
            : post;

    return LikeButton(
      size: 24,
      isLiked: currentPost.isLikedBy(currUserId!),
      likeCount: currentPost.likesCount,
      circleColor: CircleColor(
        start: Theme.of(context).primaryColor,
        end: Theme.of(context).primaryColor.withValues(alpha: 0.5),
      ),
      bubblesColor: BubblesColor(
        dotPrimaryColor: Theme.of(context).primaryColor,
        dotSecondaryColor: Theme.of(
          context,
        ).primaryColor.withValues(alpha: 0.5),
        dotThirdColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
      ),
      likeBuilder: (isLiked) {
        return Icon(
          isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
          color: isLiked ? Theme.of(context).primaryColor : AppColors.grey6,
          size: 24,
        );
      },
      countBuilder: (count, isLiked, text) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '${currentPost.likesCount}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      },
      onTap: (isLiked) async {
        homeCubit.toggleLike(currentPost);
        return !isLiked;
      },
    );
  }
}

class _CommentButtonWidget extends StatelessWidget {
  const _CommentButtonWidget({required this.post, required this.totalComments});

  final PostModel post;
  final int totalComments;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final homeCubit = context.read<HomeCubit>();
        final homeServices = context.read<HomeServices>();
        final commentsCubit = CommentsCubit(
          homeServices,
          currentUserData: context.read<HomeCubit>().currentUserData,
        );
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder:
              (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: homeCubit),
                  BlocProvider.value(value: commentsCubit),
                ],
                child: CommentsSheetSection(postId: post.id),
              ),
        ).whenComplete(() {
          commentsCubit.resetCollapsedComments();
        });
      },
      child: Row(
        children: [
          Image.asset(AppImages.commentAtPostIcon, width: 24, height: 24),
          const Gap(4),
          Text('$totalComments', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ShareButtons extends StatelessWidget {
  const _ShareButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Image.asset(AppImages.sharePostIcon, width: 24, height: 24)],
    );
  }
}

class _SaveButtons extends StatelessWidget {
  const _SaveButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Image.asset(AppImages.savePostIcon, width: 24, height: 24)],
    );
  }
}
