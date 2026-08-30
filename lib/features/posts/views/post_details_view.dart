import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/comments/cubits/comments_cubit.dart';
import 'package:social_media_app/features/comments/models/comment_model.dart';
import 'package:social_media_app/features/comments/services/comments_service.dart';
import 'package:social_media_app/features/comments/widgets/send_comment_section.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../comments/helpers/editing_comment_banner.dart';
import '../../comments/helpers/replying_to_banner.dart';
import '../../comments/models/comment_sort_option.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../reels/widgets/shared_reel_preview_card.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../helpers/header_trailing_action.dart';
import '../models/post_model.dart';
import '../widgets/post_header_widget.dart';
import '../widgets/post_reactions_inline_list.dart';
import '../widgets/post_txt_content_widget.dart';
import '../widgets/post_media_widget.dart';
import '../widgets/post_interactions_row.dart';
import '../../comments/widgets/comments_inline_section.dart';
import '../widgets/shared_post_header_widget.dart';

enum PostDetailsActiveMode { none, comments, reactions }

class PostDetailsView extends StatefulWidget {
  final PostModel post;
  final PostDetailsActiveMode initialActiveMode;

  const PostDetailsView({
    super.key,
    required this.post,
    this.initialActiveMode = PostDetailsActiveMode.comments,
  });

  @override
  State<PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  late final CommentsCubit _commentsCubit;
  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey _commentsTopKey = GlobalKey();
  late PostDetailsActiveMode _activeMode;
  bool _commentsLoaded = false;

  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  CommentModel? _editingComment;

  @override
  void initState() {
    super.initState();

    _activeMode = widget.initialActiveMode;

    _commentsCubit = CommentsCubit(
      commentsService: context.read<CommentsService>(),
      mediaCacheRepository: context.read<MediaCacheRepository>(),
      currentUserData: context.read<HomeCubit>().currentUserData,
    );

    if (_activeMode == PostDetailsActiveMode.comments) {
      _commentsLoaded = true;
      _commentsCubit.loadComments(postId: widget.post.id);
    }
  }

  @override
  void dispose() {
    _commentsCubit.close();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _toggleView(PostDetailsActiveMode target) {
    setState(() {
      _activeMode = _activeMode == target ? PostDetailsActiveMode.none : target;
    });

    if (_activeMode == PostDetailsActiveMode.comments && !_commentsLoaded) {
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
          if (state is CommentOptimisticAdded &&
              _activeMode == PostDetailsActiveMode.comments) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_mainScrollController.hasClients) {
                final cubit = context.read<CommentsCubit>();

                if (cubit.currentSort == CommentSortOption.oldest) {
                  _mainScrollController.animateTo(
                    _mainScrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  if (_commentsTopKey.currentContext != null) {
                    Scrollable.ensureVisible(
                      _commentsTopKey.currentContext!,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: 0.0,
                    );
                  }
                }
              }
            });
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
                  } catch (e) {
                    debugPrint(
                      '[PostDetailsView] post lookup failed, falling back to widget.post: $e',
                    );
                  }
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
                        controller: _mainScrollController,
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
                                      child: PostMediaWidget(
                                        post: displayPost,
                                        postsCubit: postsCubit,
                                        currentUserId: currentUserId,
                                      ),
                                    ),
                                  ],

                                  const Gap(16),
                                  PostInteractionsRow(
                                    postId: displayPost.id,
                                    onCommentsTap:
                                        () => _toggleView(
                                          PostDetailsActiveMode.comments,
                                        ),
                                    onReactionsTap:
                                        () => _toggleView(
                                          PostDetailsActiveMode.reactions,
                                        ),
                                  ),

                                  const Gap(16),
                                  Divider(
                                    key: _commentsTopKey,
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
                              child: switch (_activeMode) {
                                PostDetailsActiveMode.comments =>
                                  CommentsInlineSection(
                                    postId: currentPost.id,
                                    onReplyTap: _startReply,
                                    onEditTap: _startEdit,
                                  ),
                                PostDetailsActiveMode.reactions =>
                                  PostReactionsInlineList(
                                    postId: currentPost.id,
                                  ),
                                PostDetailsActiveMode.none =>
                                  const SizedBox.shrink(),
                              },
                            ),
                          ),

                          const SliverToBoxAdapter(child: Gap(24)),
                        ],
                      ),
                    ),

                    if (_activeMode == PostDetailsActiveMode.comments)
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
