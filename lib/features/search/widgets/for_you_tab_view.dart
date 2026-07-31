import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../../core/widgets/custom_pull_to_refresh.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../../posts/cubit/posts_cubit/posts_cubit.dart';
import '../../posts/model/post_model.dart';
import '../../posts/widgets/post_item_widget.dart';
import '../../reels/model/reel_model.dart';
import '../cubit/search_reels_cubit/search_reels_cubit.dart';
import '../model/injection_plan_entry.dart';
import '../utils/search_matcher.dart';
import 'for_you_feed_item.dart';
import 'for_you_reels_grid_section.dart';
import 'suggested_accounts_section.dart';

class ForYouTabView extends StatefulWidget {
  final ValueListenable<String> searchQuery;
  const ForYouTabView({super.key, required this.searchQuery});

  @override
  State<ForYouTabView> createState() => _ForYouTabViewState();
}

class _ForYouTabViewState extends State<ForYouTabView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  DateTime? _cachedPostsTimestamp;
  List<PostModel>? _rankedPosts;
  List<InjectionPlanEntry>? _injectionPlan;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeTopUpReels());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _maybeTopUpReels();
    }
  }

  void _maybeTopUpReels() {
    if (!mounted) return;
    if (widget.searchQuery.value.isNotEmpty) return;
    final reelsState = context.read<SearchReelsCubit>().state;
    if (reelsState is SearchReelsInitial) {
      context.read<SearchReelsCubit>().getReels();
    } else if (reelsState is SearchReelsLoaded && !reelsState.hasReachedMax) {
      context.read<SearchReelsCubit>().getReels();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<PostModel> _rankPosts(List<PostModel> posts) {
    final ranked = List<PostModel>.of(posts)..shuffle();
    ranked.sort((a, b) => _engagementScore(b).compareTo(_engagementScore(a)));
    return ranked;
  }

  int _engagementScore(PostModel post) =>
      post.likesCount + post.sharesCount + post.savedCount;

  List<ForYouFeedItem> _mergeForYouFeed({
    required List<PostModel> rankedPosts,
    required List<InjectionPlanEntry> plan,
    required List<ReelModel> reelsPool,
    required bool showSuggestedAccounts,
  }) {
    final items = <ForYouFeedItem>[];
    if (showSuggestedAccounts) {
      items.add(const ForYouFeedItem.suggestedAccounts());
    }

    var planCursor = 0;
    var reelOffset = 0;

    for (var i = 0; i < rankedPosts.length; i++) {
      items.add(ForYouFeedItem.post(rankedPosts[i]));

      if (planCursor < plan.length &&
          (i + 1) == plan[planCursor].afterPostIndex) {
        final entry = plan[planCursor];
        final remaining = reelsPool.length - reelOffset;
        if (remaining >= 2) {
          final take = entry.reelsCount.clamp(1, remaining);
          items.add(ForYouFeedItem.reelsGrid(reelsPool, reelOffset, take));
          reelOffset += take;
        }
        planCursor++;
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: widget.searchQuery,
      builder: (context, query, _) {
        return BlocBuilder<PostsCubit, PostsState>(
          buildWhen:
              (p, c) =>
                  c is PostsLoading || c is PostsLoaded || c is PostsError,
          builder: (context, postsState) {
            return BlocBuilder<SearchReelsCubit, SearchReelsState>(
              builder:
                  (context, reelsState) =>
                      _buildBody(context, theme, postsState, reelsState, query),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    PostsState postsState,
    SearchReelsState reelsState,
    String query,
  ) {
    if (postsState is PostsError) {
      return _buildErrorState(context, theme, postsState.message);
    }
    if (postsState is! PostsLoaded) {
      return Center(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.4,
          child: const CustomLoadingIndicator(radius: 11),
        ),
      );
    }

    final posts = postsState.posts;
    if (posts.isEmpty) {
      return _buildEmptyState(theme, query);
    }

    final postsCubit = context.read<PostsCubit>();

    if (query.isNotEmpty) {
      final matches =
          posts.where((p) => matchesSearchQuery(query, [p.text])).toList();
      if (matches.isEmpty) return _buildEmptyState(theme, query);

      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList.separated(
            itemCount: matches.length,
            itemBuilder:
                (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  child: PostItemWidget(
                    key: ValueKey(matches[i].id),
                    currPost: matches[i],
                    postsCubit: postsCubit,
                  ),
                ),
            separatorBuilder: (context, i) {
              return const Gap(14);
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    }

    if (_cachedPostsTimestamp != postsState.timeStamp) {
      _cachedPostsTimestamp = postsState.timeStamp;
      _rankedPosts = _rankPosts(posts);
      _injectionPlan = buildInjectionPlan(_rankedPosts!.length);
    }

    final reelsPool =
        reelsState is SearchReelsLoaded
            ? reelsState.reels
            : const <ReelModel>[];

    final items = _mergeForYouFeed(
      rankedPosts: _rankedPosts!,
      plan: _injectionPlan!,
      reelsPool: reelsPool,
      showSuggestedAccounts: true,
    );

    return CustomPullToRefresh(
      onRefresh: () => postsCubit.fetchPosts(isRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList.separated(
            itemCount: items.length,
            itemBuilder:
                (context, i) => _buildItem(context, items[i], postsCubit),
            separatorBuilder: (context, i) => const Gap(14),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    ForYouFeedItem item,
    PostsCubit postsCubit,
  ) {
    switch (item.type) {
      case ForYouItemType.suggestedAccounts:
        return const SuggestedAccountsSection();
      case ForYouItemType.post:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: PostItemWidget(
            key: ValueKey(item.post!.id),
            currPost: item.post!,
            postsCubit: postsCubit,
          ),
        );
      case ForYouItemType.reelsGrid:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ForYouReelsGridSection(
            reelsPool: item.reelsPool!,
            startIndex: item.reelsStartIndex!,
            count: item.reelsCount!,
          ),
        );
    }
  }

  Widget _buildEmptyState(ThemeData theme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyFindingsThemedAnimation(
              animationPath: AppImages.emptyFindingsLot,
              width: 150,
              height: 150,
            ),
            const Gap(12),
            Text(
              query.isEmpty
                  ? 'Nothing to show yet'
                  : 'No results found for "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(14),
            TextButton(
              onPressed:
                  () => context.read<PostsCubit>().fetchPosts(isRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
