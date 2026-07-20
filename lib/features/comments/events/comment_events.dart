import '../model/comment_model.dart';

sealed class CommentEvent {
  final String postId;
  const CommentEvent({required this.postId});
}

class CommentAddedEvent extends CommentEvent {
  final CommentModel comment;
  final String? parentId;
  final String authorName;
  final String authorImageUrl;

  const CommentAddedEvent({
    required super.postId,
    required this.comment,
    this.parentId,
    required this.authorName,
    required this.authorImageUrl,
  });
}

class CommentIdResolvedEvent extends CommentEvent {
  final String tempId;
  final String realId;

  const CommentIdResolvedEvent({
    required super.postId,
    required this.tempId,
    required this.realId,
  });
}

class CommentDeletedEvent extends CommentEvent {
  final String commentId;

  const CommentDeletedEvent({required super.postId, required this.commentId});
}
