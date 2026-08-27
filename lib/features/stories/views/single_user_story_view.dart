import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'package:social_media_app/core/link/widgets/message_link_preview.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:video_player/video_player.dart';
import '../../../core/mentions/widgets/mention_rich_text.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
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
  final VoidCallback onNextGroup;
  final VoidCallback onPrevGroup;
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
    required this.onNextGroup,
    required this.onPrevGroup,
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

  Future<void> _showLinkPreviewSheet(String url) async {
    _pauseStory();

    await showModalBottomSheet(
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
    );
    if (!mounted) return;

    _resumeStory();
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
          return StoryGestureLayer(
            onNext: widget.onNext,
            onPrev: widget.onPrev,
            onClose: widget.onClose,
            onLongPressStart: _pauseStory,
            onLongPressEnd: _resumeStory,
            onNextGroup: widget.onNextGroup,
            onPrevGroup: widget.onPrevGroup,

            child: Stack(
              children: [
                Positioned.fill(
                  child: StoryMediaView(
                    story: widget.story,
                    onMediaReady: (duration) {
                      widget.onMediaReady(duration);
                      if (!isMyStory && mounted) {
                        context.read<StoryReactionCubit>().markViewed();
                      }
                    },
                    onVideoFinished: widget.onNext,
                    onVideoControllerReady: (c) => _videoController = c,
                  ),
                ),

                if (widget.story.storyType == StoryType.text)
                  Positioned.fill(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.center,
                      child: Builder(
                        builder: (context) {
                          final text = widget.story.contentText?.trim() ?? '';

                          final bool isOnlyLink =
                              !text.contains(' ') &&
                              RegExp(
                                r'^(https?:\/\/)?([\w\d\-]+\.)+\w{2,}(\/.*)?$',
                              ).hasMatch(text);

                          final mentionTextWidget = MentionRichText(
                            text: text,
                            textAlign: TextAlign.center,
                            mentions: widget.story.mentions,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontFamily: null,
                              fontFamilyFallback: AppTypography.fontFallback,
                            ),
                            collapsedMaxLines: 9,
                            onExpandChanged: (expanded) {
                              if (expanded) {
                                _pauseStory();
                              } else {
                                _resumeStory();
                              }
                            },
                            onMentionTap:
                                (userId, name) => _openProfile(context, userId),
                            onLinkTap: _showLinkPreviewSheet,
                          );
                          if (isOnlyLink) {
                            return MessageLinkPreview(
                              text: text,
                              isMe: false,
                              textWidget: mentionTextWidget,
                            );
                          }

                          return mentionTextWidget;
                        },
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
                              ..sort(
                                (a, b) => a.viewedAt.compareTo(b.viewedAt),
                              );

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
                              child: MentionRichText(
                                text: widget.story.caption!,
                                mentions: widget.story.mentions,
                                textAlign: TextAlign.center,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: null,
                                  fontFamilyFallback: AppTypography.fontFallback,
                                ),
                                collapsedMaxLines: 9,
                                onExpandChanged: (expanded) {
                                  if (expanded) {
                                    _pauseStory();
                                  } else {
                                    _resumeStory();
                                  }
                                },
                                onMentionTap:
                                    (userId, name) =>
                                        _openProfile(context, userId),
                                onLinkTap: _showLinkPreviewSheet,
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
                            AppToast.success('Reply sent ✓');
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openProfile(BuildContext context, String userId) async {
    final currentUserId = SupabaseProvider.idOrNull;

    if (userId == currentUserId) {
      final navController = context.read<HomeCubit>().navController;
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (navController != null) {
        navController.jumpToTab(3);
      }
    } else {
      _pauseStory();

      await Navigator.of(
        context,
      ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);

      if (mounted && !_isDisposed) {
        _resumeStory();
      }
    }
  }
}
