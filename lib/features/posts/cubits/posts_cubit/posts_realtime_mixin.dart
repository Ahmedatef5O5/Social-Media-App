part of 'posts_cubit.dart';

mixin PostsRealtimeMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  List<PostModel> get cachedPosts;
  set cachedPosts(List<PostModel> value);
  List<PostModel> _fixLikersImages(List<PostModel> posts);

  StreamSubscription? _postsSubscription;

  final List<PostModel> _pendingPosts = [];
  List<PostModel> get pendingPosts => List.unmodifiable(_pendingPosts);

  final Set<String> _pendingDeletedPostIds = {};

  void listenToPosts() {
    if (_postsSubscription != null) return;

    _postsSubscription = _postsServices.getPostsStream().listen((
      FeedEvent event,
    ) async {
      if (isClosed) return;

      switch (event) {
        case PostInsertedEvent(:final postId):
          await _handlePostInserted(postId);

        case PostUpdatedEvent(:final postId):
          await _handlePostUpdated(postId);

        case PostDeletedEvent(:final postId):
          _handlePostDeleted(postId);

        case LikeChangedEvent(:final postId, :final changeType):
          await _handleLikeChanged(postId, changeType);

        case ShareChangedEvent(:final postId, :final changeType):
          await _handleShareChanged(postId, changeType);

        case PresenceChangedEvent(
          :final userId,
          :final isOnline,
          :final updatedAt,
        ):
          _handlePresenceChanged(userId, isOnline, updatedAt);
      }
    });
  }

  Future<void> _handlePostInserted(String postId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newPost = await _postsServices.fetchPostById(postId);
    if (newPost == null || isClosed) {
      debugPrint('⚠️ Fetch Post By Id returned null for: $postId');
      return;
    }

    final alreadyExists =
        cachedPosts.any((p) => p.id == postId) ||
        _pendingPosts.any((p) => p.id == postId);
    if (alreadyExists) return;

    _pendingPosts.insert(0, newPost);
    emit(PostsPendingUpdated(_pendingPosts.length));
    debugPrint('🕓 New post queued (pending): $postId');
  }

  void mergePendingPosts() {
    if ((_pendingPosts.isEmpty && _pendingDeletedPostIds.isEmpty) || isClosed) {
      return;
    }

    List<PostModel> currentPosts = List.from(cachedPosts);

    if (_pendingDeletedPostIds.isNotEmpty) {
      currentPosts.removeWhere(
        (p) =>
            _pendingDeletedPostIds.contains(p.id) ||
            _pendingDeletedPostIds.contains(p.sharedPostId),
      );
      _pendingDeletedPostIds.clear();
    }

    if (_pendingPosts.isNotEmpty) {
      currentPosts = [..._pendingPosts, ...currentPosts];
      _pendingPosts.clear();
    }

    cachedPosts = _fixLikersImages(currentPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  Future<void> _handlePostUpdated(String postId) async {
    final updatedPost = await _postsServices.fetchPostById(postId);
    if (updatedPost == null || isClosed) return;

    cachedPosts = _mergeUpdatedPost(cachedPosts, updatedPost);
    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  void _handlePostDeleted(String postId) {
    final existsDirectly = cachedPosts.any((p) => p.id == postId);
    final existsPending = _pendingPosts.any((p) => p.id == postId);
    final hasWrapperCards = cachedPosts.any((p) => p.sharedPostId == postId);

    if ((!existsDirectly && !existsPending && !hasWrapperCards) || isClosed) {
      return;
    }

    if (existsPending) {
      _pendingPosts.removeWhere((p) => p.id == postId);
    }

    if (existsDirectly || hasWrapperCards) {
      _pendingDeletedPostIds.add(postId);
    }

    emit(PostsPendingUpdated(_pendingPosts.length));
    debugPrint('🔥 EVENT TRIGGERED: Queued Post Deletion (Pending) -> $postId');
  }

  Future<void> _handleLikeChanged(
    String postId,
    PostgresChangeEvent changeType,
  ) async {
    final refreshedPost = await _postsServices.fetchPostById(postId);
    if (refreshedPost == null || isClosed) return;

    cachedPosts = _mergeUpdatedPost(cachedPosts, refreshedPost);
    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  Future<void> _handleShareChanged(
    String postId,
    PostgresChangeEvent changeType,
  ) async {
    final refreshedPost = await _postsServices.fetchPostById(postId);
    if (refreshedPost == null || isClosed) return;

    cachedPosts = _mergeUpdatedPost(cachedPosts, refreshedPost);
    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  List<PostModel> _mergeUpdatedPost(List<PostModel> posts, PostModel updated) {
    return posts.map((p) {
      if (p.id == updated.id) return updated;
      if (p.originalPost?.id == updated.id) {
        return p.copyWith(originalPost: updated);
      }
      return p;
    }).toList();
  }

  void _handlePresenceChanged(
    String userId,
    bool isOnline,
    DateTime? updatedAt,
  ) {
    final isConsideredOnline = PresenceService.isConsideredOnline(
      isOnline: isOnline,
      updatedAt: updatedAt,
    );

    final affectsCurrentFeed = cachedPosts.any((p) => p.authorId == userId);
    if (!affectsCurrentFeed || isClosed) return;

    cachedPosts =
        cachedPosts.map((p) {
          return p.authorId == userId
              ? p.copyWith(isOnline: isConsideredOnline)
              : p;
        }).toList();

    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  bool isPostGhost(String postId) {
    return _pendingDeletedPostIds.contains(postId);
  }

  @override
  Future<void> close() {
    _postsSubscription?.cancel();
    return super.close();
  }
}
