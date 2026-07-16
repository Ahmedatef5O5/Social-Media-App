part of 'posts_cubit.dart';

mixin PostReactionsMixin on Cubit<PostsState> {
  PostsServices get _postsServices;
  UserData? get currentUserData;

  Future<void> toggleReaction(PostModel post, {String emoji = 'like'}) async {
    if (state is! PostsLoaded) return;
    final user = SupabaseProvider.user;
    final userId = user?.id;
    if (userId == null) return;

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
      if (isOffline) return;
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
    } catch (e) {
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling reaction: $e');
    }
  }

  Future<void> toggleSavePost(PostModel post) async {
    if (state is! PostsLoaded) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return;

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
        return;
      }
      await _postsServices.toggleSavePost(
        postId: post.id,
        userId: userId,
        isCurrentlySaved: wasSaved,
      );
    } catch (e) {
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling saved post: $e');
    }
  }
}
