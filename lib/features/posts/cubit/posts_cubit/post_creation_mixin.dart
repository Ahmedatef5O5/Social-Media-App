part of 'posts_cubit.dart';

mixin PostCreationMixin on Cubit<PostsState> {
  CloudinaryStorageServices get _storage;
  PostsServices get _postsServices;
  Future<void> fetchPosts({bool isRefresh});
  UserData? get currentUserData;
  List<PostModel> cachedPosts = [];
  final filePickerServices = FilePickerServices();
  XFile? selectedDocument;
  XFile? selectedImage;
  XFile? selectedVideo;
  int? selectedImageSizeBytes;
  int? selectedVideoSizeBytes;
  int? selectedDocumentSizeBytes;
  dio_pkg.CancelToken? _cancelToken;

  Future<void> createPost({
    required String text,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
    List<MentionRef> mentions = const [],
  }) async {
    final user = SupabaseProvider.user;
    if (user == null) return;
    final userId = user.id;

    emit(const PostCreating(0.0));

    _cancelToken = dio_pkg.CancelToken();

    String? imageUrl, videoUrl, fileUrl;
    // ignore: unused_local_variable
    String? imagePublicId, videoPublicId, filePublicId;
    int? mediaWidth, mediaHeight;

    try {
      void updateProgress(int sentBytes, int totalBytes) {
        if (state is! PostCreating) return;
        final ratio =
            totalBytes > 0 ? (sentBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
        emit(
          PostCreating(
            ratio.clamp(0.05, 0.95),
            sentBytes: sentBytes,
            totalBytes: totalBytes,
          ),
        );
      }

      if (selectedImage != null) {
        final imageFile = File(selectedImage!.path);
        if (await imageFile.exists()) {
          final result = await _storage.uploadFile(
            imageFile,
            'posts',
            'images',
            cancelToken: _cancelToken,
            onProgressBytes: updateProgress,
          );
          imageUrl = result.secureUrl;
          imagePublicId = result.publicId;
          mediaWidth = result.width;
          mediaHeight = result.height;
        } else {
          throw Exception('image_not_found');
        }
      }

      if (selectedVideo != null) {
        final videoFile = File(selectedVideo!.path);
        if (await videoFile.exists()) {
          final result = await _storage.uploadFile(
            videoFile,
            'posts',
            'videos',
            cancelToken: _cancelToken,
            onProgressBytes: updateProgress,
          );
          videoUrl = result.secureUrl;
          videoPublicId = result.publicId;
          mediaWidth = result.width ?? mediaWidth;
          mediaHeight = result.height ?? mediaHeight;
        } else {
          throw Exception('video_not_found');
        }
      }

      if (selectedDocument != null) {
        final docFile = File(selectedDocument!.path);
        if (await docFile.exists()) {
          final result = await _storage.uploadFile(
            docFile,
            'posts',
            'documents',
            cancelToken: _cancelToken,
            onProgressBytes: updateProgress,
          );

          fileUrl = result.secureUrl;
          filePublicId = result.publicId;
        } else {
          throw Exception("file_not_found");
        }
      }
      final postId = const Uuid().v4();
      final postRequest = PostRequestBody(
        id: postId,
        text: text,
        authorId: userId,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        fileUrl: fileUrl,
        imagePublicId: imagePublicId,
        videoPublicId: videoPublicId,
        filePublicId: filePublicId,
        mediaWidth: mediaWidth,
        mediaHeight: mediaHeight,
        privacyType: privacy,
      );
      await _postsServices.addPost(postRequest);
      if (privacy == ContentPrivacy.private && allowedViewerIds.isNotEmpty) {
        await _postsServices.setPostAllowedViewers(postId, allowedViewerIds);
      }

      if (mentions.isNotEmpty) {
        await _postsServices.insertPostMentions(
          postId: postId,
          mentions: mentions,
        );
        for (final mention in mentions) {
          unawaited(
            FcmService.instance.notifyMention(
              receiverId: mention.mentionedUserId,
              actorId: userId,
              actorName: currentUserData?.name ?? 'Someone',
              actorImageUrl: currentUserData?.imageUrl ?? '',
              context: 'post',
              postId: postId,
            ),
          );
        }
      }

      emit(PostCreating(1.0));
      await Future.delayed(const Duration(milliseconds: 2000));
      _resetMedia();
      emit(PostCreated());

      await fetchPosts(isRefresh: true);
    } catch (e) {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();

      final errorMessage = _mapExceptionToMessage(e);
      if (errorMessage == "upload_canceled") {
        emit(const PostUploadCanceled());
      } else {
        emit(PostCreateError(errorMessage, isConnectivityError: isOffline));
      }
    }
  }

  Future<bool> toggleSharePost(PostModel post) async {
    if (state is! PostsLoaded) return false;
    final userId = SupabaseProvider.idOrNull;
    if (userId == null) return false;

    final oldState = state as PostsLoaded;

    final PostModel targetPost = post.displayPost;
    final bool wasShared = targetPost.isSharedByMe;
    final int rawCount =
        wasShared ? targetPost.sharesCount - 1 : targetPost.sharesCount + 1;
    final int newCount = rawCount < 0 ? 0 : rawCount;

    final PostModel updatedTarget = targetPost.copyWith(
      isSharedByMe: !wasShared,
      sharesCount: newCount,
    );

    final String tempWrapperId =
        'temp_share_${DateTime.now().microsecondsSinceEpoch}';

    List<PostModel> updatedPosts =
        oldState.posts.map((p) {
          if (p.id == targetPost.id) return updatedTarget;
          if (p.originalPost?.id == targetPost.id) {
            return p.copyWith(originalPost: updatedTarget);
          }
          return p;
        }).toList();

    if (!wasShared) {
      final wrapperCard = PostModel(
        id: tempWrapperId,
        text: '',
        authorId: userId,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        authorName: currentUserData?.name,
        authorImageUrl: currentUserData?.imageUrl,
        sharedPostId: targetPost.id,
        originalPost: updatedTarget,
      );
      updatedPosts = [wrapperCard, ...updatedPosts];
    } else {
      updatedPosts =
          updatedPosts
              .where(
                (p) =>
                    !(p.sharedPostId == targetPost.id && p.authorId == userId),
              )
              .toList();
    }

    cachedPosts = updatedPosts;
    emit(PostsLoaded(updatedPosts, DateTime.now()));

    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();
      if (isOffline) {
        cachedPosts = oldState.posts;
        emit(PostsLoaded(oldState.posts, DateTime.now()));
        return false;
      }

      final result = await _postsServices.toggleSharePost(
        postId: targetPost.id,
      );
      final bool isSharedNow = result['is_shared'] as bool? ?? !wasShared;
      final String? realWrapperId = result['share_post_id'] as String?;

      if (isSharedNow && realWrapperId != null) {
        final bool realCardAlreadyArrived = cachedPosts.any(
          (p) => p.id == realWrapperId,
        );

        cachedPosts =
            realCardAlreadyArrived
                ? cachedPosts.where((p) => p.id != tempWrapperId).toList()
                : cachedPosts
                    .map(
                      (p) =>
                          p.id == tempWrapperId
                              ? p.copyWith(id: realWrapperId)
                              : p,
                    )
                    .toList();
        emit(PostsLoaded(cachedPosts, DateTime.now()));
      }

      if (isSharedNow && targetPost.authorId != userId) {
        await NotificationRepository.instance.notifyShare(
          receiverId: targetPost.authorId,
          sharerId: userId,
          sharerName: currentUserData?.name ?? 'unKnown',
          sharerImageUrl: currentUserData?.imageUrl ?? '',
          postId: targetPost.id,
        );
        unawaited(
          FcmService.instance.notifyPostReshare(
            receiverId: targetPost.authorId,
            actorId: userId,
            actorName: currentUserData?.name ?? 'Someone',
            actorImageUrl: currentUserData?.imageUrl ?? '',
            postId: targetPost.id,
          ),
        );
      }
      return true;
    } catch (e) {
      cachedPosts = oldState.posts;
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling share: $e');
      if (e.toString().contains('23503') ||
          e.toString().contains('not present in table')) {
        AppToast.info('This post is no longer available.');
      }
      return false;
    }
  }

  void cancelUpload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User canceled post upload');
    }
    emit(const PostUploadCanceled());
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postsServices.deletePost(postId);
      if (state is PostsLoaded) {
        final updatePosts =
            (state as PostsLoaded).posts
                .where((p) => p.id != postId && p.sharedPostId != postId)
                .toList();
        cachedPosts = updatePosts;
        emit(PostsLoaded(updatePosts, DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      emit(PostsError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  // ── Media picking (posts) ──────────────────────────────────────────────────

  Future<void> pickImageFromGallery() async {
    emit(MediaPicking());
    try {
      final image = await filePickerServices.pickImageFromGallery();
      if (image != null) {
        selectedImage = image;
        selectedImageSizeBytes = File(image.path).lengthSync();
        emit(MediaPicked(image));
      } else {
        _emitPreviousState();
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      emit(MediaPickingError(e.toString()));
    }
  }

  Future<void> takePhotoByCamera() async {
    emit(MediaPicking());
    try {
      final image = await filePickerServices.takePhotoByCamera();
      if (image != null) {
        selectedImage = image;
        selectedImageSizeBytes = File(image.path).lengthSync();
        emit(MediaPicked(image));
      } else {
        _emitPreviousState();
      }
    } catch (e) {
      debugPrint('Error taking image by camera: $e');
      emit(MediaPickingError(e.toString()));
    }
  }

  Future<void> pickVideo() async {
    emit(MediaPicking());
    try {
      final video = await filePickerServices.pickVideoFromGallery();
      if (video != null) {
        selectedVideo = video;
        selectedVideoSizeBytes = File(video.path).lengthSync();
        emit(MediaPicked(video));
      } else {
        _emitPreviousState();
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      emit(MediaPickingError(e.toString()));
    }
  }

  Future<void> pickDocument() async {
    emit(MediaPicking());
    try {
      final doc = await filePickerServices.pickFile();
      if (doc != null) {
        selectedDocument = doc;
        selectedDocumentSizeBytes = File(doc.path).lengthSync();
        emit(MediaPicked(doc));
      } else {
        _emitPreviousState();
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      emit(MediaPickingError(e.toString()));
    }
  }

  void attachExternalMedia({XFile? image, XFile? video, XFile? document}) {
    if (image != null) {
      selectedImage = image;
      selectedImageSizeBytes = File(image.path).lengthSync();
    } else if (video != null) {
      selectedVideo = video;
      selectedVideoSizeBytes = File(video.path).lengthSync();
    } else if (document != null) {
      selectedDocument = document;
      selectedDocumentSizeBytes = File(document.path).lengthSync();
    }
    emit(MediaPicked(image ?? video ?? document ?? XFile('')));
  }

  void _resetMedia() {
    selectedImage = null;
    selectedVideo = null;
    selectedDocument = null;
    selectedImageSizeBytes = null;
    selectedVideoSizeBytes = null;
    selectedDocumentSizeBytes = null;
  }

  void _emitPreviousState() {
    emit(MediaPickingError('Selection Cancelled'));
  }

  String _mapExceptionToMessage(Object e) {
    final error = e.toString().toLowerCase();
    if (error.contains('canceled') || error.contains('cancel')) {
      return "upload_canceled";
    }
    if (error.contains('pathnotfoundexception') ||
        error.contains('not_found')) {
      return "The selected file is no longer available. Please re-select it.";
    } else if (error.contains('socketexception') ||
        error.contains('connection reset')) {
      return "Connection lost. Please check your internet and try again.";
    } else if (error.contains('storage-byte-range-not-satisfiable')) {
      return "File size is too large or upload was interrupted.";
    } else if (error.contains('post_images/images')) {
      return "Storage error: Make sure you have permission to upload.";
    }
    return "Something went wrong. Please try again later.";
  }
}
