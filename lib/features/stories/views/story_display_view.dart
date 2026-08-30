import 'package:flutter/material.dart';
import 'package:social_media_app/features/stories/models/story_model.dart';
import '../cubits/stories_cubit/stories_cubit.dart';
import '../widgets/user_story_group_container.dart';

class StoryDisplayView extends StatefulWidget {
  final List<List<StoryModel>> allUserGroups;
  final int initialGroupIndex;
  final StoriesCubit storiesCubit;
  final int initialStoryIndex;

  const StoryDisplayView({
    super.key,
    required this.allUserGroups,
    required this.initialGroupIndex,
    required this.storiesCubit,
    this.initialStoryIndex = 0,
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
            storiesCubit: widget.storiesCubit,
            onClose: _safeClose,
            initialStoryIndex:
                index == widget.initialGroupIndex
                    ? widget.initialStoryIndex
                    : 0,
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
