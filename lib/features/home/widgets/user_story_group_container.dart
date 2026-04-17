import 'package:flutter/material.dart';
import '../cubits/home_cubit/home_cubit.dart';
import '../models/story_model.dart';
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

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
    _progressController.forward();
  }

  void _nextStory() {
    if (_isCompleted) return;
    if (_currentStoryIndex < widget.userStories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      _isCompleted = true;
      widget.onAllStoriesComplete();
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      widget.onPrevGroup();
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
          story: widget.userStories[_currentStoryIndex],
          homeCubit: widget.homeCubit,
          onNext: _nextStory,
          onPrev: _prevStory,
          onLongPressStart: () => _progressController.stop(),
          onLongPressEnd: () => _progressController.forward(),
          onClose: widget.onClose,
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
