import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../auth/data/models/user_data.dart';
import '../../notifications/repository/notifications_repository.dart';
import '../events/comment_event_bus.dart';
import '../events/comment_events.dart';
import '../model/comment_attachment_draft.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../model/comment_model.dart';
import '../model/comment_sort_option.dart';
import '../model/comment_type.dart';
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

  final Set<String> _pendingCommentIds = {};

  final Map<String, String> _pendingReactions = {};

  String resolveId(String id) => _resolvedIds[id] ?? id;

  void _replaceCommentIdEverywhere(String tempId, String realId) {
    comments = comments.map((c) => _replaceId(c, tempId, realId)).toList();
  }

  CommentModel _replaceId(CommentModel node, String tempId, String realId) {
    final updated = node.id == tempId ? node.copyWith(id: realId) : node;
    if (updated.replies.isEmpty) return updated;
    return updated.copyWith(
      replies:
          updated.replies.map((r) => _replaceId(r, tempId, realId)).toList(),
    );
  }

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

  CommentAttachmentDraft? pendingAttachment;
  double uploadProgress = 0;
  bool isUploading = false;
  dio_pkg.CancelToken? _uploadCancelToken;

  void stageAttachment(CommentAttachmentDraft draft) {
    pendingAttachment = draft;
    emit(ComposerAttachmentUpdated());
  }

  void updateAttachmentDuration(int seconds) {
    if (pendingAttachment == null) return;
    pendingAttachment = pendingAttachment!.copyWith(durationSeconds: seconds);
  }

  void clearAttachment() {
    _uploadCancelToken?.cancel();
    _uploadCancelToken = null;
    pendingAttachment = null;
    uploadProgress = 0;
    isUploading = false;
    emit(ComposerAttachmentUpdated());
  }

  void cancelUpload() => _uploadCancelToken?.cancel();

  List<CommentModel> comments = [];
  CommentSortOption currentSort = CommentSortOption.newest;
  bool isLoadingComments = true;

  Future<void> loadComments({
    required String postId,
    CommentSortOption? sort,
  }) async {
    final targetSort = sort ?? currentSort;
    currentSort = targetSort;
    isLoadingComments = true;
    emit(CommentsListLoading());

    try {
      comments = await _commentsService.getComments(
        postId: postId,
        sort: targetSort,
      );
      isLoadingComments = false;
      emit(CommentsListLoaded());
    } catch (e) {
      isLoadingComments = false;
      debugPrint('Error loading comments: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      emit(CommentError(e.toString(), isConnectivityError: isOffline));
    }
  }

  void _insertCommentLocally(CommentModel comment, String? parentId) {
    if (parentId == null) {
      comments =
          currentSort == CommentSortOption.newest
              ? [comment, ...comments]
              : [...comments, comment];
    } else {
      comments =
          comments.map((c) => _attachReply(c, parentId, comment)).toList();
    }
  }

  CommentModel _attachReply(
    CommentModel node,
    String parentId,
    CommentModel reply,
  ) {
    if (node.id == parentId) {
      return node.copyWith(replies: [...node.replies, reply]);
    }
    if (node.replies.isEmpty) return node;
    return node.copyWith(
      replies:
          node.replies.map((r) => _attachReply(r, parentId, reply)).toList(),
    );
  }

  Future<void> addComment({
    required PostModel post,
    String commentText = '',
    String? parentCommentId,
    List<MentionRef> mentions = const [],
  }) async {
    final attachment = pendingAttachment;
    final trimmedText = commentText.trim();
    if (trimmedText.isEmpty && attachment == null) return;

    emit(AddingComment());

    final user = Supabase.instance.client.auth.currentUser;
    final tempId = const Uuid().v4();
    _pendingCommentIds.add(tempId);

    final resolvedParentId =
        parentCommentId != null ? resolveId(parentCommentId) : null;

    CommentType commentType = CommentType.text;
    String? imageUrl, videoUrl, voiceUrl, fileUrl;
    String? imagePublicId, videoPublicId, voicePublicId, filePublicId;
    String? fileName;
    int? fileSizeBytes, durationSeconds;

    try {
      if (attachment != null) {
        commentType = attachment.type;
        fileName = attachment.fileName;
        fileSizeBytes = attachment.fileSizeBytes;
        durationSeconds = attachment.durationSeconds;

        if (attachment.needsUpload) {
          isUploading = true;
          uploadProgress = 0;
          _uploadCancelToken = dio_pkg.CancelToken();
          emit(ComposerUploadProgress(0));

          final result = await CloudinaryStorageServices.instance.uploadFile(
            attachment.localFile!,
            'comments',
            post.id,
            filePrefix: '${attachment.type.value}_',
            cancelToken: _uploadCancelToken,
            onProgress: (progress) {
              uploadProgress = progress;
              emit(ComposerUploadProgress(progress));
            },
          );

          switch (attachment.type) {
            case CommentType.image:
              imageUrl = result.secureUrl;
              imagePublicId = result.publicId;
              break;
            case CommentType.video:
              videoUrl = result.secureUrl;
              videoPublicId = result.publicId;
              break;
            case CommentType.voice:
              voiceUrl = result.secureUrl;
              voicePublicId = result.publicId;
              break;
            case CommentType.file:
              fileUrl = result.secureUrl;
              filePublicId = result.publicId;
              break;
            default:
              break;
          }
        } else {
          imageUrl = attachment.remoteUrl;
        }
      }

      isUploading = false;

      final newComment = CommentModel(
        id: tempId,
        createdAt: DateTime.now().toIso8601String(),
        authorId: user!.id,
        authorName: currentUserData?.name ?? 'User',
        authorImageUrl: currentUserData?.imageUrl,
        text: trimmedText,
        postId: post.id,
        parentCommentId: resolvedParentId,
        commentType: commentType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        voiceUrl: voiceUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        durationSeconds: durationSeconds,
        mentions: mentions,
      );

      clearAttachment();
      _insertCommentLocally(newComment, resolvedParentId);
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

      final realId = await _commentsService.addComment(
        postId: post.id,
        authorId: user.id,
        commentText: trimmedText.isEmpty ? null : trimmedText,
        parentCommentId: resolvedParentId,
        commentType: commentType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        voiceUrl: voiceUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        durationSeconds: durationSeconds,
        imagePublicId: imagePublicId,
        videoPublicId: videoPublicId,
        voicePublicId: voicePublicId,
        filePublicId: filePublicId,
        mentions: mentions,
      );
      _resolvedIds[tempId] = realId;
      _replaceCommentIdEverywhere(tempId, realId);
      _pendingCommentIds.remove(tempId);
      final queuedEmoji = _pendingReactions.remove(tempId);
      if (queuedEmoji != null) {
        await toggleReaction(
          postId: post.id,
          commentId: realId,
          commentOwnerId: user.id,
          emoji: queuedEmoji,
        );
      }

      if (post.authorId != user.id) {
        await NotificationRepository.instance.notifyComment(
          receiverId: post.authorId,
          commenterId: user.id,
          commenterName: currentUserData?.name ?? 'unKnown',
          commenterImageUrl: currentUserData?.imageUrl ?? '',
          postId: post.id,
          commentPreview: trimmedText.isEmpty ? '📎 Attachment' : trimmedText,
        );
      }

      emit(
        CommentTempIdResolved(postId: post.id, tempId: tempId, realId: realId),
      );
    } on UploadCanceledException {
      isUploading = false;
      _pendingCommentIds.remove(tempId);
      _pendingReactions.remove(tempId);
      emit(ComposerAttachmentUpdated());
    } catch (e) {
      isUploading = false;
      _resolvedIds.remove(tempId);
      _pendingCommentIds.remove(tempId);
      _pendingReactions.remove(tempId);
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

    if (_pendingCommentIds.contains(commentId)) {
      if (_pendingReactions[commentId] == emoji) {
        _pendingReactions.remove(commentId);
      } else {
        _pendingReactions[commentId] = emoji;
      }
      debugPrint(
        '⏳ Reaction queued: comment still saving, will apply once ready',
      );
      return;
    }

    final resolvedCommentId = resolveId(commentId);

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
          receiverId: commentOwnerId,
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
}
