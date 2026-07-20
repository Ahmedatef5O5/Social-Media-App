import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
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
import '../../posts/widgets/post_reactions_bottom_sheet.dart';
import '../helper/comment_sheet_shared_widgets.dart';
import '../helper/comments_count_skeleton.dart';
import '../helper/editing_comment_banner.dart';
import '../helper/reactor_avatar_stack.dart';
import '../helper/replying_to_banner.dart';
import 'send_comment_section.dart';

class CommentsSheetSection extends StatefulWidget {
  final String postId;

  const CommentsSheetSection({super.key, required this.postId});

  @override
  State<CommentsSheetSection> createState() => _CommentsSheetSectionState();
}

class _CommentsSheetSectionState extends State<CommentsSheetSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CommentsCubit>().loadComments(postId: widget.postId);
    });
  }

  final ScrollController _scrollController = ScrollController();

  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _isNearBottom([double threshold = 120]) {
    if (!_scrollController.hasClients) return false;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels < threshold;
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

  CommentModel? _editingComment;
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    return BlocListener<CommentsCubit, CommentsState>(
      listener: (context, state) {
        if (state is CommentOptimisticAdded) {
          if (_isNearBottom()) {
            _scrollToBottom();
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
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(left: 150, right: 150),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (post.reactions.isNotEmpty) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder:
                                    (context) => PostReactionsBottomSheet(
                                      postId: post.id,
                                    ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,

                            children: [
                              Text(
                                '${post.likes?.length ?? 0} Reactions',
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(color: AppColors.grey7),
                              ),
                              Gap(12),
                              ReactorsAvatarStack(
                                imageUrls: post.likersImages ?? [],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<CommentsCubit, CommentsState>(
                          buildWhen:
                              (previous, current) =>
                                  current is CommentsListLoading ||
                                  current is CommentsListLoaded ||
                                  current is CommentOptimisticAdded ||
                                  current is CommentTempIdResolved || 
                                  current is CommentsUiChanged ,

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
                                            key: ValueKey('count_skeleton'),
                                          )
                                          : Text(
                                            key: const ValueKey('count_text'),
                                            '${countAllComments(cubit.comments)} Comments',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium!.copyWith(
                                              color: AppColors.grey7,
                                            ),
                                          ),
                                ),
                                CommentSortMenu(
                                  current: cubit.currentSort,
                                  onChanged: _changeSort,
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
                                      ? Padding(
                                        key: ValueKey('comments_loading'),
                                        padding: EdgeInsets.zero,
                                        child: CommentsShimmerSkeleton(),
                                      )
                                      : CommentsSection(
                                        key: ValueKey(
                                          'comments_${cubit.currentSort.name}',
                                        ),
                                        postId: post.id,
                                        postAuthorId: post.authorId,
                                        comments: cubit.comments,
                                        onReplyTap: _startReply,
                                        onEditTap: _startEdit,
                                      ),
                            );
                          },
                        ),
                      ],
                    ),
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
                Row(
                  children: [
                    Expanded(
                      child: SendCommentSection(
                        post: post,
                        replyingToCommentId: _replyingToCommentId,
                        replyingToAuthorName: _replyingToAuthorName,
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
