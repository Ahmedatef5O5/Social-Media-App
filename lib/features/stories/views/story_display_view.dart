import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/stories/model/story_model.dart';

import '../widgets/user_story_group_container.dart';

class StoryDisplayView extends StatefulWidget {
  final List<List<StoryModel>> allUserGroups;
  final int initialGroupIndex;
  final HomeCubit homeCubit;

  const StoryDisplayView({
    super.key,
    required this.allUserGroups,
    required this.initialGroupIndex,
    required this.homeCubit,
  });

  @override
  State<StoryDisplayView> createState() => _StoryDisplayViewState();
}

class _StoryDisplayViewState extends State<StoryDisplayView> {
  late PageController _groupPageController;
  bool _isClosing = false;
  void _safeClose() {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _groupPageController = PageController(
      initialPage: widget.initialGroupIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _groupPageController,
        itemCount: widget.allUserGroups.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return UserStoryGroupContainer(
            userStories: widget.allUserGroups[index],
            homeCubit: widget.homeCubit,
            onClose: _safeClose,
            onAllStoriesComplete: () {
              if (index < widget.allUserGroups.length - 1) {
                _groupPageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                _safeClose();
              }
            },
            onPrevGroup: () {
              if (index > 0) {
                _groupPageController.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
          );
        },
      ),
    );
  }
}
