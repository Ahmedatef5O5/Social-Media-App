import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_tab_wrapper.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../cubits/saved_posts_cubit/saved_posts_cubit.dart';
import '../helpers/posts_skeleton_items.dart';
import '../models/post_model.dart';
import '../widgets/post_item_widget.dart';

class SavedPostsView extends StatefulWidget {
  const SavedPostsView({super.key, required this.userId});

  final String userId;

  @override
  State<SavedPostsView> createState() => _SavedPostsViewState();
}

class _SavedPostsViewState extends State<SavedPostsView> {
  @override
  void initState() {
    super.initState();
    context.read<SavedPostsCubit>().fetchSavedPosts(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsCubit = context.read<PostsCubit>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(50),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.primaryColor,
                  size: 22,
                ),
              ),
              title: Text(
                context.l10n.savedPosts,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: context.ls(0.5),
                  fontSize: 20,
                ),
              ),
              actions: const [_SavedPostsCountBadge(), Gap(16)],
            ),
          ];
        },
        body: BlocBuilder<SavedPostsCubit, SavedPostsState>(
          builder: (context, state) {
            return CustomTabWrapper(
              isLoading:
                  state is SavedPostsInitial || state is SavedPostsLoading,
              isTopSafeArea: false,
              errorMessage: state is SavedPostsError ? state.message : null,
              loadingSkeleton: const PostsSkeletonItems(),
              onRetry:
                  () => context.read<SavedPostsCubit>().fetchSavedPosts(
                    widget.userId,
                  ),
              child: _SavedPostsList(state: state, postsCubit: postsCubit),
            );
          },
        ),
      ),
    );
  }
}

class _SavedPostsCountBadge extends StatelessWidget {
  const _SavedPostsCountBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SavedPostsCubit, SavedPostsState>(
      builder: (context, savedState) {
        if (savedState is! SavedPostsLoaded) {
          return const SizedBox.shrink();
        }

        final postIds = savedState.postIds;

        return BlocBuilder<PostsCubit, PostsState>(
          builder: (context, postsState) {
            final allPosts =
                postsState is PostsLoaded ? postsState.posts : <PostModel>[];

            final count =
                postIds
                    .map((id) => allPosts.findById(id))
                    .whereType<PostModel>()
                    .where((p) => p.isSavedByMe)
                    .length;

            if (count == 0) {
              return const SizedBox.shrink();
            }

            return Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Container(
                  key: ValueKey<int>(count),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SavedPostsList extends StatelessWidget {
  const _SavedPostsList({required this.state, required this.postsCubit});

  final SavedPostsState state;
  final PostsCubit postsCubit;

  @override
  Widget build(BuildContext context) {
    if (state is! SavedPostsLoaded) {
      return const _EmptySavedPosts();
    }

    final loadedState = state as SavedPostsLoaded;

    return BlocBuilder<PostsCubit, PostsState>(
      builder: (context, postsState) {
        final allPosts =
            postsState is PostsLoaded ? postsState.posts : <PostModel>[];

        final visiblePosts =
            loadedState.postIds
                .map((id) => allPosts.findById(id))
                .whereType<PostModel>()
                .where((p) => p.isSavedByMe)
                .toList();

        if (visiblePosts.isEmpty) {
          return const _EmptySavedPosts();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visiblePosts.length,
          separatorBuilder: (_, __) => const Gap(20),
          itemBuilder: (context, index) {
            return PostItemWidget(
              currPost: visiblePosts[index],
              postsCubit: postsCubit,
            );
          },
        );
      },
    );
  }
}

class _EmptySavedPosts extends StatelessWidget {
  const _EmptySavedPosts();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            child: EmptyFindingsThemedAnimation(
              animationPath: AppImages.emptyFindingsLot,
              height: size.height * 0.3,
            ),
          ),
          const Gap(18),
          Text(
            context.l10n.noSavedPostsYet,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              context.l10n.tapTheBookmarkIcon,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
