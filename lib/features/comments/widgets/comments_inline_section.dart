import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/comments/cubits/comments_cubit.dart';
import 'package:social_media_app/features/comments/models/comment_model.dart';
import 'package:social_media_app/features/comments/models/comment_sort_option.dart';
import 'package:social_media_app/features/comments/widgets/comments_shimmer_skeleton.dart';
import 'package:social_media_app/features/posts/cubits/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/models/post_model.dart';
import 'package:social_media_app/features/comments/widgets/comments_section.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../posts/widgets/post_reactions_bottom_sheet.dart';
import '../helpers/comment_sheet_shared_widgets.dart';
import '../helpers/comments_reaction_avatar_stack.dart';
import 'ai_comment_suggestions_row.dart';
import 'comment_typing_row.dart';

class CommentsInlineSection extends StatefulWidget {
  final String postId;
  final void Function(String commentId, String authorName)? onReplyTap;
  final void Function(CommentModel)? onEditTap;
  final ValueChanged<String>? onAiSuggestionSelected;

  const CommentsInlineSection({
    super.key,
    required this.postId,
    this.onReplyTap,
    this.onEditTap,
    this.onAiSuggestionSelected,
  });

  @override
  State<CommentsInlineSection> createState() => CommentsInlineSectionState();
}

class CommentsInlineSectionState extends State<CommentsInlineSection> {
  ScrollPosition? _ancestorPosition;

  String? _highlightCommentId;
  final GlobalKey _highlightKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _ancestorPosition) {
      _ancestorPosition?.removeListener(_handleScroll);
      _ancestorPosition = newPosition;
      _ancestorPosition?.addListener(_handleScroll);
    }
  }

  @override
  void dispose() {
    _ancestorPosition?.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    final position = _ancestorPosition;
    if (position == null || !mounted) return;
    final cubit = context.read<CommentsCubit>();
    final bool nearEdge =
        cubit.currentSort == CommentSortOption.oldest
            ? position.pixels >= position.maxScrollExtent - 150
            : position.pixels <= 150;
    cubit.setNearEdge(nearEdge);
  }

  void _changeSort(BuildContext context, CommentSortOption option) {
    final cubit = context.read<CommentsCubit>();
    if (cubit.currentSort == option) return;
    cubit.loadComments(postId: widget.postId, sort: option);
  }

  void _scrollToOwnComment(CommentModel comment, String? parentId) {
    final cubit = context.read<CommentsCubit>();
    if (parentId != null) {
      cubit.expandAncestorsOf(comment.id);
    }
    setState(() => _highlightCommentId = comment.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 75), () {
        if (!mounted) return;
        final targetContext = _highlightKey.currentContext;
        final renderObject = targetContext?.findRenderObject();

        if (renderObject is RenderBox && renderObject.hasSize) {
          Scrollable.ensureVisible(
            targetContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.4,
          ).catchError((_) {});
          return;
        }

        // Target isn't laid out yet — coarse fallback toward where new
        // content appears for the active sort (same as the Sheet).
        final position = _ancestorPosition;
        if (position == null || !position.hasContentDimensions) return;
        position.animateTo(
          cubit.currentSort == CommentSortOption.oldest
              ? position.maxScrollExtent
              : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  void _onPendingCommentsTap() {
    final cubit = context.read<CommentsCubit>();
    final target = cubit.firstPendingComment();
    cubit.mergePendingComments();
    if (target != null) {
      _scrollToOwnComment(target.comment, target.parentId);
    }
  }

  void jumpToNewComments() => _onPendingCommentsTap();

  @override
  Widget build(BuildContext context) {
    final post = context.select<PostsCubit, PostModel?>((cubit) {
      final state = cubit.state;
      if (state is PostsLoaded) {
        try {
          return state.posts.findById(widget.postId);
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

    return BlocListener<CommentsCubit, CommentsState>(
      listener: (context, state) {
        if (state is CommentOptimisticAdded) {
          _scrollToOwnComment(state.comment, state.parentId);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                                  isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!,
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

          const SizedBox(height: 2),

          if (widget.onAiSuggestionSelected != null)
            AiCommentSuggestionsRow(
              post: post,
              margin: const EdgeInsets.only(top: 4, bottom: 6),
              onChipSelected: widget.onAiSuggestionSelected!,
            ),

          const InlineCommentTypingRow(padding: EdgeInsets.zero),
          const SizedBox(height: 3),
          // ----------------------------------------
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
                              onReplyTap: widget.onReplyTap,
                              onEditTap: widget.onEditTap,
                              highlightCommentId: _highlightCommentId,
                              highlightKey: _highlightKey,
                            ),
                          ],
                        ),
              );
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
