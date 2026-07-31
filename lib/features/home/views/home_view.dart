import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/core/widgets/custom_back_to_top_btn.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/core/widgets/custom_tab_wrapper.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/reels/cubit/reels_feed_cubit/reels_feed_cubit.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../posts/cubit/posts_cubit/posts_cubit.dart';
import '../../posts/helper/global_video_pause_gate.dart';
import '../../reels/widgets/home_feed_with_reels.dart';
import '../../stories/cubit/stories_cubit/stories_cubit.dart';
import '../widgets/new_posts_pill.dart';
import '../widgets/home_view_header_section.dart';
import '../../posts/widgets/post_writing_card.dart';
import '../../stories/widgets/stories_list_section.dart';
import 'home_shimmer_skeleton_view.dart';

class HomeView extends StatefulWidget {
  final PersistentTabController navController;
  final ScrollController scrollController;
  const HomeView({
    super.key,
    required this.navController,
    required this.scrollController,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _showBackToTop = false;
  bool _isRefreshing = false;
  double _lastOffset = 0;
  bool _isScrollingToTop = false;
  static const double _topScrollThreshold = 4.0;
  bool get _isNearTop =>
      !widget.scrollController.hasClients ||
      widget.scrollController.offset <= _topScrollThreshold;

  @override
  void initState() {
    super.initState();
    updateMyFcmToken();
    context.read<HomeCubit>().navController = widget.navController;

    widget.scrollController.addListener(() {
      if (_isScrollingToTop) return;

      final currentOffset = widget.scrollController.offset;
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

  Future<void> updateMyFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        final user = SupabaseProvider.user;

        if (user != null) {
          await SupabaseProvider.client
              .from(SupabaseConstants.users)
              .update({UserColumns.fcmToken: token})
              .eq(UserColumns.id, user.id);

          debugPrint("✅ My FCM Token updated in Supabase: $token");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error updating FCM token: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _scrollToTop() async {
    _isScrollingToTop = true;

    setState(() {
      _showBackToTop = false;
    });

    await widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );

    _lastOffset = 0;
    _isScrollingToTop = false;
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    GlobalVideoPauseGate.instance.isPaused.value = true;
    try {
      await Future.wait([
        context.read<HomeCubit>().refreshUserData(isRefresh: true),
        context.read<PostsCubit>().refreshPosts(isRefresh: true),
        context.read<StoriesCubit>().fetchStories(isRefresh: true),
      ]);
      if (!mounted) return;
      final postsState = context.read<PostsCubit>().state;
      if (postsState is PostsLoaded) {
        await context.read<ReelsFeedCubit>().fetchReels(
          postsCount: postsState.posts.length,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
      GlobalVideoPauseGate.instance.isPaused.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocListener<PostsCubit, PostsState>(
        listenWhen: (previous, current) => current is PostsPendingUpdated,
        listener: (context, state) {
          if (_isNearTop) {
            context.read<PostsCubit>().mergePendingPosts();
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, homeState) {
            return BlocBuilder<PostsCubit, PostsState>(
              buildWhen: (previous, current) => current is! PostsPendingUpdated,

              builder: (context, postsState) {
                return BlocBuilder<StoriesCubit, StoriesState>(
                  buildWhen:
                      (previous, current) =>
                          current is StoriesLoaded ||
                          (current is StoriesLoading &&
                              previous is! StoriesLoaded),
                  builder: (context, storiesState) {
                    return CustomTabWrapper(
                      isLoading:
                          homeState is HomeInitial ||
                          homeState is UserDataLoading ||
                          postsState is PostsInitial ||
                          postsState is PostsLoading,
                      errorMessage:
                          homeState is UserDataLoadError
                              ? homeState.message
                              : (postsState is PostsLoadError
                                  ? postsState.message
                                  : null),

                      onRetry: () {
                        context.read<HomeCubit>().refreshUserData();
                        context.read<PostsCubit>().refreshPosts();
                      },
                      loadingSkeleton: const HomeShimmerSkeleton(),

                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: CustomPullToRefresh(
                                top: MediaQuery.sizeOf(context).height * 0.068,
                                onRefresh: _handleRefresh,
                                child: CustomScrollView(
                                  controller: widget.scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  scrollDirection: Axis.vertical,
                                  slivers: [
                                    const SliverGap(44),
                                    SliverToBoxAdapter(
                                      child: HomeViewHeaderSection(
                                        navController: widget.navController,
                                      ),
                                    ),
                                    const SliverGap(16),
                                    SliverToBoxAdapter(
                                      child: PostWritingCard(),
                                    ),
                                    const SliverGap(10),
                                    SliverToBoxAdapter(
                                      child: StoriesListSection(),
                                    ),
                                    const SliverGap(10),
                                    const HomeFeedWithReels(),
                                    SliverGap(
                                      MediaQuery.of(context).padding.bottom +
                                          100,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_isRefreshing)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: 1,
                                    child: const HomeShimmerSkeleton(),
                                  ),
                                ),
                              ),
                            ),

                          Positioned(
                            top: 22,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: BlocBuilder<PostsCubit, PostsState>(
                                buildWhen:
                                    (previous, current) =>
                                        current is PostsPendingUpdated ||
                                        current is PostsLoaded,
                                builder: (context, state) {
                                  final pendingCount =
                                      context
                                          .read<PostsCubit>()
                                          .pendingPosts
                                          .length;
                                  return NewPostsPill(
                                    count: pendingCount,
                                    onTap: () {
                                      context
                                          .read<PostsCubit>()
                                          .mergePendingPosts();
                                      _scrollToTop();
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          CustomBackToTopBtn(
                            isVisible: _showBackToTop,
                            onTap: _scrollToTop,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
