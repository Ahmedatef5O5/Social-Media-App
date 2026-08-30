import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/comments/cubits/comments_cubit.dart';
import 'package:social_media_app/features/comments/services/comments_service.dart';
import 'package:social_media_app/features/posts/widgets/post_reactions_bottom_sheet.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/deep_link/services/deep_link_service.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/share_intent/widgets/share_content_bottom_sheet.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../models/post_model.dart';
import '../../comments/widgets/comments_sheet_section.dart';
import 'post_reaction_overlay.dart';
import 'post_reactions_summary.dart';

class PostInteractionsRow extends StatelessWidget {
  final String postId;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onReactionsTap;

  const PostInteractionsRow({
    super.key,
    required this.postId,
    this.onCommentsTap,
    this.onReactionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsCubit, PostsState>(
      buildWhen: (prev, curr) {
        if (curr is! PostsLoaded) return false;

        if (prev is! PostsLoaded) return true;

        final oldPost = prev.posts.findById(postId);
        final newPost = curr.posts.findById(postId);
        if (oldPost == null || newPost == null) return true;
        if (identical(oldPost, newPost)) return false;

        return countAllComments(oldPost.comments) !=
                countAllComments(newPost.comments) ||
            (oldPost.likes?.length ?? 0) != (newPost.likes?.length ?? 0) ||
            oldPost.myReactionEmoji != newPost.myReactionEmoji ||
            oldPost.sharesCount != newPost.sharesCount ||
            oldPost.isSharedByMe != newPost.isSharedByMe ||
            oldPost.savedCount != newPost.savedCount ||
            oldPost.isSavedByMe != newPost.isSavedByMe ||
            oldPost.isOnline != newPost.isOnline;
      },
      builder: (context, state) {
        if (state is! PostsLoaded) {
          return const SizedBox.shrink();
        }

        final post = state.posts.findById(postId);
        if (post == null) return const SizedBox.shrink();

        final totalComments = countAllComments(post.comments);

        return _InteractionsContent(
          post: post,
          totalComments: totalComments,
          onCommentsTap: onCommentsTap,
          onReactionsTap: onReactionsTap,
        );
      },
    );
  }
}

class _InteractionsContent extends StatelessWidget {
  final PostModel post;
  final int totalComments;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onReactionsTap;

  const _InteractionsContent({
    required this.post,
    required this.totalComments,
    this.onCommentsTap,
    this.onReactionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final currUserId = homeCubit.currentUserData?.id;

    return Column(
      children: [
        const Gap(12),
        Row(
          children: [
            const Gap(16),

            _LikeButtonWidget(
              post: post,
              currUserId: currUserId,
              onReactionsTap: onReactionsTap,
            ),

            const Gap(22), // مسافة ثابتة ومتقاربة

            _CommentButtonWidget(
              post: post,
              totalComments: totalComments,
              onTap: onCommentsTap,
            ),

            const Gap(22), // مسافة ثابتة ومتقاربة

            _ReshareButtonWidget(post: post),

            const Gap(22), // مسافة ثابتة ومتقاربة

            _ShareLinkButtonWidget(post: post),

            const Spacer(), // Spacer وحيد لملء الفراغ ودفع زر الحفظ لليمين

            _SaveButtonWidget(post: post),

            const Gap(16),
          ],
        ),
        const Gap(8),
      ],
    );
  }
}

class _LikeButtonWidget extends StatefulWidget {
  final PostModel post;
  final String? currUserId;
  final VoidCallback? onReactionsTap;

  const _LikeButtonWidget({
    required this.post,
    required this.currUserId,
    this.onReactionsTap,
  });

  @override
  State<_LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<_LikeButtonWidget>
    with SingleTickerProviderStateMixin {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _pressed = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.5,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissPicker();
    super.dispose();
  }

  void _showPicker(PostModel currentPost) {
    if (_overlayEntry != null) return;

    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    _overlayEntry = PostReactionOverlay.create(
      context: context,
      anchorRect: offset & renderBox.size,
      selectedEmoji: currentPost.myReactionEmoji,
      onSelect: (emoji) {
        _dismissPicker();
        _handleReactionTap(currentPost, emoji);
      },
      onDismiss: _dismissPicker,
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleReactionTap(PostModel currentPost, String emoji) {
    _animationController.forward(from: 0.0);
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    context.read<PostsCubit>().toggleReaction(currentPost, emoji: emoji);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PostsCubit>().state;

    final currentPost =
        (state is PostsLoaded)
            ? state.posts.findById(widget.post.id) ?? widget.post
            : widget.post;

    final String? myReaction = currentPost.myReactionEmoji;
    final bool isDefaultLike = myReaction == null || myReaction == 'like';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: _anchorKey,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            setState(() => _pressed = false);
            _handleReactionTap(currentPost, myReaction ?? 'like');
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showPicker(currentPost);
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedScale(
              scale: _pressed ? 0.85 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child:
                  isDefaultLike
                      ? Icon(
                        myReaction == 'like'
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        color:
                            myReaction == 'like'
                                ? Theme.of(context).primaryColor
                                : AppColors.grey6,
                        size: 24,
                      )
                      : Text(
                        myReaction,
                        style: TextStyle(
                          inherit: false,
                          fontSize: 22,
                          fontFamilyFallback: AppTypography.emojiFontFallback,
                        ),
                      ),
            ),
          ),
        ),
        const Gap(6),
        GestureDetector(
          onTap: () {
            if (currentPost.reactions.isNotEmpty) {
              if (widget.onReactionsTap != null) {
                widget.onReactionsTap!.call();
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder:
                      (context) =>
                          PostReactionsBottomSheet(postId: currentPost.id),
                );
              }
            }
          },

          child: PostReactionsSummary(reactions: currentPost.reactions),
        ),
      ],
    );
  }
}

