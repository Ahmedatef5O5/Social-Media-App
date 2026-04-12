import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_back_to_top_btn.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/core/widgets/custom_tab_wrapper.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import '../widgets/home_view_header_section.dart';
import '../widgets/post_writing_card.dart';
import '../widgets/posts_section.dart';
import '../widgets/stories_list_section.dart';
import 'home_shimmer_skeleton_view.dart';

class HomeView extends StatefulWidget {
  final PersistentTabController navController;
  const HomeView({super.key, required this.navController});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late ScrollController _scrollController;
  bool _showBackToTop = false;
  double _lastOffset = 0;
  bool _isScrollingToTop = false;

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().navController = widget.navController;
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_isScrollingToTop) return;

      final currentOffset = _scrollController.offset;
      final isScrollingUp = currentOffset < _lastOffset;

      if (currentOffset > 450 && isScrollingUp) {
        if (!_showBackToTop) {
          setState(() => _showBackToTop = true);
        }
      } else {
        if (_showBackToTop) {
          setState(() => _showBackToTop = false);
        }
      }

      _lastOffset = currentOffset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() async {
    _isScrollingToTop = true;

    setState(() {
      _showBackToTop = false;
    });

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );

    _lastOffset = 0;
    _isScrollingToTop = false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return CustomTabWrapper(
            isLoading:
                state is HomeInitial ||
                state is UserDataLoading ||
                state is PostsLoading ||
                state is StoriesLoading,
            errorMessage: state is UserDataLoadError ? state.message : null,
            onRetry: () => context.read<HomeCubit>().refreshHomeData(),
            loadingSkeleton: const HomeShimmerSkeleton(),

            child: BackgroundThemeWidget(
              bottom: false,
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomPullToRefresh(
                        top: MediaQuery.sizeOf(context).height * 0.068,
                        onRefresh:
                            () async => await context
                                .read<HomeCubit>()
                                .refreshHomeData(isRefresh: true),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          scrollDirection: Axis.vertical,
                          slivers: [
                            const SliverGap(30),
                            SliverToBoxAdapter(
                              child: HomeViewHeaderSection(
                                navController: widget.navController,
                              ),
                            ),
                            const SliverGap(35),
                            SliverToBoxAdapter(child: PostWritingCard()),
                            const SliverGap(20),
                            SliverToBoxAdapter(child: StoriesListSection()),
                            const SliverGap(4),
                            PostsSection(),
                            SliverGap(
                              MediaQuery.of(context).padding.bottom + 100,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CustomBackToTopBtn(
                    isVisible: _showBackToTop,
                    onTap: _scrollToTop,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
