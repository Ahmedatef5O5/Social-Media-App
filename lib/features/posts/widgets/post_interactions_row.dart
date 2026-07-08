import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/posts/cubit/posts_cubit.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../model/post_model.dart';
import '../../home/services/home_services.dart';
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

            const _SaveButtons(),

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

class _LikeButtonWidgetState extends State<_LikeButtonWidget> {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _pressed = false;

  @override
  void dispose() {
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
        HapticFeedback.selectionClick();
        context.read<PostsCubit>().toggleReaction(currentPost, emoji: emoji);
      },
      onDismiss: _dismissPicker,
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final postsCubit = context.read<PostsCubit>();
    final state = context.watch<PostsCubit>().state;

    final currentPost =
        (state is PostsLoaded)
            ? state.posts.firstWhere((p) => p.id == widget.post.id)
            : widget.post;

    final String? myReaction = currentPost.myReactionEmoji;
    final bool isDefaultLike = myReaction == null || myReaction == 'like';

    return GestureDetector(
      key: _anchorKey,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        postsCubit.toggleReaction(currentPost, emoji: myReaction ?? 'like');
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showPicker(currentPost);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _pressed ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 120),
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
                    : Text(myReaction, style: const TextStyle(fontSize: 22)),
          ),
          const Gap(6),
          PostReactionsSummary(reactions: currentPost.reactions),
        ],
      ),
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
        final homeServices = HomeServices.instance;
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
