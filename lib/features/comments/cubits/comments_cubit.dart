import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../auth/data/models/user_data.dart';
import '../../notifications/repository/notifications_repository.dart';
import '../../../core/services/fcm_services.dart';
import '../events/comment_event_bus.dart';
import '../events/comment_events.dart';
import '../models/comment_attachment_draft.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../models/comment_model.dart';
import '../models/comment_sort_option.dart';
import '../models/comment_type.dart';
import '../../posts/models/post_model.dart';
import '../models/comment_typing_user.dart';
import '../services/comments_service.dart';
part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  final CommentsService _commentsService;
  final MediaCacheRepository _mediaCacheRepository;
  final UserData? currentUserData;

  CommentsCubit({
    required CommentsService commentsService,
    required MediaCacheRepository mediaCacheRepository,
    this.currentUserData,
  }) : _commentsService = commentsService,
       _mediaCacheRepository = mediaCacheRepository,
       super(CommentsInitial());

  StreamSubscription? _realtimeSubscription;
  Timer? _realtimeDebounce;

  final _eventBus = CommentEventBus.instance;

  final Set<String> expandedComments = {};

  // ── Pending (buffered) comments — jank prevention + "New Comments" pill ──
  List<CommentModel>? pendingComments;
  int pendingCommentsCount = 0;
  bool _isNearEdge = true;

  void setNearEdge(bool value) {
    if (_isNearEdge == value) return;
    _isNearEdge = value;
    if (value && pendingComments != null) {
      mergePendingComments();
    }

    if (!isClosed) emit(CommentsUiChanged());
  }

  bool get isNearEdge => _isNearEdge;

  void mergePendingComments() {
    if (pendingComments == null) return;
    comments = pendingComments!;
    pendingComments = null;
    pendingCommentsCount = 0;
    emit(CommentsUiChanged());
  }

  ({CommentModel comment, String? parentId})? firstPendingComment() {
    final pending = pendingComments;
    if (pending == null) return null;

    final existingIds = <String>{};
    void collectIds(CommentModel node) {
      existingIds.add(node.id);
      for (final reply in node.replies) {
        collectIds(reply);
      }
    }

    for (final c in comments) {
      collectIds(c);
    }

    ({CommentModel comment, String? parentId})? search(
      CommentModel node,
      String? parentId,
    ) {
      if (!existingIds.contains(node.id)) {
        return (comment: node, parentId: parentId);
      }
      for (final reply in node.replies) {
        final found = search(reply, node.id);
        if (found != null) return found;
      }
      return null;
    }

    for (final c in pending) {
      final found = search(c, null);
      if (found != null) return found;
    }
    return null;
  }

  /// Makes sure every ancestor of [commentId] is expanded, so a reply that
  /// was posted under a currently-collapsed thread becomes visible before we
  /// try to scroll to it.
  void expandAncestorsOf(String commentId) {
    final path = _ancestorPathOf(commentId);
    bool changed = false;
    for (final ancestorId in path) {
      if (!expandedComments.contains(ancestorId)) {
        expandedComments.add(ancestorId);
        changed = true;
      }
    }
    if (changed && !isClosed) emit(CommentsUiChanged());
  }

  List<String> _ancestorPathOf(String commentId) {
    List<String>? search(CommentModel node, List<String> pathSoFar) {
      if (node.id == commentId) return pathSoFar;
      for (final reply in node.replies) {
        final found = search(reply, [...pathSoFar, node.id]);
        if (found != null) return found;
      }
      return null;
    }

    for (final c in comments) {
      final found = search(c, []);
      if (found != null) return found;
    }
    return [];
  }

  // ── Typing indicator (ephemeral, Realtime Broadcast — no DB table) ──
  RealtimeChannel? _channel;
  final Map<String, CommentTypingUser> typingUsersById = {};
  final Map<String, Timer> _typingExpiryTimers = {};
  DateTime? _lastTypingSentAt;

  void sendTypingSignal(String postId) {
    final now = DateTime.now();
    if (_lastTypingSentAt != null &&
        now.difference(_lastTypingSentAt!) < const Duration(seconds: 2)) {
      return; // client-side throttle, avoids flooding the channel
    }
    _lastTypingSentAt = now;
    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'userId': SupabaseProvider.id,
        'name': currentUserData?.name ?? 'Someone',
        'imageUrl': currentUserData?.imageUrl ?? '',
      },
    );
  }

  void sendStoppedTypingSignal(String postId) {
    _lastTypingSentAt = null;
    _channel?.sendBroadcastMessage(
      event: 'stopped_typing',
      payload: {'userId': SupabaseProvider.id},
    );
  }

  void _handleTypingBroadcast(Map<String, dynamic> payload) {
    final userId = payload['userId'] as String?;
    if (userId == null || userId == SupabaseProvider.id) return;

    typingUsersById[userId] = CommentTypingUser(
      id: userId,
      name: payload['name'] as String? ?? 'Someone',
      imageUrl: payload['imageUrl'] as String?,
    );

    _typingExpiryTimers[userId]?.cancel();
    _typingExpiryTimers[userId] = Timer(const Duration(seconds: 4), () {
      typingUsersById.remove(userId);
      _typingExpiryTimers.remove(userId);
      if (!isClosed) emit(CommentTypingUsersChanged());
    });

    if (!isClosed) emit(CommentTypingUsersChanged());
  }

  void _handleStoppedTypingBroadcast(Map<String, dynamic> payload) {
    final userId = payload['userId'] as String?;
    if (userId == null) return;
    if (typingUsersById.remove(userId) != null) {
      _typingExpiryTimers.remove(userId)?.cancel();
      if (!isClosed) emit(CommentTypingUsersChanged());
    }
  }

  final Map<String, String> _resolvedIds = {};

  final Set<String> _pendingCommentIds = {};

  final Map<String, String> _pendingReactions = {};
  final Set<String> _pendingDeletes = {};

  String resolveId(String id) => _resolvedIds[id] ?? id;

  void listenToCommentsRealtime(String postId) {
    _realtimeSubscription?.cancel();
    _realtimeDebounce?.cancel();

    final channel = SupabaseProvider.client.channel('comments_sheet_$postId');
    _channel = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.comments,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: CommentColumns.postId,
            value: postId,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert ||
                payload.eventType == PostgresChangeEvent.delete) {
              _scheduleSilentReload(postId);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comment_reactions',
          callback: (payload) {
            final record =
                payload.eventType == PostgresChangeEvent.delete
                    ? payload.oldRecord
                    : payload.newRecord;
            final affectedCommentId = record['comment_id'] as String?;
            if (affectedCommentId != null &&
                _belongsToLoadedComments(affectedCommentId)) {
              _scheduleSilentReload(postId);
            }
          },
        )
        .onBroadcast(event: 'typing', callback: _handleTypingBroadcast)
        .onBroadcast(
          event: 'stopped_typing',
          callback: _handleStoppedTypingBroadcast,
        )
        .subscribe();
  }

  void _scheduleSilentReload(String postId) {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 300), () {
      if (isClosed) return;
      _silentReload(postId);
    });
  }

  Future<void> _silentReload(String postId) async {
    try {
      final freshComments = await _commentsService.getComments(
        postId: postId,
        sort: currentSort,
      );
      if (isClosed) return;

      final currentCount = countAllComments(comments);
      final freshCount = countAllComments(freshComments);

      // Buffer only on genuine growth (new insert) while the user is mid-scroll.
      // Reaction-only updates or deletions never grow the count, so they always
      // apply immediately — there's nothing "new" to show a pill for.
      if (!_isNearEdge && freshCount > currentCount) {
        pendingComments = freshComments;
        pendingCommentsCount = freshCount - currentCount;
        emit(CommentsPendingChanged());
        return;
      }

      comments = freshComments;
      pendingComments = null;
      pendingCommentsCount = 0;
      emit(CommentsUiChanged());
    } catch (e) {
      debugPrint('Realtime comments sync error: $e');
    }
  }

  String? _findCommentAuthorId(String commentId) {
    String? search(CommentModel node) {
      if (node.id == commentId) return node.authorId;
      for (final reply in node.replies) {
        final found = search(reply);
        if (found != null) return found;
      }
      return null;
    }

    for (final c in comments) {
      final found = search(c);
      if (found != null) return found;
    }
    return null;
  }

  bool _belongsToLoadedComments(String commentId) {
    bool contains(CommentModel node) {
      if (node.id == commentId) return true;
      for (final reply in node.replies) {
        if (contains(reply)) return true;
      }
      return false;
    }

    return comments.any(contains);
  }

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
    if (expandedComments.contains(commentId)) {
      expandedComments.remove(commentId);
    } else {
      expandedComments.add(commentId);
    }
    emit(CommentsUiChanged());
  }

  void resetExpandedComments() {
    expandedComments.clear();
    emit(CommentsUiChanged());
  }

  CommentAttachmentDraft? pendingAttachment;
  double uploadProgress = 0;
  final Map<String, ValueNotifier<double>> commentUploadProgress = {};
  bool isUploading = false;
  dio_pkg.CancelToken? _uploadCancelToken;

  ValueNotifier<double> progressNotifierFor(String commentId) {
    return commentUploadProgress.putIfAbsent(
      commentId,
      () => ValueNotifier<double>(0),
    );
  }

  void _disposeProgressNotifier(String commentId) {
    commentUploadProgress.remove(commentId)?.dispose();
  }

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
    listenToCommentsRealtime(postId);
    final targetSort = sort ?? currentSort;
    currentSort = targetSort;
    isLoadingComments = true;
    emit(CommentsListLoading());

    try {
      final freshComments = await _commentsService.getComments(
        postId: postId,
        sort: targetSort,
      );
      if (isClosed) return;
      comments = freshComments;
      isLoadingComments = false;
      emit(CommentsListLoaded());
    } catch (e) {
      if (isClosed) return;
      isLoadingComments = false;
      debugPrint('Error loading comments: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isClosed) return;
      emit(
        CommentError(
          SupabaseErrorMapper.toUserMessage(e),
          isConnectivityError: isOffline,
        ),
      );
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

  CommentModel _replaceCommentInTree(
    CommentModel node,
    String targetId,
    CommentModel replacement,
  ) {
    if (node.id == targetId) return replacement;
    if (node.replies.isEmpty) return node;
    return node.copyWith(
      replies:
          node.replies
              .map((r) => _replaceCommentInTree(r, targetId, replacement))
              .toList(),
    );
  }

  void _updateCommentLocally(CommentModel comment, String? parentId) {
    comments =
        comments
            .map((c) => _replaceCommentInTree(c, comment.id, comment))
            .toList();
  }

  CommentModel? _removeCommentFromTree(CommentModel node, String targetId) {
    if (node.replies.any((r) => r.id == targetId)) {
      return node.copyWith(
        replies: node.replies.where((r) => r.id != targetId).toList(),
      );
    }
    if (node.replies.isEmpty) return node;
    return node.copyWith(
      replies:
          node.replies
              .map((r) => _removeCommentFromTree(r, targetId) ?? r)
              .toList(),
    );
  }

  void _removeCommentLocally(String commentId, String? parentId) {
    if (parentId == null) {
      comments = comments.where((c) => c.id != commentId).toList();
    } else {
      comments =
          comments
              .map((c) => _removeCommentFromTree(c, commentId) ?? c)
              .toList();
    }
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

    final user = SupabaseProvider.user;
    final tempId = const Uuid().v4();
    _pendingCommentIds.add(tempId);

    final resolvedParentId =
        parentCommentId != null ? resolveId(parentCommentId) : null;

    final bool isMediaAttachment =
        attachment != null &&
        (attachment.type == CommentType.image ||
            attachment.type == CommentType.video) &&
        attachment.needsUpload;

    CommentType commentType = attachment?.type ?? CommentType.text;
    String? imageUrl, videoUrl, voiceUrl, fileUrl;
    String? imagePublicId, videoPublicId, voicePublicId, filePublicId;
    String? fileName = attachment?.fileName;
    int? fileSizeBytes = attachment?.fileSizeBytes;
    int? durationSeconds = attachment?.durationSeconds;

    CommentModel? optimisticComment;
    if (isMediaAttachment) {
      optimisticComment = CommentModel(
        id: tempId,
        createdAt: DateTime.now().toIso8601String(),
        authorId: user!.id,
        authorName: currentUserData?.name ?? 'User',
        authorImageUrl: currentUserData?.imageUrl,
        text: trimmedText,
        postId: post.id,
        parentCommentId: resolvedParentId,
        commentType: commentType,
        imageUrl:
            commentType == CommentType.image
                ? attachment.localFile!.path
                : null,
        videoUrl:
            commentType == CommentType.video
                ? attachment.localFile!.path
                : null,
        fileSizeBytes: fileSizeBytes,
        durationSeconds: durationSeconds,
        mentions: mentions,
      );
      _insertCommentLocally(optimisticComment, resolvedParentId);
      if (isClosed) return;
      emit(CommentOptimisticAdded(post.id, optimisticComment, parentCommentId));
    }

    try {
      if (attachment != null) {
        if (attachment.needsUpload) {
          isUploading = true;
          uploadProgress = 0;
          _uploadCancelToken = dio_pkg.CancelToken();
          if (!isMediaAttachment && !isClosed) emit(ComposerUploadProgress(0));

          String prefix = '${attachment.type.value}_';
          if (attachment.type == CommentType.file &&
              attachment.fileName != null) {
            final originalName = attachment.fileName!;
            final nameWithoutExt =
                originalName.contains('.')
                    ? originalName.substring(0, originalName.lastIndexOf('.'))
                    : originalName;
            final safeName = nameWithoutExt.replaceAll(
              RegExp(r'[^a-zA-Z0-9\-_]'),
              '_',
            );
            prefix = '${safeName}_';
          }

          final result = await CloudinaryStorageServices.instance.uploadFile(
            attachment.localFile!,
            'comments',
            post.id,
            filePrefix: prefix,
            cancelToken: _uploadCancelToken,
            onProgress: (progress) {
              uploadProgress = progress;
              if (isMediaAttachment) {
                progressNotifierFor(tempId).value = progress;
              } else {
                if (!isClosed) emit(ComposerUploadProgress(progress));
              }
            },
          );

          switch (attachment.type) {
            case CommentType.image:
              imageUrl = result.secureUrl;
              imagePublicId = result.publicId;
              await _mediaCacheRepository.adoptUploadedFile(
                result.secureUrl,
                attachment.localFile!,
              );
              break;
            case CommentType.video:
              videoUrl = result.secureUrl;
              videoPublicId = result.publicId;
              await _mediaCacheRepository.adoptUploadedFile(
                result.secureUrl,
                attachment.localFile!,
              );
              break;
            case CommentType.voice:
              voiceUrl = result.secureUrl;
              voicePublicId = result.publicId;
              break;
            case CommentType.file:
              fileUrl = result.secureUrl;
              filePublicId = result.publicId;
              await _mediaCacheRepository.adoptUploadedFile(
                result.secureUrl,
                attachment.localFile!,
              );
              break;
            default:
              break;
          }
        } else {
          imageUrl = attachment.remoteUrl;
        }
      }

      isUploading = false;

      final newComment = (optimisticComment ??
              CommentModel(
                id: tempId,
                createdAt: DateTime.now().toIso8601String(),
                authorId: user!.id,
                authorName: currentUserData?.name ?? 'User',
                authorImageUrl: currentUserData?.imageUrl,
                text: trimmedText,
                postId: post.id,
                parentCommentId: resolvedParentId,
                commentType: commentType,
                mentions: mentions,
              ))
          .copyWith(
            imageUrl: imageUrl,
            videoUrl: videoUrl,
            voiceUrl: voiceUrl,
            fileUrl: fileUrl,
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
            durationSeconds: durationSeconds,
          );

      if (isClosed) return;

      clearAttachment();

      if (isMediaAttachment) {
        _updateCommentLocally(newComment, resolvedParentId);
        emit(CommentOptimisticAdded(post.id, newComment, parentCommentId));
        _disposeProgressNotifier(tempId);
      } else {
        _insertCommentLocally(newComment, resolvedParentId);
        emit(CommentOptimisticAdded(post.id, newComment, parentCommentId));
      }

      _eventBus.emit(
        CommentAddedEvent(
          postId: post.id,
          comment: newComment,
          parentId: parentCommentId,
          authorName: currentUserData?.name ?? 'User',
          authorImageUrl: currentUserData?.imageUrl ?? '',
        ),
      );

      final realId = await _commentsService.addComment(
        postId: post.id,
        authorId: user!.id,
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
      _eventBus.emit(
        CommentIdResolvedEvent(postId: post.id, tempId: tempId, realId: realId),
      );
      _pendingCommentIds.remove(tempId);

      if (_pendingDeletes.remove(tempId)) {
        _pendingReactions.remove(tempId);
        try {
          await _commentsService.deleteComment(commentId: realId);
        } catch (e) {
          debugPrint('Error deleting comment after id resolution: $e');
        }
        if (isClosed) return;
        emit(
          CommentTempIdResolved(
            postId: post.id,
            tempId: tempId,
            realId: realId,
          ),
        );
        return;
      }

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

      final String previewText =
          trimmedText.isEmpty ? '📎 Attachment' : trimmedText;
      if (resolvedParentId == null) {
        if (post.authorId != user.id) {
          unawaited(
            FcmService.instance.notifyPostComment(
              receiverId: post.authorId,
              actorId: user.id,
              actorName: currentUserData?.name ?? 'Someone',
              actorImageUrl: currentUserData?.imageUrl ?? '',
              postId: post.id,
              commentText: previewText,
            ),
          );
        }
      } else {
        final parentAuthorId = _findCommentAuthorId(resolvedParentId);
        if (parentAuthorId != null && parentAuthorId != user.id) {
          unawaited(
            FcmService.instance.notifyCommentReply(
              receiverId: parentAuthorId,
              actorId: user.id,
              actorName: currentUserData?.name ?? 'Someone',
              actorImageUrl: currentUserData?.imageUrl ?? '',
              postId: post.id,
              commentId: realId,
              commentText: previewText,
            ),
          );
        }
      }

      for (final mention in mentions) {
        unawaited(
          FcmService.instance.notifyMention(
            receiverId: mention.mentionedUserId,
            actorId: user.id,
            actorName: currentUserData?.name ?? 'Someone',
            actorImageUrl: currentUserData?.imageUrl ?? '',
            context: 'post',
            postId: post.id,
          ),
        );
      }

      if (isClosed) return;
      emit(
        CommentTempIdResolved(postId: post.id, tempId: tempId, realId: realId),
      );
    } on UploadCanceledException {
      isUploading = false;
      if (isMediaAttachment) {
        _removeCommentLocally(tempId, resolvedParentId);
        _disposeProgressNotifier(tempId);
        if (!isClosed) emit(CommentsUiChanged());
      }
      _pendingCommentIds.remove(tempId);
      _pendingReactions.remove(tempId);
      if (!isClosed) emit(ComposerAttachmentUpdated());
    } catch (e) {
      isUploading = false;
      if (isMediaAttachment) {
        _removeCommentLocally(tempId, resolvedParentId);
        _disposeProgressNotifier(tempId);
      }
      _resolvedIds.remove(tempId);
      _pendingCommentIds.remove(tempId);
      _pendingReactions.remove(tempId);
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isClosed) return;
      emit(
        CommentError(
          SupabaseErrorMapper.toUserMessage(e),
          isConnectivityError: isOffline,
        ),
      );
    }
  }

  Future<void> editComment({
    required String commentId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final resolvedId = resolveId(commentId);

    comments = comments.map((c) => _applyEdit(c, resolvedId, trimmed)).toList();
    if (!isClosed) emit(CommentsUiChanged());

    try {
      await _commentsService.editComment(
        commentId: commentId,
        newText: newText,
      );
    } catch (e) {
      debugPrint('Error editing comment: $e');
    }
  }

  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    final bool stillSaving = _pendingCommentIds.contains(commentId);

    if (stillSaving) {
      _pendingDeletes.add(commentId);
      _pendingReactions.remove(commentId);
    }

    final resolvedId = resolveId(commentId);
    final previousComments = comments;

    comments =
        comments
            .where((c) => c.id != resolvedId)
            .map((c) => _removeReplyById(c, resolvedId))
            .toList();
    if (!isClosed) emit(CommentsUiChanged());

    _eventBus.emit(CommentDeletedEvent(postId: postId, commentId: resolvedId));

    if (stillSaving) return;

    try {
      await _commentsService.deleteComment(commentId: resolvedId);
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      comments = previousComments;
      if (!isClosed) emit(CommentsUiChanged());
    }
  }

  CommentModel _removeReplyById(CommentModel node, String commentId) {
    if (node.replies.isEmpty) return node;
    return node.copyWith(
      replies:
          node.replies
              .where((r) => r.id != commentId)
              .map((r) => _removeReplyById(r, commentId))
              .toList(),
    );
  }

  CommentModel _applyEdit(CommentModel node, String commentId, String newText) {
    final updated =
        node.id == commentId
            ? node.copyWith(text: newText, isEdited: true)
            : node;
    if (updated.replies.isEmpty) return updated;
    return updated.copyWith(
      replies:
          updated.replies
              .map(((r) => _applyEdit(r, commentId, newText)))
              .toList(),
    );
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

    comments =
        comments
            .map((c) => _updateReactionInTree(c, resolvedCommentId, emoji))
            .toList();
    if (!isClosed) emit(CommentsUiChanged());

    try {
      final userId = SupabaseProvider.id;
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
        unawaited(
          FcmService.instance.notifyCommentReact(
            receiverId: commentOwnerId,
            actorId: userId,
            actorName: currentUserData?.name ?? 'Someone',
            actorImageUrl: currentUserData?.imageUrl ?? '',
            postId: postId,
            commentId: resolvedCommentId,
            reactionType: emoji,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling comment reaction: $e');
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isClosed) return;
      emit(
        CommentError(
          SupabaseErrorMapper.toUserMessage(e),
          isConnectivityError: isOffline,
        ),
      );
    }
  }

  CommentModel _updateReactionInTree(
    CommentModel node,
    String commentId,
    String emoji,
  ) {
    if (node.id == commentId) {
      return node.copyWith(reactions: _toggledReactions(node.reactions, emoji));
    }
    if (node.replies.isEmpty) return node;
    return node.copyWith(
      replies:
          node.replies
              .map((r) => _updateReactionInTree(r, commentId, emoji))
              .toList(),
    );
  }

  List<CommentReaction> _toggledReactions(
    List<CommentReaction> current,
    String emoji,
  ) {
    final updated = List<CommentReaction>.from(current);
    final myIdx = updated.indexWhere((r) => r.reactedByMe);
    if (myIdx >= 0) {
      final old = updated[myIdx];
      if (old.emoji == emoji) {
        old.count <= 1
            ? updated.removeAt(myIdx)
            : updated[myIdx] = old.copyWith(
              count: old.count - 1,
              reactedByMe: false,
            );
      } else {
        old.count <= 1
            ? updated.removeAt(myIdx)
            : updated[myIdx] = old.copyWith(
              count: old.count - 1,
              reactedByMe: false,
            );
        final ni = updated.indexWhere((r) => r.emoji == emoji);
        ni >= 0
            ? updated[ni] = updated[ni].copyWith(
              count: updated[ni].count + 1,
              reactedByMe: true,
            )
            : updated.add(
              CommentReaction(emoji: emoji, count: 1, reactedByMe: true),
            );
      }
    } else {
      final ni = updated.indexWhere((r) => r.emoji == emoji);
      ni >= 0
          ? updated[ni] = updated[ni].copyWith(
            count: updated[ni].count + 1,
            reactedByMe: true,
          )
          : updated.add(
            CommentReaction(emoji: emoji, count: 1, reactedByMe: true),
          );
    }
    return updated;
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    _realtimeDebounce?.cancel();
    _uploadCancelToken?.cancel();
    for (final notifier in commentUploadProgress.values) {
      notifier.dispose();
    }
    for (final timer in _typingExpiryTimers.values) {
      timer.cancel();
    }
    if (_channel != null) {
      SupabaseProvider.client.removeChannel(_channel!);
    }
    return super.close();
  }
}
