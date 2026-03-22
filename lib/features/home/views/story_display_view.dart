import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/story_page_item.dart';

class StoryDisplayView extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryDisplayView({
    super.key,
    required this.stories,
    required this.initialIndex,
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
      backgroundColor: AppColors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        physics: const ClampingScrollPhysics(),
        // physics: const AlwaysScrollableScrollPhysics(),
        // physics: const PageScrollPhysics(),
        onPageChanged: (value) {},
        itemBuilder:
            (context, index) => StoryPageItem(
              story: widget.stories[index],
              controller: _pageController,
              onStoryComplete: () {
                if (index < widget.stories.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
      ),
    );
  }
}
