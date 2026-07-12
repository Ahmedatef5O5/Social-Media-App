import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../cubit/story_reaction_cubit/story_reaction_cubit.dart';
import '../cubit/story_reply_cubit/story_reply_cubit.dart';
import '../cubit/story_views_cubit/story_views_cubit.dart';
import '../model/story_model.dart';
import '../widgets/story_gesture_layer.dart';
import '../widgets/story_header.dart';
import '../widgets/story_reply_input_bar.dart';
import '../widgets/story_views_indicator.dart';
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
  bool _isDisposed = false;

  void _pauseStory() {
    widget.onLongPressStart();
    if (_isDisposed || !mounted) return;
    _videoController?.pause();
  }

  void _resumeStory() {
    widget.onLongPressEnd();
    if (_isDisposed || !mounted) return;
    _videoController?.play();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isMyStory = widget.story.authorId == currentUserId;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StoryReplyCubit()),
        if (!isMyStory)
          BlocProvider(
            create:
                (_) => StoryReactionCubit(
                  storyId: widget.story.id,
                  storyAuthorId: widget.story.authorId,
                ),
          ),
        if (isMyStory)
          BlocProvider(
            create: (_) => StoryViewsCubit(storyId: widget.story.id),
          ),
      ],
      child: Builder(
        builder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                child: StoryMediaView(
                  story: widget.story,
                  onMediaReady: (duration) {
                    widget.onMediaReady(duration);
                    if (!isMyStory) {
                      context.read<StoryReactionCubit>().markViewed();
                    }
                  },
                  onVideoFinished: widget.onNext,
                  onVideoControllerReady: (c) => _videoController = c,
                ),
              ),
              Positioned.fill(
                child: StoryGestureLayer(
                  onNext: widget.onNext,
                  onPrev: widget.onPrev,
                  onClose: widget.onClose,
                  onLongPressStart: _pauseStory,
                  onLongPressEnd: _resumeStory,
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
                  onPause: _pauseStory,
                  onResume: _resumeStory,
                  videoController: _videoController,
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.story.caption?.isNotEmpty == true)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          isMyStory ? 32 : 16,
                        ),
                        child: Align(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.story.caption!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isMyStory)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Align(
                          alignment: Alignment.center,
                          child: StoryViewsIndicator(
                            onOpen: _pauseStory,
                            onClose: _resumeStory,
                          ),
                        ),
                      ),

                    if (!isMyStory)
                      StoryReplyInputBar(
                        story: widget.story,
                        onComposingStart: _pauseStory,
                        onComposingEnd: _resumeStory,
                        onSent: () {
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //     content: Text('Reply sent ✓'),
                          //     duration: Duration(seconds: 1),
                          //   ),
                          // );
                          AppToast.info('Reply sent ✓');
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
