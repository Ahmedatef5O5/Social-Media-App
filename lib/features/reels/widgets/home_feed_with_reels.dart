import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../posts/cubit/posts_cubit/posts_cubit.dart';
import '../../posts/model/post_model.dart';
import '../../posts/widgets/post_item_widget.dart';
import '../cubit/reels_feed_cubit/reels_feed_cubit.dart';
import '../model/reel_model.dart';
import '../services/reels_preferences_store.dart';
import 'reels_horizontal_section.dart';

class HomeFeedWithReels extends StatefulWidget {
  const HomeFeedWithReels({super.key});

  @override
  State<HomeFeedWithReels> createState() => _HomeFeedWithReelsState();
}

class _HomeFeedWithReelsState extends State<HomeFeedWithReels> {
  bool _isInitializingReels = false;

  @override
  void initState() {
    super.initState();
    // TODO : REMEBER REMOVE THIS resetPreferences
    // ReelsPreferencesStore.instance.resetPreferences();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeInitializeReels(),
    );
  }

  Future<void> _maybeInitializeReels() async {
    if (!mounted || _isInitializingReels) return;
    final postsState = context.read<PostsCubit>().state;
    final reelsCubit = context.read<ReelsFeedCubit>();
    if (postsState is! PostsLoaded || reelsCubit.state is! ReelsFeedInitial) {
      return;
    }
    await _initializeReelsFeed(postsState.posts.length);
  }

  Future<void> _initializeReelsFeed(int postsCount) async {
    _isInitializingReels = true;
    final reelsCubit = context.read<ReelsFeedCubit>();

    final hasSeenOnboarding =
        await ReelsPreferencesStore.instance.hasSeenOnboarding();

    List<String> categories = [];
    if (hasSeenOnboarding) {
      categories = await ReelsPreferencesStore.instance.getSelectedCategories();
    }

    if (!mounted) {
      _isInitializingReels = false;
      return;
    }
    await reelsCubit.applyPreferredCategoriesAndFetch(
      categories: categories,
      postsCount: postsCount,
    );
    _isInitializingReels = false;
  }

  @override
  Widget build(BuildContext context) {
    final postsCubit = context.read<PostsCubit>();

    return BlocListener<PostsCubit, PostsState>(
      bloc: postsCubit,
      listenWhen:
          (previous, current) =>
              current is PostsLoaded && previous is! PostsLoaded,
      listener: (context, state) {
        final reelsCubit = context.read<ReelsFeedCubit>();
        if (reelsCubit.state is ReelsFeedInitial) {
          _initializeReelsFeed((state as PostsLoaded).posts.length);
        }
      },
      child: BlocBuilder<PostsCubit, PostsState>(
        bloc: postsCubit,
        buildWhen:
            (previous, current) =>
                current is PostsLoading ||
                current is PostsLoaded ||
                current is PostsError,
        builder: (context, postsState) {
          return BlocBuilder<ReelsFeedCubit, ReelsFeedState>(
            builder:
                (context, reelsState) => _buildMergedSliver(
                  context,
                  postsCubit,
                  postsState,
                  reelsState,
                ),
          );
        },
      ),
    );
  }

  Widget _buildMergedSliver(
    BuildContext context,
    PostsCubit postsCubit,
    PostsState postsState,
    ReelsFeedState reelsState,
  ) {
    if (postsState is PostsLoading) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.36,
          child: const CustomLoadingIndicator(radius: 11),
        ),
      );
    } else if (postsState is PostsLoaded) {
      final posts = postsState.posts;
      if (posts.isEmpty) {
        return const SliverToBoxAdapter(
          child: Center(child: Text('No posts available.')),
        );
      }

      final injectionIndices =
          reelsState is ReelsFeedLoaded
              ? reelsState.injectionIndices
              : const <int>[];
      final sections =
          reelsState is ReelsFeedLoaded
              ? reelsState.sections
              : const <List<ReelModel>>[];

      final mergedItems = _mergeFeed(posts, injectionIndices, sections);

      return SliverList.separated(
        itemCount: mergedItems.length,
        itemBuilder: (context, index) {
          final item = mergedItems[index];
          if (item.reelsSection != null) {
            return ReelsHorizontalSection(
              reels: item.reelsSection!,
              sectionIndex: item.sectionIndex!,
            );
          }
          final post = item.post!;
          return PostItemWidget(
            key: ValueKey(post.id),
            currPost: post,
            postsCubit: postsCubit,
          );
        },
        separatorBuilder: (context, index) => const Gap(14),
      );
    } else if (postsState is PostsError) {
      return SliverToBoxAdapter(child: Center(child: Text(postsState.message)));
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  List<_MergedFeedItem> _mergeFeed(
    List<PostModel> posts,
    List<int> injectionIndices,
    List<List<ReelModel>> sections,
  ) {
    final items = <_MergedFeedItem>[];
    var postCursor = 0;

    for (var i = 0; i < injectionIndices.length; i++) {
      final targetIndex = injectionIndices[i];
      while (postCursor < targetIndex && postCursor < posts.length) {
        items.add(_MergedFeedItem.post(posts[postCursor]));
        postCursor++;
      }
      if (postCursor >= posts.length) break;
      items.add(_MergedFeedItem.reels(sections[i], i));
    }

    while (postCursor < posts.length) {
      items.add(_MergedFeedItem.post(posts[postCursor]));
      postCursor++;
    }

    return items;
  }
}

class _MergedFeedItem {
  final PostModel? post;
  final List<ReelModel>? reelsSection;
  final int? sectionIndex;

  const _MergedFeedItem.post(this.post)
    : reelsSection = null,
      sectionIndex = null;
  const _MergedFeedItem.reels(this.reelsSection, this.sectionIndex)
    : post = null;
}
