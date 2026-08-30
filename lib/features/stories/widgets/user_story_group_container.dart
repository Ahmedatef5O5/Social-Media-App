import 'package:flutter/material.dart';
import '../cubits/stories_cubit/stories_cubit.dart';
import '../models/story_model.dart';
import '../views/single_user_story_view.dart';

class UserStoryGroupContainer extends StatefulWidget {
  final List<StoryModel> userStories;
  final VoidCallback onAllStoriesComplete;
  final VoidCallback onPrevGroup;
  final StoriesCubit storiesCubit;
  final VoidCallback onClose;
  final int initialStoryIndex;

  const UserStoryGroupContainer({
    super.key,
    required this.userStories,
    required this.onAllStoriesComplete,
    required this.onPrevGroup,
    required this.storiesCubit,
    required this.onClose,
    this.initialStoryIndex = 0,
  });

  @override
  State<UserStoryGroupContainer> createState() =>
      _UserStoryGroupContainerState();
}

class _UserStoryGroupContainerState extends State<UserStoryGroupContainer>
    with TickerProviderStateMixin {
  late int _currentStoryIndex;
  late AnimationController _progressController;
  bool _isCompleted = false;
  bool _mediaReady = false;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex.clamp(
      0,
      widget.userStories.length - 1,
    );
    _initController(autoStart: false);
  }

  void _initController({bool autoStart = false}) {
    _progressController = AnimationController(
      vsync: this,
      duration: _durationForStory(widget.userStories[_currentStoryIndex]),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _nextStory();
    });

    if (autoStart) _progressController.forward();
  }

  Duration _durationForStory(StoryModel story) {
    switch (story.storyType) {
      case StoryType.video:
        final secs = story.videoDurationSeconds;
        return (secs != null && secs > 0)
            ? Duration(seconds: secs)
            : const Duration(seconds: 60);
      case StoryType.image:
      case StoryType.text:
        return const Duration(seconds: 7);
    }
  }

  void _onMediaReady(Duration? actualDuration) {
    if (!mounted) return;

    if (_mediaReady) return;

    setState(() {
      _mediaReady = true;
    });

    Duration safeDuration = actualDuration ?? const Duration(seconds: 5);
    final currentStory = widget.userStories[_currentStoryIndex];

    if (currentStory.storyType == StoryType.video &&
        safeDuration.inMilliseconds < 500) {
      if (currentStory.videoDurationSeconds != null &&
          currentStory.videoDurationSeconds! > 0) {
        safeDuration = Duration(seconds: currentStory.videoDurationSeconds!);
      } else {
        safeDuration = const Duration(seconds: 15);
      }
    }

    _progressController.duration = safeDuration;
    if (!_isCompleted) {
      _progressController.forward(from: 0);
    }
  }

  void _nextStory() {
    if (_isCompleted) return;
    if (_currentStoryIndex < widget.userStories.length - 1) {
      _progressController.stop();
      _progressController.reset();

      setState(() {
        _currentStoryIndex++;
        _mediaReady = false;
      });
      _progressController.duration = _durationForStory(
        widget.userStories[_currentStoryIndex],
      );
    } else {
      _isCompleted = true;
      _dismissKeyboardIfOpen();
      widget.onAllStoriesComplete();
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      _progressController.stop();
      _progressController.reset();

      setState(() {
        _currentStoryIndex--;
        _mediaReady = false;
      });
      _progressController.duration = _durationForStory(
        widget.userStories[_currentStoryIndex],
      );
    } else {
      _dismissKeyboardIfOpen();
      widget.onPrevGroup();
    }
  }

  void _pauseProgress() => _progressController.stop();

  void _resumeProgress() {
    if (_mediaReady) _progressController.forward();
  }

  void _dismissKeyboardIfOpen() {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleUserStoryView(
          key: ValueKey(widget.userStories[_currentStoryIndex].id),
          story: widget.userStories[_currentStoryIndex],
          storiesCubit: widget.storiesCubit,
          onNext: _nextStory,
          onPrev: _prevStory,
          onLongPressStart: _pauseProgress,
          onLongPressEnd: _resumeProgress,
          onNextGroup: widget.onAllStoriesComplete,
          onPrevGroup: widget.onPrevGroup,
          onClose: widget.onClose,
          onMediaReady: _onMediaReady,
        ),

        Positioned(
          top: 40,
          left: 10,
          right: 10,
          child: AnimatedBuilder(
            animation: _progressController,
            builder:
                (context, _) => Row(
                  children:
                      widget.userStories.asMap().entries.map((entry) {
                        int idx = entry.key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value:
                                  idx < _currentStoryIndex
                                      ? 1.0
                                      : (idx == _currentStoryIndex
                                          ? _progressController.value
                                          : 0.0),
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              minHeight: 2,
                            ),
                          ),
                        );
                      }).toList(),
                ),
          ),
        ),
      ],
    );
  }
}
