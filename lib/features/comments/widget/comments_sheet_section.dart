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
import '../helper/editing_comment_banner.dart';
import '../helper/replying_to_banner.dart';
import 'send_comment_section.dart';
import 'ai_comment_suggestions_row.dart';
import 'package:social_media_app/core/mentions/mentions.dart';

class CommentsSheetSection extends StatefulWidget {
  final String postId;

  const CommentsSheetSection({super.key, required this.postId});

  @override
  State<CommentsSheetSection> createState() => _CommentsSheetSectionState();
}

class _CommentsSheetSectionState extends State<CommentsSheetSection> {
  ScrollController? _scrollController;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  MentionTextEditingController? _commentController;
  CommentModel? _editingComment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CommentsCubit>().loadComments(postId: widget.postId);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController?.hasClients ?? false) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController?.hasClients ?? false) {
        _scrollController!.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
      _editingComment = null;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  void _changeSort(CommentSortOption option) {
    final cubit = context.read<CommentsCubit>();
    if (cubit.currentSort == option) return;
    cubit.loadComments(postId: widget.postId, sort: option);
  }

  void _startEdit(CommentModel comment) {
    setState(() {
      _editingComment = comment;
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  void _cancleEdit() {
    setState(() {
      _editingComment = null;
    });
  }

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
      return const SizedBox(height: 300, child: CustomLoadingIndicator());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return BlocListener<CommentsCubit, CommentsState>(
      listener: (context, state) {
        if (state is CommentOptimisticAdded) {
          final cubit = context.read<CommentsCubit>();
          if (cubit.currentSort == CommentSortOption.oldest) {
            _scrollToBottom();
          } else {
            _scrollToTop();
          }
        }

        if (state is CommentTempIdResolved) {
          _cancelReply();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.96,
              expand: false,
              builder: (context, scrollController) {
                _scrollController = scrollController;

                return Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: BlocBuilder<CommentsCubit, CommentsState>(
                          buildWhen: (previous, current) =>
                              current is CommentsListLoading ||
                              current is CommentsListLoaded ||
                              current is CommentOptimisticAdded ||
                              current is CommentTempIdResolved ||
                              current is CommentsUiChanged,
                          builder: (context, state) {
                            final cubit = context.read<CommentsCubit>();
                            final commentsCount = countAllComments(cubit.comments);

                            return CustomScrollView(
                              controller: scrollController,
                              physics: const ClampingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),

                                      Center(
                                        child: Container(
                                          height: 4,
                                          width: 40,
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white24 : Colors.black12,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: cubit.isLoadingComments
                                                  ? Shimmer.fromColors(
                                                      key: const ValueKey('badge_shimmer'),
                                                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                                      highlightColor: isDark ? Colors.grey[700]! : Colors.white,
                                                      child: Container(
                                                        width: 28,
                                                        height: 24,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      key: const ValueKey('badge_real'),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[200],
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
                                                    ),
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
                                                    builder: (context) => PostReactionsBottomSheet(
                                                      postId: post.id,
                                                    ),
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
                                              onChanged: _changeSort,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: AiCommentSuggestionsRow(
                                          postId: post.id,
                                          postText: post.text,
                                          onChipSelected: (text) {
                                            _commentController?.text = text;
                                            _commentController?.selection = TextSelection.collapsed(
                                              offset: text.length,
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 14),
                                    ],
                                  ),
                                ),

                                if (cubit.isLoadingComments)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: CommentsShimmerSkeleton(),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: CommentsSection(
                                      key: ValueKey('comments_${cubit.currentSort.name}'),
                                      postId: post.id,
                                      postAuthorId: post.authorId,
                                      comments: cubit.comments,
                                      onReplyTap: _startReply,
                                      onEditTap: _startEdit,
                                    ),
                                  ),

                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 16),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      if (_replyingToCommentId != null)
                        ReplyingToBanner(
                          authorName: _replyingToAuthorName ?? '',
                          onCancel: _cancelReply,
                        ),

                      if (_editingComment != null)
                        EditingCommentBanner(
                          commentText: _editingComment!.text,
                          onCancel: _cancleEdit,
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SendCommentSection(
                                post: post,
                                replyingToCommentId: _replyingToCommentId,
                                replyingToAuthorName: _replyingToAuthorName,
                                onControllerReady: (controller) => _commentController = controller,
                                onReplySent: () {
                                  setState(() {
                                    _replyingToCommentId = null;
                                    _replyingToAuthorName = null;
                                  });
                                },
                                editingComment: _editingComment,
                                onEditSaved: _cancleEdit,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}