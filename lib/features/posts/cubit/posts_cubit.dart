// ignore_for_file: unused_field
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/presence_service.dart';
import '../../comments/events/comment_event_bus.dart';
import '../../comments/model/comment_model.dart';
import '../../notifications/repository/notifications_repository.dart';
import '../model/feed_event.dart';
import '../model/post_model.dart';
import '../model/post_reaction_model.dart';
import '../model/post_request_body.dart';
import '../services/posts_services.dart';
part 'posts_state.dart';

const int kMaxCachedPostsSnapshot = 30;

class PostsCubit extends Cubit<PostsState> {
  final PostsServices _postsServices;
  final CloudinaryStorageServices _storage;
  final NetworkStatusService _networkStatus;

  PostsCubit({
    required PostsServices postsServices,
    required CloudinaryStorageServices storage,
    NetworkStatusService? networkStatus,
  }) : _postsServices = postsServices,
       _storage = storage,
       _networkStatus = networkStatus ?? NetworkStatusService.instance,
       super(PostsInitial()) {
    _listenToCommentEvents();
  }

  List<PostModel> cachedPosts = [];
  UserData? currentUserData;
  final filePickerServices = FilePickerServices();
  XFile? selectedDocument;
  XFile? selectedImage;
  XFile? selectedVideo;

  StreamSubscription? _commentEventSub;

  final _eventBus = CommentEventBus.instance;
  StreamSubscription? _postsSubscription;

  dio_pkg.CancelToken? _cancelToken;

  void setCurrentUser(UserData user) {
    currentUserData = user;
  }

  Future<void> refreshPosts({bool isRefresh = false}) async {
    try {
      final start = DateTime.now();
      await fetchPosts(isRefresh: isRefresh);

      if (isRefresh) {
        emit(PostsRefreshFeedback());
        final elapsed = DateTime.now().difference(start);
        const minDuration = Duration(milliseconds: 700);
        if (elapsed < minDuration) {
          await Future.delayed(minDuration - elapsed);
        }
        if (cachedPosts.isNotEmpty) {
          emit(PostsLoaded(cachedPosts, DateTime.now()));
        }
      }
    } catch (e) {
      debugPrint('Error refreshing posts: $e');
      if (e.toString().contains('no-internet')) {
        ConnectivityBannerController.notifyBlockedByOffline();
      }
      if (cachedPosts.isEmpty) {
        emit(
          PostsLoadError(
            e.toString().contains('no-internet')
                ? 'No internet connection. Please check your network.'
                : 'An error occurred while updating the data. Please try again.',
          ),
        );
      }
    }
  }

