import 'package:flutter/material.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../model/story_model.dart';
import '../views/single_user_story_view.dart';

class UserStoryGroupContainer extends StatefulWidget {
  final List<StoryModel> userStories;
  final VoidCallback onAllStoriesComplete;
  final VoidCallback onPrevGroup;
  final HomeCubit homeCubit;
  final VoidCallback onClose;

  const UserStoryGroupContainer({
    super.key,
    required this.userStories,
    required this.onAllStoriesComplete,
    required this.onPrevGroup,
    required this.homeCubit,
    required this.onClose,
  });

  @override
  State<UserStoryGroupContainer> createState() =>
      _UserStoryGroupContainerState();
}

class _UserStoryGroupContainerState extends State<UserStoryGroupContainer>
    with TickerProviderStateMixin {
  int _currentStoryIndex = 0;
  late AnimationController _progressController;
  bool _isCompleted = false;

  bool _mediaReady = false;

  @override
  void initState() {
    super.initState();
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
        return const Duration(seconds: 60);
      case StoryType.image:
      case StoryType.text:
        return const Duration(seconds: 7);
    }
  }

  void _onMediaReady(Duration? actualDuration) {
    if (!mounted || _mediaReady) return;
    _mediaReady = true;

    final duration =
        actualDuration ??
        _durationForStory(widget.userStories[_currentStoryIndex]);

    _progressController.stop();
    _progressController.reset();
    _progressController.duration = duration;
    _progressController.forward(from: 0.0);
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
      widget.onPrevGroup();
    }
  }

  void _pauseProgress() => _progressController.stop();

  void _resumeProgress() {
    if (_mediaReady) _progressController.forward();
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
          homeCubit: widget.homeCubit,
          onNext: _nextStory,
          onPrev: _prevStory,
          onLongPressStart: _pauseProgress,
          onLongPressEnd: _resumeProgress,
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
