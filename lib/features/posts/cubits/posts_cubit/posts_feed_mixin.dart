part of 'posts_cubit.dart';

mixin PostsFeedMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  List<PostModel> get cachedPosts;
  set cachedPosts(List<PostModel> value);
  List<PostModel> _fixLikersImages(List<PostModel> posts);
  void listenToPosts();

  int feedEpoch = 0;

  FeedWindow _feedWindow = const FeedWindow.initial();
  bool _isLoadingMoreFeed = false;
  bool _feedNotifierDisposed = false;

  /// Drives the small spinner under the last post.
  final ValueNotifier<bool> feedLoadingMore = ValueNotifier<bool>(false);

  bool get canLoadMorePosts =>
      _feedWindow.canLoadMore && !_isLoadingMoreFeed && cachedPosts.isNotEmpty;

  void _setLoadingMore(bool value) {
    _isLoadingMoreFeed = value;
    if (!_feedNotifierDisposed) feedLoadingMore.value = value;
  }

  /// Appends the next slice of the ranked feed. Safe to call from a scroll
  /// listener: it returns immediately unless a request is actually needed.
  Future<void> loadMorePosts() async {
    if (isClosed || !canLoadMorePosts) return;

    final epoch = feedEpoch;
    final nextLimit = _feedWindow.nextLimit;
    _setLoadingMore(true);
    try {
      final page = await _postsServices.fetchRankedHomeFeedPage(
        limit: nextLimit,
        offset: _feedWindow.offset,
        asOf: _feedWindow.asOf,
        excludeIds: {for (final p in cachedPosts) p.id},
      );

      // A refresh started while we were loading: its feed replaced ours, so
      // this page belongs to a stale ranking. Drop it.
      if (isClosed || epoch != feedEpoch) return;

      _feedWindow = _feedWindow.afterFetch(
        requested: nextLimit,
        rankedCount: page.rankedCount,
        asOf: page.asOf,
      );
      if (page.posts.isNotEmpty) {
        mergePostsIntoCache(page.posts, appendNew: true);
      }
    } catch (e) {
      // Keep the window unchanged so the next scroll retries.
      debugPrint('Error loading more posts: $e');
    } finally {
      _setLoadingMore(false);
    }
  }

  @override
  Future<void> close() {
    _feedNotifierDisposed = true;
    feedLoadingMore.dispose();
    return super.close();
  }

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
      const firstWindow = FeedWindow.initial();
      final page = await _postsServices.fetchRankedHomeFeedPage(
        limit: firstWindow.nextLimit,
      );
      _feedWindow = firstWindow.afterFetch(
        requested: firstWindow.nextLimit,
        rankedCount: page.rankedCount,
        asOf: page.asOf,
      );

      cachedPosts = _fixLikersImages(page.posts);

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
        _feedWindow = const FeedWindow.initial();

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

  void updateAuthorInfo({
    required String authorId,
    required String newName,
    required String? newImageUrl,
  }) {
    PostModel patchPost(PostModel post) {
      PostModel updated = post;
      if (updated.authorId == authorId) {
        updated = updated.copyWith(
          authorName: newName,
          authorImageUrl: newImageUrl ?? '',
        );
      }
      if (updated.originalPost != null) {
        updated = updated.copyWith(
          originalPost: patchPost(updated.originalPost!),
        );
      }
      if (updated.likes != null &&
          updated.likersImages != null &&
          updated.likes!.contains(authorId)) {
        final idx = updated.likes!.indexOf(authorId);
        if (idx >= 0 && idx < updated.likersImages!.length) {
          final newLikersImages = List<String>.from(updated.likersImages!);
          newLikersImages[idx] =
              (newImageUrl != null && newImageUrl.isNotEmpty)
                  ? newImageUrl
                  : 'asset:default';
          updated = updated.copyWith(likersImages: newLikersImages);
        }
      }
      return updated;
    }

    cachedPosts = cachedPosts.map(patchPost).toList();
    persistPostsSnapshot(cachedPosts);
    emit(PostsLoaded(List<PostModel>.from(cachedPosts), DateTime.now()));
  }
}