class _CommentButtonWidget extends StatelessWidget {
  final PostModel post;
  final int totalComments;
  final VoidCallback? onTap;

  const _CommentButtonWidget({
    required this.post,
    required this.totalComments,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final postsCubit = context.read<PostsCubit>();

        if (postsCubit.isPostGhost(post.id)) {
          AppToast.info('This post is no longer available.');
          return;
        }

        if (onTap != null) {
          onTap!.call();
          return;
        }
        final commentsCubit = CommentsCubit(
          commentsService: context.read<CommentsService>(),
          mediaCacheRepository: context.read<MediaCacheRepository>(),
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
                  BlocProvider.value(value: postsCubit),
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

          if (totalComments > 0) ...[
            const Gap(4),
            Text(
              '$totalComments',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReshareButtonWidget extends StatefulWidget {
  const _ReshareButtonWidget({required this.post});

  final PostModel post;

  @override
  State<_ReshareButtonWidget> createState() => _ReshareButtonWidgetState();
}

class _ReshareButtonWidgetState extends State<_ReshareButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(PostModel currentPost) async {
    _animationController.forward(from: 0.0);
    HapticFeedback.lightImpact();

    final primaryColor = Theme.of(context).primaryColor;
    final postsCubit = context.read<PostsCubit>();
    final bool wasShared = currentPost.isSharedByMe;

    final bool success = await postsCubit.toggleSharePost(currentPost);

    if (success) {
      AppToast.save(
        wasShared ? 'Reshare removed' : 'Reshared successfully',
        icon: Icons.repeat_rounded,
        iconColor: wasShared ? AppColors.grey5 : primaryColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PostsCubit>().state;
    final currentPost =
        (state is PostsLoaded)
            ? state.posts.findById(widget.post.id) ?? widget.post
            : widget.post;

    final bool isShared = currentPost.isSharedByMe;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(currentPost),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder:
                  (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
              child: Icon(
                CupertinoIcons.arrow_2_squarepath,
                key: ValueKey(isShared),
                color:
                    isShared ? Theme.of(context).primaryColor : AppColors.grey6,
                size: 24,
              ),
            ),
          ),
          if (currentPost.sharesCount > 0) ...[
            const Gap(4),
            Text(
              '${currentPost.sharesCount}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isShared ? Theme.of(context).primaryColor : null,
                fontWeight: isShared ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareLinkButtonWidget extends StatelessWidget {
  const _ShareLinkButtonWidget({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PostsCubit>().state;
    final currentPost =
        (state is PostsLoaded) ? state.posts.findById(post.id) ?? post : post;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        final url = DeepLinkService.urlForPost(currentPost.id);
        ShareContentBottomSheet.show(
          context,
          url: url,
          shareText: 'Check out this post on Social Media App: $url',
          onShared:
              () => context.read<PostsCubit>().incrementLinkShareCount(
                currentPost.id,
              ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.paperplane, color: AppColors.grey6, size: 22),
          if (currentPost.linkShareCount > 0) ...[
            const Gap(4),
            Text(
              '${currentPost.linkShareCount}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveButtonWidget extends StatefulWidget {
  final PostModel post;

  const _SaveButtonWidget({required this.post});

  @override
  State<_SaveButtonWidget> createState() => _SaveButtonWidgetState();
}

class _SaveButtonWidgetState extends State<_SaveButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(PostModel currentPost) async {
    _animationController.forward(from: 0.0);
    HapticFeedback.lightImpact();

    final bool wasSaved = currentPost.isSavedByMe;
    final bool success = await context.read<PostsCubit>().toggleSavePost(
      currentPost,
    );

    if (success) {
      AppToast.save(
        icon: wasSaved ? Icons.bookmark_remove_rounded : Icons.bookmark_rounded,
        wasSaved ? 'Post removed from saves' : 'Post saved successfully',
        iconColor: wasSaved ? AppColors.grey5 : AppColors.goldenYellow,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PostsCubit>().state;
    final currentPost =
        (state is PostsLoaded)
            ? state.posts.findById(widget.post.id) ?? widget.post
            : widget.post;

    final bool isSaved = currentPost.isSavedByMe;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(currentPost),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder:
                  (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey(isSaved),
                color: isSaved ? AppColors.goldenYellow : AppColors.grey6,
                size: 24,
              ),
            ),
          ),
          if (currentPost.savedCount > 0) ...[
            const Gap(4),
            Text(
              '${currentPost.savedCount}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSaved ? AppColors.goldenYellow : null,
                fontWeight: isSaved ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
