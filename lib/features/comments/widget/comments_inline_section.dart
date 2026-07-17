import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/model/comment_sort_option.dart';
import 'package:social_media_app/features/comments/widget/comments_shimmer_skeleton.dart';
import 'package:social_media_app/features/posts/cubit/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/model/post_model.dart';
import 'package:social_media_app/features/comments/widget/comments_section.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../helper/comment_sheet_shared_widgets.dart';
import '../helper/comments_count_skeleton.dart';

class CommentsInlineSection extends StatelessWidget {
  final String postId;
  final void Function(String commentId, String authorName)? onReplyTap;
  final void Function(CommentModel)? onEditTap;

  const CommentsInlineSection({
    super.key,
    required this.postId,
    this.onReplyTap,
    this.onEditTap,
  });

  void _changeSort(BuildContext context, CommentSortOption option) {
    final cubit = context.read<CommentsCubit>();
    if (cubit.currentSort == option) return;
    cubit.loadComments(postId: postId, sort: option);
  }

  @override
  Widget build(BuildContext context) {
    final post = context.select<PostsCubit, PostModel?>((cubit) {
      final state = cubit.state;
      if (state is PostsLoaded) {
        try {
          return state.posts.findById(postId);
        } catch (_) {
          return null;
        }
      }
      return null;
    });

    if (post == null) {
      return const SizedBox(height: 200, child: CustomLoadingIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),

        BlocBuilder<CommentsCubit, CommentsState>(
          buildWhen:
              (previous, current) =>
                  current is CommentsListLoading ||
                  current is CommentsListLoaded ||
                  current is CommentOptimisticAdded ||
                  current is CommentTempIdResolved,
          builder: (context, state) {
            final cubit = context.read<CommentsCubit>();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:
                      cubit.isLoadingComments
                          ? const CommentsCountSkeleton(
                            key: ValueKey('inline_count_skeleton'),
                          )
                          : Text(
                            key: const ValueKey('inline_count_text'),
                            '${countAllComments(cubit.comments)} Comments',
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(color: AppColors.grey7),
                          ),
                ),
                CommentSortMenu(
                  current: cubit.currentSort,
                  onChanged: (option) => _changeSort(context, option),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        BlocBuilder<CommentsCubit, CommentsState>(
          buildWhen:
              (previous, current) =>
                  current is CommentsListLoading ||
                  current is CommentsListLoaded ||
                  current is CommentOptimisticAdded ||
                  current is CommentTempIdResolved ||
                  current is CommentsUiChanged,
          builder: (context, state) {
            final cubit = context.read<CommentsCubit>();
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child:
                  cubit.isLoadingComments
                      ? const Padding(
                        key: ValueKey('inline_comments_loading'),
                        padding: EdgeInsets.zero,
                        child: CommentsShimmerSkeleton(),
                      )
                      : CommentsSection(
                        key: ValueKey(
                          'inline_comments_${cubit.currentSort.name}',
                        ),
                        postId: post.id,
                        postAuthorId: post.authorId,
                        comments: cubit.comments,
                        onReplyTap: onReplyTap,
                        onEditTap: onEditTap,
                      ),
            );
          },
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}
