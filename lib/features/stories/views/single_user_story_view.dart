import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:story_view/story_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../model/story_model.dart';

class SingleUserStoryView extends StatefulWidget {
  final StoryModel story;
  final HomeCubit homeCubit;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onClose;

  final void Function(Duration?) onMediaReady;

  const SingleUserStoryView({
    super.key,
    required this.story,
    required this.homeCubit,
    required this.onNext,
    required this.onPrev,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onClose,
    required this.onMediaReady,
  });

  @override
  State<SingleUserStoryView> createState() => _SingleUserStoryViewState();
}

class _SingleUserStoryViewState extends State<SingleUserStoryView> {
  double _pointerDownX = 0;
  double _pointerDownY = 0;
  double _pointerDownTime = 0;

  final StoryController _storyController = StoryController();

  // ── Video controller ──────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoInitialised = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    if (widget.story.storyType == StoryType.video) {
      _initVideo();
    }
    if (widget.story.storyType == StoryType.text) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onMediaReady((null)),
      );
    }
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.story.videoUrl!),
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _videoController = controller;
      controller.setLooping(false);
      controller.play();
      controller.addListener(_onVideoUpdate);
      setState(() => _videoInitialised = true);
      widget.onMediaReady(controller.value.duration);
    } catch (_) {
      if (mounted) {
        setState(() => _videoError = true);
        widget.onMediaReady(_videoController!.value.duration);
      }
    }
  }

  void _onVideoUpdate() {
    if (_videoController == null) return;
    final value = _videoController!.value;
    if (value.duration > Duration.zero &&
        value.position >= value.duration &&
        !value.isPlaying) {
      _videoController!.removeListener(_onVideoUpdate);
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _storyController.dispose();
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final storyItems = [
    //   if (widget.story.imageUrl != null)
    //     StoryItem.pageImage(
    //       url: widget.story.imageUrl!,
    //       controller: _storyController,
    //       duration: const Duration(seconds: 7),
    //     )
    //   else
    //     StoryItem.text(
    //       title: widget.story.contentText ?? "",
    //       backgroundColor: Color(
    //         int.parse(widget.story.backgroundColor ?? 'ff9c27b0', radix: 16),
    //       ),
    //       textStyle: const TextStyle(fontSize: 28, color: Colors.white),
    //     ),
    // ];

    return Stack(
      children: [
        Positioned.fill(child: _buildMedia()),

        Positioned.fill(child: _buildGestureLayer(context)),

        Positioned(top: 55, left: 20, right: 20, child: _buildHeader(context)),

        // ── Caption ──────────────────────────────────────────────────────
        if (widget.story.caption != null && widget.story.caption!.isNotEmpty)
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.story.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  // ── Media builders ─────────────────────────────────────────────────────────

  Widget _buildMedia() {
    switch (widget.story.storyType) {
      case StoryType.video:
        return _buildVideoMedia();
      case StoryType.image:
        return _buildImageMedia();
      case StoryType.text:
        return _buildTextMedia();
    }
  }

  Widget _buildVideoMedia() {
    if (_videoError) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.videocam_off_outlined,
            color: Colors.white54,
            size: 48,
          ),
        ),
      );
    }
    if (!_videoInitialised) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.white),
            strokeWidth: 2,
          ),
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildImageMedia() {
    return CachedNetworkImage(
      imageUrl: widget.story.imageUrl!,
      fit: BoxFit.contain,
      placeholder:
          (_, __) => const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 2,
              ),
            ),
          ),
      imageBuilder: (context, imageProvider) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onMediaReady((null)),
        );
        return Image(image: imageProvider, fit: BoxFit.contain);
      },
      errorWidget: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onMediaReady((null)),
        );
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextMedia() {
    final bgColor = Color(
      int.parse(widget.story.backgroundColor ?? 'ff9c27b0', radix: 16),
    );
    return StoryView(
      storyItems: [
        StoryItem.text(
          title: widget.story.contentText ?? '',
          backgroundColor: bgColor,
          textStyle: const TextStyle(fontSize: 28, color: Colors.white),
        ),
      ],
      controller: _storyController,
      onComplete: () {},
      inline: true,
      progressPosition: ProgressPosition.none,
    );
  }

  // ── Gesture layer ──────────────────────────────────────────────────────────

  Widget _buildGestureLayer(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _pointerDownX = e.position.dx;
        _pointerDownY = e.position.dy;
        _pointerDownTime = e.timeStamp.inMilliseconds.toDouble();
      },
      onPointerUp: (e) {
        final dx = e.position.dx - _pointerDownX;
        final dy = e.position.dy - _pointerDownY;
        final dt = e.timeStamp.inMilliseconds - _pointerDownTime;

        // Long-press release
        if (dt > 300 && dx.abs() < 10 && dy.abs() < 10) {
          _storyController.play();
          widget.onLongPressEnd();
          return;
        }

        // Swipe down to close
        if (dy.abs() > dx.abs() && dy.abs() > 50) {
          widget.onClose();
          return;
        }

        // Horizontal swipe
        if (dx.abs() > 50) {
          dx < 0 ? widget.onNext() : widget.onPrev();
          return;
        }

        // Tap left/right half
        final half = MediaQuery.of(context).size.width / 2;
        e.position.dx < half ? widget.onPrev() : widget.onNext();
      },
      onPointerMove: (e) {
        final dx = e.position.dx - _pointerDownX;
        final dy = e.position.dy - _pointerDownY;
        final dt = e.timeStamp.inMilliseconds - _pointerDownTime;

        if (dt > 300 && dx.abs() < 10 && dy.abs() < 10) {
          _storyController.pause();
          widget.onLongPressStart();
        }
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final story = widget.story;
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final bool isMyStory = story.authorId == currentUserId;

    return Row(
      children: [
        InkWell(
          onTap: widget.onClose,
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        const Gap(10),
        GestureDetector(
          onTap:
              isMyStory
                  ? null
                  : () {
                    final currentHomeCubit = context.read<HomeCubit>();
                    showDialog(
                      context: context,
                      builder:
                          (dialogContext) => BlocProvider.value(
                            value: currentHomeCubit,
                            child: UserPreviewDialog(
                              user: story.toChatUserModel(),
                              showContactOptions: false,
                            ),
                          ),
                    );
                  },
          child: CircleAvatar(
            backgroundImage:
                (story.authorImageUrl != null &&
                        story.authorImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(story.authorImageUrl!)
                    : AssetImage(AppImages.defaultUserImg),
          ),
        ),
        const Gap(10),
        GestureDetector(
          onTap:
              isMyStory
                  ? null
                  : () {
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.profileViewRoute,
                      arguments: story.authorId,
                    );
                  },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMyStory ? 'You' : story.authorName,
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                FormattedDate.getFormattedDate(story.createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const Spacer(),

        if (story.storyType == StoryType.video)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white70,
              size: 18,
            ),
          ),

        if (isMyStory)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined, color: Colors.white70),
            elevation: 1.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onOpened: () {
              _storyController.pause();
              _videoController?.pause();
              widget.onLongPressStart();
            },
            onCanceled: () {
              _storyController.play();
              _videoController?.play();
              widget.onLongPressEnd();
            },
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await _showDeleteConfirmation(context);
                if (confirm == true) {
                  widget.homeCubit.deleteStory(story.id);
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  _storyController.play();
                  _videoController?.play();
                  widget.onLongPressEnd();
                }
              }
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        Gap(8),
                        Text(
                          'Delete Story',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
      ],
    );
  }
}

// ── Delete confirmation dialog ────────────────────────────────────────────────

Future<bool?> _showDeleteConfirmation(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        child: CustomConfirmationDialog(
          title: 'Delete this story?',
          img: AppImages.deleteFilesAnimationLot,
          confirmBtnText: 'Delete',
          cancelBtnText: 'Cancel',
          onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      );
    },
  );
}
