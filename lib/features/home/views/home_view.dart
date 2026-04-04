import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_back_to_top_btn.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import '../widgets/home_view_header_section.dart';
import '../widgets/post_writing_card.dart';
import '../widgets/posts_section.dart';
import '../widgets/stories_list_section.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late ScrollController _scrollController;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 3000 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 3000 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BackgroundThemeWidget(
        bottom: false,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomPullToRefresh(
                  onRefresh:
                      () async => await context
                          .read<HomeCubit>()
                          .refreshHomeData(isRefresh: true),
                  child: CustomScrollView(
                    controller: _scrollController,
                    // physics: const AlwaysScrollableScrollPhysics(),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
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
                      SliverGap(MediaQuery.of(context).padding.bottom + 100),
                    ],
                  ),
                ),
              ),
            ),
            CustomBackToTopBtn(isVisible: _showBackToTop, onTap: _scrollToTop),
          ],
        ),
      ),
    );
  }
}
