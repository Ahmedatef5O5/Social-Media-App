part of 'posts_cubit.dart';

enum PinResult { pinned, unpinned, limitReached, ignored, failed }

mixin PostPinMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  List<PostModel> get cachedPosts;
  set cachedPosts(List<PostModel> value);

  final Set<String> _pinInFlight = {};

  Future<PinResult> togglePin(String postId) async {
    final userId = SupabaseProvider.idOrNull;
    if (userId == null) return PinResult.ignored;

    final feed =
        state is PostsLoaded ? (state as PostsLoaded).posts : cachedPosts;
    final post = feed.where((p) => p.id == postId).firstOrNull;
    if (post == null || post.authorId != userId) return PinResult.ignored;
    if (!_pinInFlight.add(postId)) return PinResult.ignored; // double tap

    final bool wasPinned = post.isPinned;
    final bool target = !wasPinned;
    _setPinned(postId, target);

    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isOffline) {
        _setPinned(postId, wasPinned);
        return PinResult.failed;
      }

      final result = await _postsServices.setPostPinned(postId, target);
      if (result.pinned != target) _setPinned(postId, result.pinned);
      return result.pinned ? PinResult.pinned : PinResult.unpinned;
    } on PostgrestException catch (e) {
      _setPinned(postId, wasPinned);
      if (e.message.contains('pin_limit_reached')) {
        AppToast.info('Pin limit reached. Unpin a post first.');
        return PinResult.limitReached;
      }
      debugPrint('Error pinning post: $e');
      AppToast.info('Could not update the pin. Please try again.');
      return PinResult.failed;
    } catch (e) {
      _setPinned(postId, wasPinned);
      debugPrint('Error pinning post: $e');
      AppToast.info('Could not update the pin. Please try again.');
      return PinResult.failed;
    } finally {
      _pinInFlight.remove(postId);
    }
  }

  void _setPinned(String postId, bool value) {
    final base =
        state is PostsLoaded ? (state as PostsLoaded).posts : cachedPosts;
    final updated =
        base
            .map((p) => p.id == postId ? p.copyWith(isPinned: value) : p)
            .toList();
    cachedPosts = updated;
    emit(PostsLoaded(updated, DateTime.now()));
  }
}
