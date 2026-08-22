import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/model/comment_sort_option.dart';
import 'package:social_media_app/features/comments/widget/comments_shimmer_skeleton.dart';
import 'package:social_media_app/features/posts/cubit/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/model/post_model.dart';
import 'package:social_media_app/features/comments/widget/comments_section.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../posts/widgets/post_reactions_bottom_sheet.dart';
import '../helper/comment_sheet_shared_widgets.dart';
import '../helper/comments_reaction_avatar_stack.dart';

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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

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
            final commentsCount = countAllComments(cubit.comments);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:
                      cubit.isLoadingComments
                          ? Shimmer.fromColors(
                            key: const ValueKey('badge_shimmer'),
                            baseColor:
                                isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            highlightColor:
                                isDark ? Colors.grey[700]! : Colors.white,
                            child: Container(
                              width: 28,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                          : (commentsCount > 0)
                          ? Container(
                            key: const ValueKey('badge_real'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? colorScheme.surfaceContainerHighest
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$commentsCount',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          )
                          : SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Comments',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 12),
                if (post.reactions.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (context) =>
                                PostReactionsBottomSheet(postId: post.id),
                      );
                    },
                    child: CommentsReactionAvatarStack(
                      imageUrls: post.likersImages ?? [],
                      totalReactions: post.likes?.length ?? 0,
                      reactions: post.reactions,
                    ),
                  ),
                const Spacer(),
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
                      : CustomScrollView(
                        key: ValueKey(
                          'inline_comments_${cubit.currentSort.name}',
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        slivers: [
                          CommentsSection(
                            postId: post.id,
                            postAuthorId: post.authorId,
                            comments: cubit.comments,
                            onReplyTap: onReplyTap,
                            onEditTap: onEditTap,
                          ),
                        ],
                      ),
            );
          },
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}
