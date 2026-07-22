part of 'posts_cubit.dart';

mixin ReelShareMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  UserData? get currentUserData;
  List<PostModel> get cachedPosts;
  set cachedPosts(List<PostModel> value);

  Future<bool> shareReel(ReelModel reel) async {
    if (state is! PostsLoaded) return false;
    final userId = SupabaseProvider.idOrNull;
    if (userId == null) return false;

    final oldState = state as PostsLoaded;
    final wrapperId = const Uuid().v4();

    final wrapperCard = PostModel(
      id: wrapperId,
      text: '',
      authorId: userId,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      authorName: currentUserData?.name,
      authorImageUrl: currentUserData?.imageUrl,
      sharedReelId: reel.id,
      sharedReel: reel,
    );

    final updatedPosts = [wrapperCard, ...oldState.posts];
    cachedPosts = updatedPosts;
    emit(PostsLoaded(updatedPosts, DateTime.now()));

    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isOffline) {
        cachedPosts = oldState.posts;
        emit(PostsLoaded(oldState.posts, DateTime.now()));
        return false;
      }

      await _postsServices.shareReel(
        postId: wrapperId,
        reelId: reel.id,
        authorId: userId,
      );
      return true;
    } catch (e) {
      debugPrint('Error sharing reel: $e');
      cachedPosts = oldState.posts;
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      return false;
    }
  }
}
