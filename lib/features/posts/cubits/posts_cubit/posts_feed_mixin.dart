part of 'posts_cubit.dart';

mixin PostsFeedMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  List<PostModel> get cachedPosts;
  set cachedPosts(List<PostModel> value);
  List<PostModel> _fixLikersImages(List<PostModel> posts);
  void listenToPosts();

  Future<void> refreshPosts({bool isRefresh = false}) async {
    try {
      final start = DateTime.now();
      await fetchPosts(isRefresh: isRefresh);

      if (isRefresh) {
        emit(PostsRefreshFeedback());
        final elapsed = DateTime.now().difference(start);
        const minDuration = Duration(milliseconds: 700);
        if (elapsed < minDuration) {
          await Future.delayed(minDuration - elapsed);
        }
        if (cachedPosts.isNotEmpty) {
          emit(PostsLoaded(cachedPosts, DateTime.now()));
        }
      }
    } catch (e) {
      debugPrint('Error refreshing posts: $e');
      if (e.toString().contains('no-internet')) {
        ConnectivityBannerController.notifyBlockedByOffline();
      }
      if (cachedPosts.isEmpty) {
        emit(
          PostsLoadError(
            e.toString().contains('no-internet')
                ? 'No internet connection. Please check your network.'
                : 'An error occurred while updating the data. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (!isRefresh) emit(PostsLoading());
    try {
      cachedPosts = await _postsServices.fetchPosts();
      cachedPosts = _fixLikersImages(cachedPosts);
      emit(PostsLoaded(cachedPosts, DateTime.now()));

      listenToPosts();
      persistPostsSnapshot(cachedPosts);
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (cachedPosts.isNotEmpty) {
        debugPrint('Silent error: no internet, showing cached posts.');
        return;
      }
      final diskPosts = readPostsSnapshot();
      if (diskPosts.isNotEmpty) {
        debugPrint(
          'Silent error: no internet, showing posts snapshot from disk.',
        );
        cachedPosts = diskPosts;
        emit(PostsLoaded(diskPosts, DateTime.now()));
        return;
      }
      emit(
        PostsLoadError(
          e.toString().contains('no-internet')
              ? 'No internet connection. Please check your network.'
              : 'Failed to load posts.',
        ),
      );
    }
  }

  void mergePostsIntoCache(List<PostModel> posts) {
    if (posts.isEmpty || isClosed) return;

    final List<PostModel> basePosts =
        state is PostsLoaded ? (state as PostsLoaded).posts : cachedPosts;

    final Map<String, PostModel> byId = {for (final p in basePosts) p.id: p};
    for (final incoming in posts) {
      byId[incoming.id] = incoming;
    }

    cachedPosts =
        byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  void persistPostsSnapshot(List<PostModel> posts) {
    unawaited(
      LocalSnapshotStore.instance
          .saveList(
            SnapshotKeys.posts,
            posts
                .take(kMaxCachedPostsSnapshot)
                .map((post) => post.toCacheJson())
                .toList(),
          )
          .catchError(
            (e) => debugPrint('Failed to persist posts snapshot: $e'),
          ),
    );
  }

  List<PostModel> readPostsSnapshot() {
    try {
      return LocalSnapshotStore.instance
          .readList(SnapshotKeys.posts)
          .map(PostModel.fromCacheJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to read posts snapshot from disk: $e');
      return [];
    }
  }
}
