import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:social_media_app/core/link/widgets/message_link_preview.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:video_player/video_player.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../cubit/story_reaction_cubit/story_reaction_cubit.dart';
import '../cubit/story_reply_cubit/story_reply_cubit.dart';
import '../cubit/story_views_cubit/story_views_cubit.dart';
import '../model/story_model.dart';
import '../widgets/reaction_fountain_widget.dart';
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

class _SingleUserStoryViewState extends State<SingleUserStoryView>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isDisposed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _pauseStory();
    } else if (state == AppLifecycleState.resumed) {
      _resumeStory();
    }
  }

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

  void _showLinkPreviewSheet(String url) {
    _pauseStory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  MessageLinkPreview(
                    text: url,
                    isMe: false,
                    textWidget: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
    ).then((_) {
      _resumeStory();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseProvider.id;
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

              if (widget.story.storyType == StoryType.text)
                Positioned.fill(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    child: MessageLinkPreview(
                      text: widget.story.contentText ?? '',
                      isMe: false,
                      textWidget: Text(
                        widget.story.contentText ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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

              if (isMyStory)
                Positioned.fill(
                  child: BlocBuilder<StoryViewsCubit, StoryViewsState>(
                    builder: (context, state) {
                      if (state is! StoryViewsLoaded) {
                        return const SizedBox.shrink();
                      }
                      final reactedViewers =
                          state.viewers.where((v) => v.hasReacted).toList()
                            ..sort((a, b) => a.viewedAt.compareTo(b.viewedAt));

                      final reactionEmojis =
                          reactedViewers.map((v) => v.reaction!).toList();

                      return ReactionFountainWidget(
                        reactionEmojis: reactionEmojis,
                      );
                    },
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
                            child: Linkify(
                              text: widget.story.caption!,
                              textAlign: TextAlign.center,
                              options: const LinkifyOptions(humanize: false),
                              onOpen: (link) => _showLinkPreviewSheet(link.url),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              linkStyle: const TextStyle(
                                color: Colors.lightBlueAccent,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.lightBlueAccent,
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
