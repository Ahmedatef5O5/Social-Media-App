part of 'posts_cubit.dart';

mixin PostReactionsMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  UserData? get currentUserData;

  Future<bool> toggleReaction(PostModel post, {String emoji = 'like'}) async {
    if (state is! PostsLoaded) return false;
    final user = SupabaseProvider.user;
    final userId = user?.id;
    if (userId == null) return false;

    final oldState = state as PostsLoaded;
    final String? currentEmoji = post.myReactionEmoji;
    final bool isRemoving = currentEmoji == emoji;

    final List<PostModel> updatedPosts = oldState.posts.updatePostById(
      post.id,
      (p) {
        final updatedLikes = List<String>.from(p.likes ?? []);
        final updatedImages = List<String>.from(p.likersImages ?? []);
        final updatedReactions = List<PostReactionModel>.from(p.reactions);

        final String imagePlaceholder =
            (currentUserData?.imageUrl != null &&
                    currentUserData!.imageUrl!.startsWith('http'))
                ? currentUserData!.imageUrl!
                : 'asset:default';

        if (currentEmoji == null) {
          updatedLikes.insert(0, userId);
          updatedImages.insert(0, imagePlaceholder);
        } else if (isRemoving) {
          updatedLikes.remove(userId);
          updatedImages.remove(imagePlaceholder);
        }
        if (currentEmoji != null) {
          final oldIdx = updatedReactions.indexWhere(
            (r) => r.emoji == currentEmoji,
          );
          if (oldIdx >= 0) {
            final old = updatedReactions[oldIdx];
            old.count <= 1
                ? updatedReactions.removeAt(oldIdx)
                : updatedReactions[oldIdx] = old.copyWith(
                  count: old.count - 1,
                  reactedByMe: false,
                );
          }
        }
        if (!isRemoving) {
          final newIdx = updatedReactions.indexWhere((r) => r.emoji == emoji);
          newIdx >= 0
              ? updatedReactions[newIdx] = updatedReactions[newIdx].copyWith(
                count: updatedReactions[newIdx].count + 1,
                reactedByMe: true,
              )
              : updatedReactions.add(
                PostReactionModel(emoji: emoji, count: 1, reactedByMe: true),
              );
        }

        return p.copyWith(
          likes: updatedLikes,
          likersImages: updatedImages.where((img) => img.isNotEmpty).toList(),
          reactions: updatedReactions,
        );
      },
    );

    emit(PostsLoaded(updatedPosts, DateTime.now()));

    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isOffline) return false;

      await _postsServices.toggleReaction(
        postId: post.id,
        userId: userId,
        emoji: emoji,
        currentEmoji: currentEmoji,
      );

      if (post.authorId != userId && currentEmoji == null) {
        await NotificationRepository.instance.notifyLike(
          receiverId: post.authorId,
          likerId: userId,
          likerName: currentUserData?.name ?? 'unKnown',
          likerImageUrl: currentUserData?.imageUrl ?? '',
          postId: post.id,
        );
      }

      if (post.authorId != userId && !isRemoving) {
        unawaited(
          FcmService.instance.notifyPostReact(
            receiverId: post.authorId,
            actorId: userId,
            actorName: currentUserData?.name ?? 'Someone',
            actorImageUrl: currentUserData?.imageUrl ?? '',
            postId: post.id,
            reactionType: emoji,
          ),
        );
      }
      return true;
    } catch (e) {
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling reaction: $e');

      if (e.toString().contains('23503') ||
          e.toString().contains('not present in table')) {
        AppToast.info('This post is no longer available.');
      }
      return false;
    }
  }

  Future<bool> toggleSavePost(PostModel post) async {
    if (state is! PostsLoaded) return false;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return false;

    final oldState = state as PostsLoaded;
    final bool wasSaved = post.isSavedByMe;

    final List<PostModel> updatedPosts = oldState.posts.updatePostById(
      post.id,
      (p) {
        final newCount = wasSaved ? p.savedCount - 1 : p.savedCount + 1;
        return p.copyWith(
          isSavedByMe: !wasSaved,
          savedCount: newCount < 0 ? 0 : newCount,
        );
      },
    );

    emit(PostsLoaded(updatedPosts, DateTime.now()));

    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isOffline) {
        emit(PostsLoaded(oldState.posts, DateTime.now()));
        return false;
      }
      await _postsServices.toggleSavePost(
        postId: post.id,
        userId: userId,
        isCurrentlySaved: wasSaved,
      );
      if (post.authorId != userId && !wasSaved) {
        unawaited(
          FcmService.instance.notifyPostSave(
            receiverId: post.authorId,
            actorId: userId,
            actorName: currentUserData?.name ?? 'Someone',
            actorImageUrl: currentUserData?.imageUrl ?? '',
            postId: post.id,
          ),
        );
      }
      return true;
    } catch (e) {
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling saved post: $e');

      if (e.toString().contains('23503') ||
          e.toString().contains('not present in table')) {
        AppToast.info('This post is no longer available.');
      }
      return false;
    }
  }
}
