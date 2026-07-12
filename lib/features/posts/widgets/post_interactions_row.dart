import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/services/comments_service.dart';
import 'package:social_media_app/features/posts/cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/widgets/post_reactions_bottom_sheet.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../model/post_model.dart';
import '../../comments/widget/comments_sheet_section.dart';
import 'post_reaction_overlay.dart';
import 'post_reactions_summary.dart';

class PostInteractionsRow extends StatelessWidget {
  const PostInteractionsRow({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsCubit, PostsState>(
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

            _SaveButtonWidget(post: post),

            const Gap(12),
          ],
        ),
        const Gap(8),
      ],
    );
  }
}

class _LikeButtonWidget extends StatefulWidget {
  const _LikeButtonWidget({required this.post, required this.currUserId});

  final PostModel post;
  final String? currUserId;

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
            ? state.posts.firstWhere((p) => p.id == widget.post.id)
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
                          fontSize: 22,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 1.0) ??
                              Colors.black,
                        ),
                      ),
            ),
          ),
        ),
        const Gap(6),
        GestureDetector(
          onTap: () {
            if (currentPost.reactions.isNotEmpty) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (context) =>
                        PostReactionsBottomSheet(postId: currentPost.id),
              );
            }
          },

          child: PostReactionsSummary(reactions: currentPost.reactions),
        ),
      ],
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
        final postsCubit = context.read<PostsCubit>();
        final commentsCubit = CommentsCubit(
          commentsService: context.read<CommentsService>(),
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
    return GestureDetector(
      onTap: () => AppToast.info('this feature is coming soon'),
      child: Row(
        children: [Image.asset(AppImages.sharePostIcon, width: 24, height: 24)],
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

  void _handleTap(PostModel currentPost) {
    _animationController.forward(from: 0.0);
    HapticFeedback.lightImpact();

    final bool wasSaved = currentPost.isSavedByMe;

    context.read<PostsCubit>().toggleSavePost(currentPost);
    AppToast.save(
      icon: wasSaved ? Icons.bookmark_remove_rounded : Icons.bookmark_rounded,
      wasSaved ? 'Post removed from saves' : 'Post saved successfully',
      iconColor: wasSaved ? AppColors.grey5 : AppColors.goldenYellow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PostsCubit>().state;
    final currentPost =
        (state is PostsLoaded)
            ? state.posts.firstWhere(
              (p) => p.id == widget.post.id,
              orElse: () => widget.post,
            )
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
