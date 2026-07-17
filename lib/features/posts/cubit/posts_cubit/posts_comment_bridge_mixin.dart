part of 'posts_cubit.dart';

mixin PostsCommentBridgeMixin on Cubit<PostsState> {
  final _eventBus = CommentEventBus.instance;
  StreamSubscription? _commentEventSub;

  void _listenToCommentEvents() {
    _commentEventSub = _eventBus.stream.listen((event) {
      switch (event) {
        case CommentAddedEvent():
          addCommentLocally(event.postId, event.comment, event.parentId);
        case CommentDeletedEvent():
          removeCommentLocally(event.postId, event.commentId);
      }
    });
  }

  void addCommentLocally(
    String postId,
    CommentModel comment,
    String? parentId,
  ) {
    if (state is! PostsLoaded) return;
    final oldState = state as PostsLoaded;

    final updatedPosts = oldState.posts.updatePostById(postId, (post) {
      List<CommentModel> updatedComments = List<CommentModel>.from(
        post.comments ?? const [],
      );

      if (parentId == null) {
        updatedComments.insert(0, comment);
      } else {
        bool isAdded = false;

        CommentModel attach(CommentModel node) {
          if (node.id == parentId) {
            isAdded = true;
            return node.copyWith(replies: [...node.replies, comment]);
          }
          if (node.replies.isEmpty) return node;
          return node.copyWith(
            replies: node.replies.map((r) => attach(r)).toList(),
          );
        }

        updatedComments = updatedComments.map((c) => attach(c)).toList();
        if (!isAdded) updatedComments.insert(0, comment);
      }
      return post.copyWith(comments: updatedComments);
    });

    emit(PostsLoaded(updatedPosts, DateTime.now()));
  }

  void removeCommentLocally(String postId, String commentId) {
    if (state is! PostsLoaded) return;
    final oldState = state as PostsLoaded;

    final updatedPosts = oldState.posts.updatePostById(postId, (post) {
      final updatedComments = _removeCommentById(
        List<CommentModel>.from(post.comments ?? const []),
        commentId,
      );
      return post.copyWith(comments: updatedComments);
    });

    emit(PostsLoaded(updatedPosts, DateTime.now()));
  }

  List<CommentModel> _removeCommentById(
    List<CommentModel> comments,
    String commentId,
  ) {
    return comments
        .where((c) => c.id != commentId)
        .map(
          (c) =>
              c.replies.isEmpty
                  ? c
                  : c.copyWith(
                    replies: _removeCommentById(c.replies, commentId),
                  ),
        )
        .toList();
  }

  @override
  Future<void> close() {
    _commentEventSub?.cancel();
    return super.close();
  }
}
