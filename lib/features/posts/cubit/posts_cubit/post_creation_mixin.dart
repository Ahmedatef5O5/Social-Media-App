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

  dio_pkg.CancelToken? _cancelToken;

  Future<void> createPost({
    required String text,
    ContentPrivacy privacy = ContentPrivacy.public,
    List<String> allowedViewerIds = const [],
  }) async {
    final user = SupabaseProvider.user;
    if (user == null) return;
    final userId = user.id;

    emit(const PostCreating(0.0));

    _cancelToken = dio_pkg.CancelToken();

    String? imageUrl, videoUrl, fileUrl;
    // ignore: unused_local_variable
    String? imagePublicId, videoPublicId, filePublicId;

    try {
      void updateProgress(double p) {
        if (state is PostCreating) {
          emit(PostCreating(p.clamp(0.05, 0.95)));
        }
      }

      if (selectedImage != null) {
        final imageFile = File(selectedImage!.path);
        if (await imageFile.exists()) {
          final result = await _storage.uploadFile(
            imageFile,
            'posts',
            'images',
            cancelToken: _cancelToken,
            onProgress: updateProgress,
          );
          imageUrl = result.secureUrl;
          imagePublicId = result.publicId;
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
            onProgress: updateProgress,
          );
          videoUrl = result.secureUrl;
          videoPublicId = result.publicId;
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
            onProgress: updateProgress,
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
        privacyType: privacy,
      );
      await _postsServices.addPost(postRequest);
      if (privacy == ContentPrivacy.private && allowedViewerIds.isNotEmpty) {
        await _postsServices.setPostAllowedViewers(postId, allowedViewerIds);
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

  Future<void> toggleSharePost(PostModel post) async {
    if (state is! PostsLoaded) return;
    final userId = SupabaseProvider.idOrNull;
    if (userId == null) return;

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
        return;
      }

      final result = await _postsServices.toggleSharePost(
        postId: targetPost.id,
      );
      final bool isSharedNow = result['is_shared'] as bool? ?? !wasShared;
      final String? realWrapperId = result['share_post_id'] as String?;

      if (isSharedNow && realWrapperId != null) {
        // Edge case: ممكن الـ Realtime يكون سبقنا وضاف الكارت الحقيقي بالفعل
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
      }
    } catch (e) {
      cachedPosts = oldState.posts;
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling share: $e');
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
      emit(PostsError(e.toString()));
    }
  }

  // ── Media picking (posts) ──────────────────────────────────────────────────

  Future<void> pickImageFromGallery() async {
    emit(MediaPicking());
    try {
      final image = await filePickerServices.pickImageFromGallery();
      if (image != null) {
        selectedImage = image;
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
        emit(MediaPicked(doc));
      } else {
        _emitPreviousState();
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      emit(MediaPickingError(e.toString()));
    }
  }

  void _resetMedia() {
    selectedImage = null;
    selectedVideo = null;
    selectedDocument = null;
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
