import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/supabase_storage_services.dart';
import '../../../comments/events/comment_event_bus.dart';
import '../../../comments/model/comment_model.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../models/feed_event.dart';
import '../../models/post_model.dart';
import '../../models/post_request_body.dart';
import '../../../stories/model/story_model.dart';
import '../../services/home_services.dart';
part 'home_state.dart';

const Duration kMaxStoryVideoDuration = Duration(seconds: 60);

class HomeCubit extends Cubit<HomeState> {
  final HomeServices _homeServices;
  final NetworkStatusService _networkStatus;

  HomeCubit({
    required HomeServices homeServices,
    NetworkStatusService? networkStatus,
  }) : _homeServices = homeServices,
       _networkStatus = networkStatus ?? NetworkStatusService.instance,
       super(HomeInitial()) {
    _listenToCommentEvents();
  }

  List<PostModel> cachedPosts = [];
  List<StoryModel> cachedStories = [];
  UserData? currentUserData;
  final filePickerServices = FilePickerServices();
  PersistentTabController? navController;
  XFile? selectedDocument;
  XFile? selectedImage;
  File? selectedStoryFile;
  XFile? selectedVideo;

  // ignore: unused_field
  StreamSubscription? _commentEventSub;

  final _eventBus = CommentEventBus.instance;
  StreamSubscription? _postsSubscription;
  File? _stableVideoFile;

  dio_pkg.CancelToken? _cancelToken;

  @override
  Future<void> close() {
    _postsSubscription?.cancel();
    _cleanupStableVideo();
    return super.close();
  }

  // ── Home data ──────────────────────────────────────────────────────────────

