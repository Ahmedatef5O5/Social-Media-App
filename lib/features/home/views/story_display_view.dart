import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:social_media_app/features/home/views/single_user_story_view.dart';

class StoryDisplayView extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final HomeCubit homeCubit;
  final List<List<StoryModel>> allUserGroups;
  final int currentGroupIndex;

  const StoryDisplayView({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.homeCubit,
    required this.allUserGroups,
    required this.currentGroupIndex,
  });

  @override
  State<StoryDisplayView> createState() => _StoryDisplayViewState();
}

class _StoryDisplayViewState extends State<StoryDisplayView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late List<StoryModel> _currentStories;
  late int _currentGroupIndex;
  late AnimationController _progressController;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentStories = widget.stories;
    _currentGroupIndex = widget.currentGroupIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentStoryIndex = widget.initialIndex;
    _initProgress();
  }

  void _initProgress() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onStoryComplete();
      }
    });

    _progressController.forward();
  }

  void _resetProgress() {
    _progressController.removeStatusListener(_onStatusChanged);
    _progressController.dispose();
    _initProgress();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _onStoryComplete();
    }
  }

  void _onStoryComplete() {
    if (_currentStoryIndex < _currentStories.length - 1) {
      setState(() => _currentStoryIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _resetProgress();
    } else {
      _goToNextUser();
    }
  }

  void _goToNextUser() {
    if (_currentGroupIndex < widget.allUserGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStories = widget.allUserGroups[_currentGroupIndex];
        _currentStoryIndex = 0;
      });
      _pageController.jumpToPage(0);
      _resetProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPrevUser() {
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStories = widget.allUserGroups[_currentGroupIndex];
        _currentStoryIndex = 0;
      });
      _pageController.jumpToPage(0);
      _resetProgress();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _currentStories.length,
            // physics: const BouncingScrollPhysics(),
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return SingleUserStoryView(
                key: ValueKey(_currentStories[index].id),
                story: _currentStories[index],
                homeCubit: widget.homeCubit,
                onComplete: _onStoryComplete,
                pageController: _pageController,
                currentIndex: index,
                totalCount: _currentStories.length,
                onSwipeNext: _goToNextUser,
                onSwipePrev: _goToPrevUser,
                progressController: _progressController,
                onResetProgress: _resetProgress,
              );
            },
          ),
          Positioned(
            top: 40,
            left: 12,
            right: 12,
            child: Row(
              children: List.generate(_currentStories.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child:
                        i < _currentStoryIndex
                            ? const LinearProgressIndicator(
                              value: 1,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white70,
                              ),
                              minHeight: 2.5,
                            )
                            : i == _currentStoryIndex
                            ? AnimatedBuilder(
                              animation: _progressController,
                              builder:
                                  (context, _) => LinearProgressIndicator(
                                    value: _progressController.value,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(
                                      Colors.white70,
                                    ),
                                    minHeight: 2.5,
                                  ),
                            )
                            : const LinearProgressIndicator(
                              value: 0,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white70,
                              ),
                              minHeight: 2.5,
                            ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
