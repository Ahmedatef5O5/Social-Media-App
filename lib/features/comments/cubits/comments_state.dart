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

class CommentError extends CommentsState {
  final String message;
  final bool isConnectivityError;
  CommentError(this.message, {this.isConnectivityError = false});
}

class ComposerAttachmentUpdated extends CommentsState {}

class ComposerUploadProgress extends CommentsState {
  final double progress; // 0.0 to 1.0

  ComposerUploadProgress(this.progress);
}

class ComposerUploadError extends CommentsState {
  final String message;

  ComposerUploadError(this.message);
}

// ── Sorted comments list (Functional Sorting & Filters) ──

class CommentsListLoading extends CommentsState {}

class CommentsListLoaded extends CommentsState {}

//  pending (buffered) comments waiting to be merged into view ──
class CommentsPendingChanged extends CommentsState {}

// someone started/stopped typing a comment on this post ──
class CommentTypingUsersChanged extends CommentsState {}
