part of 'posts_cubit.dart';

mixin PostsFeedMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  List<PostModel> get cachedPosts;
  set cachedPosts(List<PostModel> value);
  List<PostModel> _fixLikersImages(List<PostModel> posts);
  void listenToPosts();

  int feedEpoch = 0;

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
      cachedPosts = await _postsServices.fetchRankedHomeFeed();
      cachedPosts = _fixLikersImages(cachedPosts);

      feedEpoch++;

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

        feedEpoch++;

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

  void mergePostsIntoCache(List<PostModel> posts, {bool appendNew = false}) {
    if (posts.isEmpty || isClosed) return;

    final List<PostModel> basePosts =
        state is PostsLoaded ? (state as PostsLoaded).posts : cachedPosts;

    final Map<String, PostModel> incomingById = {
      for (final p in _fixLikersImages(posts)) p.id: p,
    };

    final updatedExisting =
        basePosts.map((existing) {
          final incoming = incomingById.remove(existing.id);
          if (incoming == null) return existing;
          return incoming.copyWith(
            isSuggestedForYou: existing.isSuggestedForYou,
          );
        }).toList();

    final brandNewPosts = incomingById.values.toList();

    cachedPosts =
        appendNew
            ? [...updatedExisting, ...brandNewPosts]
            : [...brandNewPosts, ...updatedExisting];

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
