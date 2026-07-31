import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/posts/helper/full_screen_video_actions.dart';
import 'package:video_player/video_player.dart';

import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../comments/cubit/comments_cubit.dart';
import '../../comments/services/comments_service.dart';
import '../../comments/widget/comments_sheet_section.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../model/post_model.dart';
import '../widgets/post_reaction_overlay.dart';

class RightInteractionsPostVideoColumn extends StatefulWidget {
  final PostModel post;
  final PostsCubit postsCubit;
  final VideoPlayerController videoController;

  const RightInteractionsPostVideoColumn({
    super.key,
    required this.post,
    required this.postsCubit,
    required this.videoController,
  });

  @override
  State<RightInteractionsPostVideoColumn> createState() =>
      _RightInteractionsPostVideoColumnState();
}

class _RightInteractionsPostVideoColumnState
    extends State<RightInteractionsPostVideoColumn> {
  final GlobalKey _likeAnchorKey = GlobalKey();
  OverlayEntry? _reactionOverlay;

  @override
  void dispose() {
    _dismissReactionPicker();
    super.dispose();
  }

  void _showReactionPicker(PostModel currentPost) {
    if (_reactionOverlay != null) return;

    final renderBox =
        _likeAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    _reactionOverlay = PostReactionOverlay.create(
      context: context,
      anchorRect: offset & renderBox.size,
      selectedEmoji: currentPost.myReactionEmoji,
      bubbleWidth: 320,
      onSelect: (emoji) {
        _dismissReactionPicker();
        HapticFeedback.lightImpact();
        widget.postsCubit.toggleReaction(currentPost, emoji: emoji);
      },
      onDismiss: _dismissReactionPicker,
    );

    Overlay.of(context).insert(_reactionOverlay!);
  }

  void _dismissReactionPicker() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
  }

  void _openComments(PostModel post) {
    if (widget.postsCubit.isPostGhost(post.id)) {
      AppToast.info('This post is no longer available.');
      return;
    }
    final bool wasPlaying = widget.videoController.value.isPlaying;
    if (wasPlaying) widget.videoController.pause();

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
              BlocProvider.value(value: widget.postsCubit),
              BlocProvider.value(value: commentsCubit),
            ],
            child: CommentsSheetSection(postId: post.id),
          ),
    ).whenComplete(() {
      commentsCubit.resetCollapsedComments();
      if (wasPlaying && widget.videoController.value.isInitialized) {
        widget.videoController.play();
      }
    });
  }

  Future<void> _toggleReshare(PostModel post) async {
    HapticFeedback.lightImpact();
    final bool wasShared = post.isSharedByMe;
    final bool success = await widget.postsCubit.toggleSharePost(post);
    if (success) {
      AppToast.save(
        wasShared ? 'Share removed' : 'Shared successfully',
        icon: Icons.repeat_rounded,
      );
    }
  }

  Future<void> _toggleSave(PostModel post) async {
    HapticFeedback.lightImpact();
    final bool wasSaved = post.isSavedByMe;
    final bool success = await widget.postsCubit.toggleSavePost(post);
    if (success) {
      AppToast.save(
        wasSaved ? 'Post removed from saves' : 'Post saved successfully',
        icon: wasSaved ? Icons.bookmark_remove_rounded : Icons.bookmark_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsCubit, PostsState>(
      bloc: widget.postsCubit,
      buildWhen: (prev, curr) => prev is PostsLoaded && curr is PostsLoaded,
      builder: (context, state) {
        final currentPost =
            (state is PostsLoaded)
                ? state.posts.findById(widget.post.id) ?? widget.post
                : widget.post;

        final String? myReaction = currentPost.myReactionEmoji;
        final bool isLiked = myReaction != null;
        final int totalComments = countAllComments(currentPost.comments);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              key: _likeAnchorKey,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.postsCubit.toggleReaction(
                  currentPost,
                  emoji: myReaction ?? 'like',
                );
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showReactionPicker(currentPost);
              },
              child: FullScreenVideoActions(
                label: '${currentPost.likesCount}',
                child:
                    isLiked && myReaction != 'like'
                        ? Text(
                          myReaction,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                          ),
                        )
                        : Icon(
                          isLiked
                              ? Icons.thumb_up_alt
                              : Icons.thumb_up_alt_outlined,
                          color:
                              isLiked ? const Color(0xFF1877F2) : Colors.white,
                          size: 32,
                        ),
              ),
            ),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: () => _openComments(currentPost),
              child: FullScreenVideoActions(
                label: '$totalComments',
                child: Image.asset(
                  AppImages.commentAtPostIcon,
                  width: 31,
                  height: 31,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: () => _toggleReshare(currentPost),
              child: FullScreenVideoActions(
                label: '${currentPost.sharesCount}',
                child: Icon(
                  Icons.repeat_rounded,
                  color:
                      currentPost.isSharedByMe
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                  size: 31,
                ),
              ),
            ),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: () => _toggleSave(currentPost),
              child: FullScreenVideoActions(
                label:
                    currentPost.savedCount > 0
                        ? '${currentPost.savedCount}'
                        : null,
                child: Icon(
                  currentPost.isSavedByMe
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color:
                      currentPost.isSavedByMe
                          ? AppColors.goldenYellow
                          : Colors.white,
                  size: 31,
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],
        );
      },
    );
  }
}
