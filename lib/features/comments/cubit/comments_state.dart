part of 'comments_cubit.dart';

sealed class CommentsState {}

class CommentsInitial extends CommentsState {}

class CommentsUiChanged extends CommentsState {}

class AddingComment extends CommentsState {}

class CommentOptimisticAdded extends CommentsState {
  final String postId;
  final CommentModel comment;
  final String? parentId;

  CommentOptimisticAdded(this.postId, this.comment, this.parentId);
}

class CommentTempIdResolved extends CommentsState {
  final String postId;
  final String tempId;
  final String realId;

  CommentTempIdResolved({
    required this.postId,
    required this.tempId,
    required this.realId,
  });
}

class CommentReactionOptimistic extends CommentsState {
  final String postId;
  final String commentId;
  final String emoji;

  CommentReactionOptimistic({
    required this.postId,
    required this.commentId,
    required this.emoji,
  });
}

class CommentError extends CommentsState {
  final String message;
  CommentError(this.message);
}
