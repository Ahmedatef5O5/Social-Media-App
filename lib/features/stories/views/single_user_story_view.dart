import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../cubit/stories_cubit.dart';
import '../model/story_model.dart';
import '../widgets/story_gesture_layer.dart';
import '../widgets/story_header.dart';
import 'story_media_view.dart';

class SingleUserStoryView extends StatefulWidget {
  final StoryModel story;
  final StoriesCubit storiesCubit;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onClose;
  final void Function(Duration?) onMediaReady;

  const SingleUserStoryView({
    super.key,
    required this.story,
    required this.storiesCubit,
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
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: StoryMediaView(
            story: widget.story,
            onMediaReady: widget.onMediaReady,
            onVideoFinished: widget.onNext,
            onVideoControllerReady: (c) => _videoController = c,
          ),
        ),
        Positioned.fill(
          child: StoryGestureLayer(
            onNext: widget.onNext,
            onPrev: widget.onPrev,
            onClose: widget.onClose,
            onLongPressStart: widget.onLongPressStart,
            onLongPressEnd: widget.onLongPressEnd,
          ),
        ),
        Positioned(
          top: 55,
          left: 20,
          right: 20,
          child: StoryHeader(
            story: widget.story,
            storiesCubit: widget.storiesCubit,
            onClose: widget.onClose,
            onPause: widget.onLongPressStart,
            onResume: widget.onLongPressEnd,
            videoController: _videoController,
          ),
        ),
        if (widget.story.caption?.isNotEmpty == true)
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
}