import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../auth/data/models/user_data.dart';
import '../events/comment_event_bus.dart';
import '../events/comment_events.dart';
import '../../home/models/comment_model.dart';
import '../../home/models/post_model.dart';
import '../../home/services/home_services.dart';
part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit(this.homeServices, {this.currentUserData})
    : super(CommentsInitial());

  final HomeServices homeServices;
  final UserData? currentUserData;

  final _eventBus = CommentEventBus.instance;

  /// collapsed / expanded replies
  final Set<String> collapsedComments = {};

  // =========================
  // UI STATE
  // =========================

  void toggleReplies(String commentId) {
    if (collapsedComments.contains(commentId)) {
      collapsedComments.remove(commentId);
    } else {
      collapsedComments.add(commentId);
    }
    emit(CommentsUiChanged());
  }

  void resetCollapsedComments() {
    collapsedComments.clear();
    emit(CommentsUiChanged());
  }

  // =========================
  // ADD COMMENT
  // =========================
  Future<void> addComment({
    required PostModel post,
    required String commentText,
    String? parentCommentId,
  }) async {
    emit(AddingComment());

    final user = Supabase.instance.client.auth.currentUser;
    final tempId = const Uuid().v4();

    final newComment = CommentModel(
      id: tempId,
      createdAt: DateTime.now().toIso8601String(),
      authorId: user!.id,
      authorName: currentUserData?.name ?? 'User',
      authorImageUrl: currentUserData?.imageUrl,
      text: commentText,
      postId: post.id,
      parentCommentId: parentCommentId,
    );

    emit(CommentOptimisticAdded(post.id, newComment, parentCommentId));

    _eventBus.emit(
      CommentEvent(
        postId: post.id,
        comment: newComment,
        parentId: parentCommentId,
        authorName: currentUserData?.name ?? 'User',
        authorImageUrl: currentUserData?.imageUrl ?? '',
      ),
    );

    try {
      final realId = await homeServices.commentServices.addComment(
        postId: post.id,
        authorId: user.id,
        commentText: commentText,
        parentCommentId: parentCommentId,
      );

      emit(
        CommentTempIdResolved(postId: post.id, tempId: tempId, realId: realId),
      );
    } catch (e) {
      emit(CommentError(e.toString()));
    }
  }

  // =========================
  // REACTIONS
  // =========================

  Future<void> toggleReaction({
    required String postId,
    required String commentId,
    required String emoji,
  }) async {
    emit(
      CommentReactionOptimistic(
        postId: postId,
        commentId: commentId,
        emoji: emoji,
      ),
    );

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await homeServices.commentServices.toggleCommentReaction(
        commentId: commentId,
        userId: userId,
        emoji: emoji,
      );
    } catch (e) {
      emit(CommentError(e.toString()));
    }
  }
}