  // ── Posts ──────────────────────────────────────────────────────────────────

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (!isRefresh) emit(PostsLoading());
    try {
      cachedPosts = await _postsServices.fetchPosts();
      cachedPosts = _fixLikersImages(cachedPosts);
      emit(PostsLoaded(cachedPosts, DateTime.now()));

      _listenToPosts();
      persistPostsSnapshot(cachedPosts);
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (cachedPosts.isNotEmpty) {
        debugPrint('Silent error: no internet, showing cached posts.');
        return;
      }
      final diskPosts = readPostsSnapshot();
      if (diskPosts.isNotEmpty) {
        debugPrint(
          'Silent error: no internet, showing posts snapshot from disk.',
        );
        cachedPosts = diskPosts;
        emit(PostsLoaded(diskPosts, DateTime.now()));
        return;
      }
      emit(
        PostsLoadError(
          e.toString().contains('no-internet')
              ? 'No internet connection. Please check your network.'
              : 'Failed to load posts.',
        ),
      );
    }
  }

  void persistPostsSnapshot(List<PostModel> posts) {
    unawaited(
      LocalSnapshotStore.instance.saveList(
        SnapshotKeys.posts,
        posts
            .take(kMaxCachedPostsSnapshot)
            .map((post) => post.toCacheJson())
            .toList(),
      ),
    );
  }

  List<PostModel> readPostsSnapshot() {
    try {
      return LocalSnapshotStore.instance
          .readList(SnapshotKeys.posts)
          .map(PostModel.fromCacheJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to read posts snapshot from disk: $e');
      return [];
    }
  }

  void addCommentLocally(
    String postId,
    CommentModel comment,
    String? parentId,
  ) {
    if (state is! PostsLoaded) return;
    final oldState = state as PostsLoaded;

    final updatedPosts =
        oldState.posts.map((post) {
          if (post.id != postId) return post;
          final updatedComments = List<CommentModel>.from(
            post.comments ?? const [],
          );
          if (parentId == null) {
            updatedComments.insert(0, comment);
          } else {
            for (int i = 0; i < updatedComments.length; i++) {
              if (updatedComments[i].id == parentId) {
                final replies = List<CommentModel>.from(
                  updatedComments[i].replies,
                );
                replies.add(comment);
                updatedComments[i] = updatedComments[i].copyWith(
                  replies: replies,
                );
                break;
              }
            }
          }
          return post.copyWith(comments: updatedComments);
        }).toList();

    emit(PostsLoaded(updatedPosts, DateTime.now()));
  }

  Future<void> createPost({required String text}) async {
    final user = Supabase.instance.client.auth.currentUser;
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

      final postRequest = PostRequestBody(
        text: text,
        authorId: userId,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        fileUrl: fileUrl,
        imagePublicId: imagePublicId,
        videoPublicId: videoPublicId,
        filePublicId: filePublicId,
      );
      await _postsServices.addPost(postRequest);

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
            (state as PostsLoaded).posts.where((p) => p.id != postId).toList();
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

  // ── Likes ──────────────────────────────────────────────────────────────────

  Future<void> toggleReaction(PostModel post, {String emoji = 'like'}) async {
    if (state is! PostsLoaded) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return;

    final oldState = state as PostsLoaded;
    final String? currentEmoji = post.myReactionEmoji;
    final bool isRemoving = currentEmoji == emoji;

    final List<PostModel> updatedPosts =
        oldState.posts.map((p) {
          if (p.id != post.id) return p;

          final updatedLikes = List<String>.from(p.likes ?? []);
          final updatedImages = List<String>.from(p.likersImages ?? []);
          final updatedReactions = List<PostReactionModel>.from(p.reactions);

          final String imagePlaceholder =
              (currentUserData?.imageUrl != null &&
                      currentUserData!.imageUrl!.startsWith('http'))
                  ? currentUserData!.imageUrl!
                  : 'asset:default';

          if (currentEmoji == null) {
            updatedLikes.insert(0, userId);
            updatedImages.insert(0, imagePlaceholder);
          } else if (isRemoving) {
            updatedLikes.remove(userId);
            updatedImages.remove(imagePlaceholder);
          }
          if (currentEmoji != null) {
            final oldIdx = updatedReactions.indexWhere(
              (r) => r.emoji == currentEmoji,
            );
            if (oldIdx >= 0) {
              final old = updatedReactions[oldIdx];
              old.count <= 1
                  ? updatedReactions.removeAt(oldIdx)
                  : updatedReactions[oldIdx] = old.copyWith(
                    count: old.count - 1,
                    reactedByMe: false,
                  );
            }
          }
          if (!isRemoving) {
            final newIdx = updatedReactions.indexWhere((r) => r.emoji == emoji);
            newIdx >= 0
                ? updatedReactions[newIdx] = updatedReactions[newIdx].copyWith(
                  count: updatedReactions[newIdx].count + 1,
                  reactedByMe: true,
                )
                : updatedReactions.add(
                  PostReactionModel(emoji: emoji, count: 1, reactedByMe: true),
                );
          }

          return p.copyWith(
            likes: updatedLikes,
            likersImages: updatedImages.where((img) => img.isNotEmpty).toList(),
            reactions: updatedReactions,
          );
        }).toList();

    emit(PostsLoaded(updatedPosts, DateTime.now()));

    try {
      final isOffline = await ConnectivityBannerController.notifyIfOffline();

      if (isOffline) {
        return;
      }
      await _postsServices.toggleReaction(
        postId: post.id,
        userId: userId,
        emoji: emoji,
        currentEmoji: currentEmoji,
      );

      if (post.authorId != userId && currentEmoji == null) {
        await NotificationRepository.instance.notifyLike(
          receiverId: post.authorId,
          likerId: userId,
          likerName: currentUserData?.name ?? 'unKnown',
          likerImageUrl: currentUserData?.imageUrl ?? '',
          postId: post.id,
        );
      }
    } catch (e) {
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling reaction: $e');
    }
  }

  void _listenToCommentEvents() {
    _commentEventSub = _eventBus.stream.listen((event) {
      addCommentLocally(event.postId, event.comment, event.parentId);
    });
  }

  void _listenToPosts() {
    if (_postsSubscription != null) return;

    _postsSubscription = _postsServices.getPostsStream().listen((
      FeedEvent event,
    ) async {
      if (isClosed) return;

      switch (event) {
        case PostInsertedEvent(:final postId):
          await _handlePostInserted(postId);

        case PostUpdatedEvent(:final postId):
          await _handlePostUpdated(postId);

        case PostDeletedEvent(:final postId):
          _handlePostDeleted(postId);

        case LikeChangedEvent(:final postId, :final changeType):
          await _handleLikeChanged(postId, changeType);

        case PresenceChangedEvent(
          :final userId,
          :final isOnline,
          :final updatedAt,
        ):
          _handlePresenceChanged(userId, isOnline, updatedAt);
      }
    });
  }

  Future<void> _handlePostInserted(String postId) async {
    final newPost = await _postsServices.fetchPostById(postId);
    if (newPost == null || isClosed) return;

    final alreadyExists = cachedPosts.any((p) => p.id == postId);
    if (alreadyExists) return;

    cachedPosts = [newPost, ...cachedPosts];

    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
    debugPrint('🔥 EVENT TRIGGERED: Inserted Post -> $postId');
  }

  Future<void> _handlePostUpdated(String postId) async {
    final updatedPost = await _postsServices.fetchPostById(postId);
    if (updatedPost == null || isClosed) return;

    cachedPosts =
        cachedPosts.map((p) {
          return p.id == postId ? updatedPost : p;
        }).toList();
    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  void _handlePostDeleted(String postId) {
    final exists = cachedPosts.any((p) => p.id == postId);
    if (!exists || isClosed) return;

    cachedPosts = cachedPosts.where((p) => p.id != postId).toList();
    emit(PostsLoaded(cachedPosts, DateTime.now()));
    debugPrint('🔥 EVENT TRIGGERED: Deleted Post Locally -> $postId');
  }

  Future<void> _handleLikeChanged(
    String postId,
    PostgresChangeEvent changeType,
  ) async {
    final refreshedPost = await _postsServices.fetchPostById(postId);
    if (refreshedPost == null || isClosed) return;

    cachedPosts =
        cachedPosts.map((p) {
          return p.id == postId ? refreshedPost : p;
        }).toList();
    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  void _handlePresenceChanged(
    String userId,
    bool isOnline,
    DateTime? updatedAt,
  ) {
    final isConsideredOnline = PresenceService.isConsideredOnline(
      isOnline: isOnline,
      updatedAt: updatedAt,
    );

    final affectsCurrentFeed = cachedPosts.any((p) => p.authorId == userId);
    if (!affectsCurrentFeed || isClosed) return;

    cachedPosts =
        cachedPosts.map((p) {
          return p.authorId == userId
              ? p.copyWith(isOnline: isConsideredOnline)
              : p;
        }).toList();

    emit(PostsLoaded(cachedPosts, DateTime.now()));
  }

  List<PostModel> _fixLikersImages(List<PostModel> posts) {
    return posts.map((post) {
      if (post.likes == null || post.likes!.isEmpty) return post;
      final likersImages = post.likersImages ?? [];
      if (likersImages.length >= post.likes!.length) return post;
      final fixedImages = List<String>.from(likersImages);
      final missing = post.likes!.length - likersImages.length;
      for (int i = 0; i < missing; i++) {
        fixedImages.add('asset:default');
      }
      return post.copyWith(likersImages: fixedImages);
    }).toList();
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

  @override
  Future<void> close() {
    _postsSubscription?.cancel();
    return super.close();
  }
}
