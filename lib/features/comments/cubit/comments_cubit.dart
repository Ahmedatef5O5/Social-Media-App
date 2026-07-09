import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../auth/data/models/user_data.dart';
import '../../notifications/repository/notifications_repository.dart';
import '../events/comment_event_bus.dart';
import '../events/comment_events.dart';
import '../model/comment_model.dart';
import '../../posts/model/post_model.dart';
import '../services/comments_service.dart';
part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  final CommentsService _commentsService;
  final UserData? currentUserData;

  CommentsCubit({
    required CommentsService commentsService,
    this.currentUserData,
  }) : _commentsService = commentsService,
       super(CommentsInitial());

  final _eventBus = CommentEventBus.instance;

  final Set<String> collapsedComments = {};

  final Map<String, String> _resolvedIds = {};

  String resolveId(String id) => _resolvedIds[id] ?? id;

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

  Future<void> addComment({
    required PostModel post,
    required String commentText,
    String? parentCommentId,
  }) async {
    emit(AddingComment());

    final user = Supabase.instance.client.auth.currentUser;
    final tempId = const Uuid().v4();

    final resolvedParentId =
        parentCommentId != null ? resolveId(parentCommentId) : null;

    final newComment = CommentModel(
      id: tempId,
      createdAt: DateTime.now().toIso8601String(),
      authorId: user!.id,
      authorName: currentUserData?.name ?? 'User',
      authorImageUrl: currentUserData?.imageUrl,
      text: commentText,
      postId: post.id,
      parentCommentId: resolvedParentId,
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
      final realId = await _commentsService.addComment(
        postId: post.id,
        authorId: user.id,
        commentText: commentText,
        parentCommentId: resolvedParentId,
      );
      _resolvedIds[tempId] = realId;

      if (post.authorId != user.id) {
        await NotificationRepository.instance.notifyComment(
          receiverId: post.authorId,
          commenterId: user.id,
          commenterName: currentUserData?.name ?? 'unKnown',
          commenterImageUrl: currentUserData?.imageUrl ?? '',
          postId: post.id,
          commentPreview: commentText,
        );
      }

      emit(
        CommentTempIdResolved(postId: post.id, tempId: tempId, realId: realId),
      );
    } catch (e) {
      _resolvedIds.remove(tempId);
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(CommentError(e.toString(), isConnectivityError: isOffline));
    }
  }

  Future<void> toggleReaction({
    required String postId,
    required String commentId,
    required String commentOwnerId,
    required String emoji,
  }) async {
    final isOffline = await ConnectivityBannerController.notifyIfOffline();
    if (isOffline) return;
    final resolvedCommentId = resolveId(commentId);

    if (resolvedCommentId == commentId &&
        commentId.length == 36 &&
        _resolvedIds.values.contains(commentId) == false &&
        _isPossiblyTemp(commentId)) {
      debugPrint('⚠️ Reaction ignored: comment not yet saved to DB');
      return;
    }

    emit(
      CommentReactionOptimistic(
        postId: postId,
        commentId: resolvedCommentId,
        emoji: emoji,
      ),
    );

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await _commentsService.toggleCommentReaction(
        commentId: resolvedCommentId,
        userId: userId,
        emoji: emoji,
      );

      if (commentOwnerId != userId) {
        NotificationRepository.instance.notifyLike(
          receiverId: commentId,
          likerId: userId,
          likerName: currentUserData?.name ?? 'unKnown',
          likerImageUrl: currentUserData?.imageUrl ?? '',
          postId: postId,
        );
      }
    } catch (e) {
      debugPrint('Error toggling comment reaction: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(CommentError(e.toString(), isConnectivityError: isOffline));
    }
  }

  bool _isPossiblyTemp(String id) {
    return !_resolvedIds.containsValue(id);
  }
}
