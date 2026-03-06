import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/widgets/story_item_widget.dart';

class StoriesListSection extends StatelessWidget {
  const StoriesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.14,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder:
            (context, index) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: StoryItemWidget(isFirstItem: index == 0),
            ),
      ),
    );
  }
}
