import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/services/comments_service.dart';
import 'package:social_media_app/features/comments/widget/send_comment_section.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../comments/helper/editing_comment_banner.dart';
import '../../comments/helper/replying_to_banner.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../reels/widgets/shared_reel_preview_card.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../helper/header_trailing_action.dart';
import '../model/post_model.dart';
import '../widgets/post_header_widget.dart';
import '../widgets/post_reactions_inline_list.dart';
import '../widgets/post_txt_content_widget.dart';
import '../widgets/post_media_widget.dart';
import '../widgets/post_interactions_row.dart';
import '../../comments/widget/comments_inline_section.dart';
import '../widgets/shared_post_header_widget.dart';

enum DetailsViewState { none, comments, reactions }

class PostDetailsView extends StatefulWidget {
  final PostModel post;
  final DetailsViewState initialViewState;

  const PostDetailsView({
    super.key,
    required this.post,
    this.initialViewState = DetailsViewState.comments,
  });

  @override
  State<PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  late final CommentsCubit _commentsCubit;

  late DetailsViewState _viewState;
  bool _commentsLoaded = false;

  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  CommentModel? _editingComment;

  @override
  void initState() {
    super.initState();

    _viewState = widget.initialViewState;

    _commentsCubit = CommentsCubit(
      commentsService: context.read<CommentsService>(),
      currentUserData: context.read<HomeCubit>().currentUserData,
    );

    if (_viewState == DetailsViewState.comments) {
      _commentsLoaded = true;
      _commentsCubit.loadComments(postId: widget.post.id);
    }
  }

  @override
  void dispose() {
    _commentsCubit.close();
    super.dispose();
  }

  void _toggleView(DetailsViewState target) {
    setState(() {
      _viewState = _viewState == target ? DetailsViewState.none : target;
    });

    if (_viewState == DetailsViewState.comments && !_commentsLoaded) {
      _commentsLoaded = true;
      _commentsCubit.loadComments(postId: widget.post.id);
    }
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

  void _startEdit(CommentModel comment) {
    setState(() {
      _editingComment = comment;
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingComment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = SupabaseProvider.id;
    final postsCubit = context.read<PostsCubit>();

    return BlocProvider.value(
      value: _commentsCubit,
      child: BlocListener<CommentsCubit, CommentsState>(
        listener: (context, state) {
          if (state is CommentTempIdResolved) {
            _cancelReply();
          }
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: BlocBuilder<PostsCubit, PostsState>(
              buildWhen: (previous, current) {
                if (previous is PostsLoaded && current is PostsLoaded) {
                  final oldPost = previous.posts.firstWhere(
                    (p) => p.id == widget.post.id,
                  );
                  final newPost = current.posts.firstWhere(
                    (p) => p.id == widget.post.id,
                  );
                  return oldPost != newPost;
                }
                return false;
              },
              builder: (context, state) {
                PostModel currentPost = widget.post;
                if (state is PostsLoaded) {
                  try {
                    currentPost = state.posts.firstWhere(
                      (p) => p.id == widget.post.id,
                    );
                  } catch (_) {}
                }

                final bool isSharedPost = currentPost.isSharedPost;
                final PostModel? displayPost =
                    isSharedPost ? currentPost.originalPost : currentPost;

                if (isSharedPost && displayPost == null) {
                  return const Center(child: Text('Content not available'));
                }

                final bool isSharedReel = displayPost!.isSharedReel;

                return Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isSharedReel) ...[
                                    SharedPostHeaderWidget(
                                      sharedPost: currentPost,
                                      currentUserId: currentUserId,
                                      postsCubit: postsCubit,
                                      contentLabel: 'a reel',
                                      trailingAction:
                                          HeaderTrailingAction.closeScreen,
                                    ),
                                    const Gap(12),
                                  ],
                                  if (isSharedReel &&
                                      displayPost.sharedReel != null)
                                    SharedReelPreviewCard(
                                      reel: displayPost.sharedReel!,
                                    )
                                  else ...[
                                    PostHeaderWidget(
                                      post: displayPost,
                                      currentUserId: currentUserId,
                                      postsCubit: postsCubit,
                                      trailingAction:
                                          HeaderTrailingAction.closeScreen,
                                    ),
                                    const Gap(12),
                                    PostTxtContentWidget(post: displayPost),
                                    const Gap(8),

                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: PostMediaWidget(post: displayPost),
                                    ),
                                  ],

                                  const Gap(16),
                                  PostInteractionsRow(
                                    postId: displayPost.id,
                                    onCommentsTap:
                                        () => _toggleView(
                                          DetailsViewState.comments,
                                        ),
                                    onReactionsTap:
                                        () => _toggleView(
                                          DetailsViewState.reactions,
                                        ),
                                  ),

                                  const Gap(16),
                                  Divider(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                    thickness: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: switch (_viewState) {
                                DetailsViewState.comments =>
                                  CommentsInlineSection(
                                    postId: currentPost.id,
                                    onReplyTap: _startReply,
                                    onEditTap: _startEdit,
                                  ),
                                DetailsViewState.reactions =>
                                  PostReactionsInlineList(
                                    postId: currentPost.id,
                                  ),
                                DetailsViewState.none =>
                                  const SizedBox.shrink(),
                              },
                            ),
                          ),

                          const SliverToBoxAdapter(child: Gap(24)),
                        ],
                      ),
                    ),

                    if (_viewState == DetailsViewState.comments)
                      _CommentComposerBar(
                        post: currentPost,
                        replyingToCommentId: _replyingToCommentId,
                        replyingToAuthorName: _replyingToAuthorName,
                        editingComment: _editingComment,
                        onCancelReply: _cancelReply,
                        onCancelEdit: _cancelEdit,
                        onReplySent: () {
                          setState(() {
                            _replyingToCommentId = null;
                            _replyingToAuthorName = null;
                          });
                        },
                        onEditSaved: _cancelEdit,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentComposerBar extends StatelessWidget {
  final PostModel post;
  final String? replyingToCommentId;
  final String? replyingToAuthorName;
  final CommentModel? editingComment;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;
  final VoidCallback onReplySent;
  final VoidCallback onEditSaved;

  const _CommentComposerBar({
    required this.post,
    required this.replyingToCommentId,
    required this.replyingToAuthorName,
    required this.editingComment,
    required this.onCancelReply,
    required this.onCancelEdit,
    required this.onReplySent,
    required this.onEditSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (replyingToCommentId != null)
              ReplyingToBanner(
                authorName: replyingToAuthorName ?? '',
                onCancel: onCancelReply,
              ),
            if (editingComment != null)
              EditingCommentBanner(
                commentText: editingComment!.text,
                onCancel: onCancelEdit,
              ),
            SendCommentSection(
              post: post,
              replyingToCommentId: replyingToCommentId,
              replyingToAuthorName: replyingToAuthorName,
              onReplySent: onReplySent,
              editingComment: editingComment,
              onEditSaved: onEditSaved,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
