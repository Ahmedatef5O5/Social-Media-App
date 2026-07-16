part of 'posts_cubit.dart';

mixin PostsRealtimeMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  List<PostModel> get cachedPosts;
  set cachedPosts(List<PostModel> value);
  List<PostModel> _fixLikersImages(List<PostModel> posts);

  StreamSubscription? _postsSubscription;

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
    final newPost = await _postsServices.fetchPostById(postId);
    if (newPost == null || isClosed) return;

    final alreadyExists = cachedPosts.any((p) => p.id == postId);
    if (alreadyExists) return;

    cachedPosts = [newPost, ...cachedPosts];

    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
    debugPrint('🔥 EVENT TRIGGERED: Inserted Post -> $postId');
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
    final hasWrapperCards = cachedPosts.any((p) => p.sharedPostId == postId);
    if ((!existsDirectly && !hasWrapperCards) || isClosed) return;

    cachedPosts =
        cachedPosts
            .where((p) => p.id != postId && p.sharedPostId != postId)
            .toList();
    emit(PostsLoaded(cachedPosts, DateTime.now()));
    debugPrint('🔥 EVENT TRIGGERED: Deleted Post Locally -> $postId');
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

  @override
  Future<void> close() {
    _postsSubscription?.cancel();
    return super.close();
  }
}
