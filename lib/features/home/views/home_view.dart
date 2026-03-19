import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import '../widgets/home_view_header_section.dart';
import '../widgets/post_writing_card.dart';
import '../widgets/posts_section.dart';
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
            child: CustomPullToRefresh(
              onRefresh:
                  () async => await context.read<HomeCubit>().refreshHomeData(
                    isRefresh: true,
                  ),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                slivers: [
                  const SliverGap(30),
                  SliverToBoxAdapter(child: HomeViewHeaderSection()),
                  const SliverGap(35),
                  SliverToBoxAdapter(child: PostWritingCard()),
                  const SliverGap(20),
                  SliverToBoxAdapter(child: StoriesListSection()),
                  const SliverGap(4),
                  PostsSection(),
                  const SliverGap(25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
