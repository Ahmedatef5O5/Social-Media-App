import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_tab_wrapper.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../cubit/saved_posts_cubit/saved_posts_cubit.dart';
import '../helper/saved_posts_skeleton_items.dart';
import '../model/post_model.dart';
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
                'Saved Posts',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  fontSize: 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: theme.primaryColor,
                  ),
                  onPressed: () {
                    AppToast.info('this feature is coming soon');
                  },
                ),
                const Gap(8),
              ],
            ),
          ];
        },
        body: BlocBuilder<SavedPostsCubit, SavedPostsState>(
          builder: (context, state) {
            return CustomTabWrapper(
              isLoading:
                  state is SavedPostsInitial || state is SavedPostsLoading,
              errorMessage: state is SavedPostsError ? state.message : null,
              loadingSkeleton: const SavedPostsSkeletonItems(),
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
                .map((id) {
                  try {
                    return allPosts.firstWhere((p) => p.id == id);
                  } catch (_) {
                    return null;
                  }
                })
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
            'No saved posts yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap the bookmark icon on any post to save it here for later.',
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
