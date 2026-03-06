import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import '../widgets/home_view_header_section.dart';
import '../widgets/post_writing_card.dart';
import '../widgets/stories_list_section.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BackgroundThemeWidget(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Gap(30),
                HomeViewHeaderSection(),
                Gap(35),
                PostWritingCard(),
                Gap(20),
                StoriesListSection(),
                Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
