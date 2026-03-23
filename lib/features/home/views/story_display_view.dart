import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:social_media_app/features/home/views/single_user_story_view.dart';

class StoryDisplayView extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final HomeCubit homeCubit;

  const StoryDisplayView({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.homeCubit,
  });

  @override
  State<StoryDisplayView> createState() => _StoryDisplayViewState();
}

class _StoryDisplayViewState extends State<StoryDisplayView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        physics: const BouncingScrollPhysics(),
        // physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return SingleUserStoryView(
            key: ValueKey(widget.stories[index].id),
            story: widget.stories[index],
            homeCubit: widget.homeCubit,
            onComplete: () {
              if (index < widget.stories.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pop(context);
              }
            },
            pageController: _pageController,
            currentIndex: index,
            totalCount: widget.stories.length,
          );
        },
      ),
    );
  }
}