  Future<void> refreshHomeData({bool isRefresh = false}) async {
    bool hasNet = await _networkStatus.isConnected();
    if (!hasNet) {
      emit(
        UserDataLoadError("No internet connection. Please check your network."),
      );
      return;
    }

    try {
      final start = DateTime.now();

      await getHomeData(isRefresh: isRefresh);

      if (isRefresh) {
        emit(HomeRefreshFeedback());

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
      debugPrint('Error refreshing home data: $e');
      emit(
        UserDataLoadError(
          'An error occurred while updating the data. Please try again.',
        ),
      );
    }
  }

  Future<void> getHomeData({bool isRefresh = false}) async {
    if (!isRefresh) emit(UserDataLoading());
    final userId = Supabase.instance.client.auth.currentUser!.id;
    await Future.wait([
      _getCurrentUser(userId),
      fetchStories(isRefresh: isRefresh),
      fetchPosts(isRefresh: isRefresh),
    ]);
  }

  // ── Story actions ──────────────────────────────────────────────────────────

  Future<void> addTextStory({
    required String text,
    required Color bgColor,
  }) async {
    if (currentUserData == null) return;
    emit(AddStoryLoading());
    try {
      final newStory = StoryModel(
        contentText: text,
        backgroundColor: bgColor.toARGB32().toRadixString(16),
        authorId: currentUserData!.id,
        authorName: currentUserData!.name,
        createdAt: DateTime.now().toIso8601String(),
        imageUrl: null,
      );
      await _homeServices.storyServices.createStory(newStory);
      await fetchStories();
      emit(AddStorySuccess());
      await Future.delayed(const Duration(milliseconds: 100));
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      if (cachedPosts.isNotEmpty) {
        emit(PostsLoaded(cachedPosts, DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error adding text story: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> addStory({required File file, required UserData user}) async {
    emit(AddStoryLoading());
    try {
      final result = await _homeServices.storyServices.uploadStoryFile(
        file,
        user.id,
      );
      final newStory = StoryModel(
        imageUrl: result.secureUrl,
        imagePublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _homeServices.storyServices.createStory(newStory);
      await fetchStories();
      await Future.delayed(const Duration(milliseconds: 100));
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      if (cachedPosts.isNotEmpty) {
        emit(PostsLoaded(cachedPosts, DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error adding story: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _homeServices.storyServices.deleteStory(storyId);
      cachedStories = cachedStories.where((s) => s.id != storyId).toList();
      if (state is StoriesLoaded) {
        final updateStories =
            (state as StoriesLoaded).stories
                .where((s) => s.id != storyId)
                .toList();
        emit(StoriesLoaded(updateStories, DateTime.now()));
      } else {
        emit(StoriesLoaded(cachedStories, DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error deleting story: $e');
    }
  }

  Future<void> pickAndAddStory({required ImageSource source}) async {
    try {
      final XFile? pickedFile =
          source == ImageSource.camera
              ? await filePickerServices.takePhotoByCamera()
              : await filePickerServices.pickImageFromGallery();

      if (pickedFile == null) return;

      final file = await _writeToAppDir(xFile: pickedFile, extension: 'jpg');
      selectedStoryFile = file;
      emit(StoryImagePicked(file: file));
    } catch (e) {
      debugPrint('Error in pickAndAddStory: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  // TODO : Do not repeat this func addStory & addStoryWithCaption ... solve that  DRY

  Future<void> addStoryWithCaption({
    required File file,
    required UserData user,
    String? caption,
  }) async {
    emit(AddStoryLoading());
    try {
      final result = await _homeServices.storyServices.uploadStoryFile(
        file,
        user.id,
      );
      final newStory = StoryModel(
        imageUrl: result.secureUrl,
        imagePublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
        caption: caption,
      );
      await _homeServices.storyServices.createStory(newStory);
      await fetchStories();
      emit(AddStorySuccess());
      await Future.delayed(const Duration(milliseconds: 100));
      emit(StoriesLoaded(cachedStories, DateTime.now()));
      if (cachedPosts.isNotEmpty) {
        emit(PostsLoaded(cachedPosts, DateTime.now()));
      }
    } catch (e) {
      debugPrint('Error adding story with caption: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> pickAndPreviewVideoStory({required ImageSource source}) async {
    if (state is StoryVideoPicked) return;

    try {
      final XFile? pickedFile =
          source == ImageSource.camera
              ? await filePickerServices.takeVideoByCamera()
              : await filePickerServices.pickVideoFromGallery();

      if (pickedFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final destPath =
          '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      final stableFile = await File(pickedFile.path).copy(destPath);

      if (!await stableFile.exists()) {
        emit(const StoryVideoPickError('Could not process the video file.'));
        return;
      }

      final duration = await _getVideoDuration(stableFile);

      if (duration > kMaxStoryVideoDuration) {
        // ignore: body_might_complete_normally_catch_error
        await stableFile.delete().catchError((_) {});
        emit(
          StoryVideoTooLong(
            videoDuration: duration,
            maxAllowed: kMaxStoryVideoDuration,
          ),
        );
        return;
      }

      _stableVideoFile = stableFile;
      selectedStoryFile = stableFile;
      emit(StoryVideoPicked(file: stableFile, videoDuration: duration));
    } catch (e) {
      debugPrint('Error picking video story: $e');
      emit(StoryVideoPickError(e.toString()));
    }
  }

  Future<void> addVideoStoryWithCaption({
    required File file,
    required UserData user,
    String? caption,
  }) async {
    emit(AddStoryLoading());
    try {
      final File uploadFile =
          (_stableVideoFile != null && await _stableVideoFile!.exists())
              ? _stableVideoFile!
              : (await file.exists()
                  ? file
                  : throw PathNotFoundException(
                    file.path,
                    const OSError('File not found', 2),
                  ));

      final result = await _homeServices.storyServices.uploadStoryVideoFile(
        uploadFile,
        user.id,
      );

      final newStory = StoryModel(
        videoUrl: result.secureUrl,
        videoPublicId: result.publicId,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
        caption: caption,
      );
      await _homeServices.storyServices.createStory(newStory);
      await fetchStories(isRefresh: true);
      _cleanupStableVideo();
      emit(AddStorySuccess());
      await Future.delayed(const Duration(milliseconds: 300));
      if (cachedPosts.isNotEmpty) {
        emit(PostsLoaded(cachedPosts, DateTime.now()));
      } else {
        emit(StoriesLoaded(cachedStories, DateTime.now()));
      }
    } on UploadCanceledException {
      return;
    } catch (e) {
      debugPrint('Error adding video story: $e');
      emit(AddStoryError(e.toString()));

      if (e.toString().contains('session_expired')) {
        emit(AddStoryError('Your session has expired; please log in again'));
        return;
      }
    }
  }

  // ── Stories fetch ──────────────────────────────────────────────────────────

  Future<void> fetchStories({bool isRefresh = false}) async {
    if (!isRefresh && state is! StoriesLoading) emit(StoriesLoading());
    try {
      final stories = await _homeServices.storyServices.fetchStories();
      cachedStories = stories;
      emit(StoriesLoaded(stories, DateTime.now()));
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      emit(StoriesError(e.toString()));
    }
  }

  // ── Posts ──────────────────────────────────────────────────────────────────

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (!isRefresh) emit(PostsLoading());
    final hasNet = await _networkStatus.isConnected();
    if (!hasNet) {
      emit(UserDataLoadError("No internet connection."));
      return;
    }

    try {
      cachedPosts = await _homeServices.postServices.fetchPosts();
      cachedPosts = _fixLikersImages(cachedPosts);
      emit(PostsLoaded(cachedPosts, DateTime.now()));

      _listenToPosts();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      emit(UserDataLoadError('Failed to load posts.'));
      rethrow;
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
          final result = await _homeServices.storage.uploadFile(
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
          final result = await _homeServices.storage.uploadFile(
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
          final result = await _homeServices.storage.uploadFile(
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
      await _homeServices.postServices.addPost(postRequest);

      emit(PostCreating(1.0));
      await Future.delayed(const Duration(milliseconds: 2000));
      _resetMedia();
      emit(PostCreated());
    } catch (e) {
      final errorMessage = _mapExceptionToMessage(e);
      if (errorMessage == "upload_canceled") {
        emit(const PostUploadCanceled());
      } else {
        emit(PostCreateError(errorMessage));
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
      await _homeServices.postServices.deletePost(postId);
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

  Future<void> toggleLike(PostModel post) async {
    if (state is! PostsLoaded) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return;

    final oldState = state as PostsLoaded;
    final bool isCurrentlyLiked = post.isLikedBy(userId);

    final List<PostModel> updatedPosts =
        oldState.posts.map((p) {
          if (p.id == post.id) {
            final updatedLikes = List<String>.from(p.likes ?? []);
            final updatedImages = List<String>.from(p.likersImages ?? []);

            final String imagePlaceholder =
                (currentUserData?.imageUrl != null &&
                        currentUserData!.imageUrl!.startsWith('http'))
                    ? currentUserData!.imageUrl!
                    : 'asset:default';

            if (!isCurrentlyLiked) {
              updatedLikes.insert(0, userId);
              updatedImages.insert(0, imagePlaceholder);
            } else {
              updatedLikes.remove(userId);
              updatedImages.remove(imagePlaceholder);
            }

            return p.copyWith(
              likes: updatedLikes,
              likersImages:
                  updatedImages.where((img) => img.isNotEmpty).toList(),
            );
          }
          return p;
        }).toList();

    emit(PostsLoaded(updatedPosts, DateTime.now()));

    try {
      await _homeServices.postServices.toggleLike(
        postId: post.id,
        userId: userId,
        isLiked: isCurrentlyLiked,
      );

      // add like notify to notifications view
      if (post.authorId != userId) {
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
      debugPrint('Error toggling like: $e');
    }
  }

  void _listenToCommentEvents() {
    _commentEventSub = _eventBus.stream.listen((event) {
      addCommentLocally(event.postId, event.comment, event.parentId);
    });
  }

  Future<void> _getCurrentUser(String userId, {bool isRefresh = false}) async {
    try {
      currentUserData = await _homeServices.userServices.fetchCurrentUser(
        userId,
      );
      if (!isRefresh) emit(UserDataLoaded(currentUserData!));
    } catch (e) {
      debugPrint("Error fetching user: $e");
      emit(UserDataLoadError(e.toString()));
    }
  }

  void _listenToPosts() {
    if (_postsSubscription != null) return;

    _postsSubscription = _homeServices.postServices.getPostsStream().listen((
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
    final newPost = await _homeServices.postServices.fetchPostById(postId);
    if (newPost == null || isClosed) return;

    final alreadyExists = cachedPosts.any((p) => p.id == postId);
    if (alreadyExists) return;

    cachedPosts = [newPost, ...cachedPosts];

    cachedPosts = _fixLikersImages(cachedPosts);
    emit(PostsLoaded(cachedPosts, DateTime.now()));
    debugPrint('🔥 EVENT TRIGGERED: Inserted Post -> $postId');
  }

  Future<void> _handlePostUpdated(String postId) async {
    final updatedPost = await _homeServices.postServices.fetchPostById(postId);
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
    final refreshedPost = await _homeServices.postServices.fetchPostById(
      postId,
    );
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

  Future<File> _writeToAppDir({
    required XFile xFile,
    required String extension,
  }) async {
    final bytes = await xFile.readAsBytes();
    final appDir = await getApplicationDocumentsDirectory();
    final destPath =
        '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.$extension';
    return File(destPath).writeAsBytes(bytes);
  }

  Future<Duration> _getVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }

  void _cleanupStableVideo() {
    // ignore: body_might_complete_normally_catch_error
    _stableVideoFile?.delete().catchError((_) {});
    _stableVideoFile = null;
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
}
