import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/models/comment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/post_request_body.dart';
import '../models/story_model.dart';
import '../services/home_services.dart';
part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  final homeServices = HomeServices();
  UserData? currentUserData;
  final filePickerServices = FilePickerServices();
  XFile? selectedImage;
  XFile? selectedVideo;
  XFile? selectedDocument;
  File? selectedStoryFile;

  List<StoryModel> cachedStories = [];

  List<List<StoryModel>> cachedUserGroups = [];
  int cachedCurrentUserGroupIndex = 0;

  // Refresh Screen
  Future<void> refreshHomeData({bool isRefresh = false}) async {
    try {
      await getHomeData(isRefresh: isRefresh);
    } catch (e) {
      debugPrint('Error refreshing home data: $e');
    }
  }

  Future<void> getHomeData({bool isRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    await Future.wait([
      _getCurrentUser(userId),
      fetchStories(isRefresh: isRefresh),
      fetchPosts(isRefresh: isRefresh),
    ]);
  }

  Future<void> _getCurrentUser(String userId, {bool isRefresh = false}) async {
    try {
      currentUserData = await homeServices.fetchCurrentUser(userId);
      if (!isRefresh) emit(UserDataLoaded(currentUserData!));
    } catch (e) {
      debugPrint("Error fetching user: $e");
      emit(UserDataLoadError(e.toString()));
    }
  }

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
      await homeServices.createStory(newStory);
      await fetchStories();
      emit(AddStorySuccess());
    } catch (e) {
      debugPrint('Error adding text story: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> addStory({required File file, required UserData user}) async {
    emit(AddStoryLoading());
    try {
      final fileUrl = await homeServices.uploadStoryFile(file, user.id);
      final newStory = StoryModel(
        // id: '',
        imageUrl: fileUrl,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
      );
      await homeServices.createStory(newStory);
      await fetchStories();
    } catch (e) {
      debugPrint('Error adding story: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await homeServices.deleteStory(storyId);
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
      if (pickedFile != null) {
        final file = File(pickedFile.path);

        if (await file.exists() && currentUserData != null) {
          selectedStoryFile = file;

          emit(StoryImagePicked(file: file));
        } else {
          final appDir = await getTemporaryDirectory();
          final newPath =
              '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          final newFile = await File(pickedFile.path).copy(newPath);
          selectedStoryFile = newFile;
          emit(StoryImagePicked(file: newFile));
        }
      }
    } catch (e) {
      debugPrint('Error in pickAndAddStory: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> addStoryWithCaption({
    required File file,
    required UserData user,
    String? caption,
  }) async {
    emit(AddStoryLoading());
    try {
      final fileUrl = await homeServices.uploadStoryFile(file, user.id);
      final newStory = StoryModel(
        imageUrl: fileUrl,
        authorId: user.id,
        authorName: user.name,
        createdAt: DateTime.now().toIso8601String(),
        caption: caption,
      );
      await homeServices.createStory(newStory);
      await fetchStories();
      emit(AddStorySuccess());
    } catch (e) {
      debugPrint('Error adding story With caption: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> fetchStories({bool isRefresh = false}) async {
    if (!isRefresh && state is! StoriesLoading) emit(StoriesLoading());
    try {
      final stories = await homeServices.fetchStories();
      cachedStories = stories;
      emit(StoriesLoaded(stories, DateTime.now()));
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      emit(StoriesError(e.toString()));
    }
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (!isRefresh) emit(PostsLoading());
    try {
      final posts = await homeServices.fetchPosts();

      final fixedPosts = _fixLikersImages(posts);
      emit(PostsLoaded(fixedPosts, DateTime.now()));
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> createPost({required String text}) async {
    emit(PostCreating(0.05));
    try {
      //
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? imageUrl;
      String? videoUrl;
      String? fileUrl;
      void updateProgress(double p) {
        if (state is PostCreating) {
          emit(PostCreating(p.clamp(0.05, 0.95)));
        }
      }

      if (selectedImage != null) {
        final imageFile = File(selectedImage!.path);

        if (await imageFile.exists()) {
          imageUrl = await homeServices.uploadFile(
            File(selectedImage!.path),
            'post_images',
            'images',

            onProgress: updateProgress,
          );
        } else {
          throw Exception('image_not_found');
        }
      }
      if (selectedVideo != null) {
        final videoFile = File(selectedVideo!.path);
        if (await videoFile.exists()) {
          videoUrl = await homeServices.uploadFile(
            File(selectedVideo!.path),
            'post_images',
            'videos',
            onProgress: updateProgress,
          );
        } else {
          throw Exception('video_not_found');
        }
      }
      if (selectedDocument != null) {
        final docFile = File(selectedDocument!.path);
        if (await docFile.exists()) {
          fileUrl = await homeServices.uploadFile(
            docFile,
            'post_images',
            'documents',
            onProgress: updateProgress,
          );
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
      );
      await homeServices.addPost(postRequest);

      emit(PostCreating(1.0));
      await Future.delayed(const Duration(milliseconds: 2000));

      _resetMedia();
      emit(PostCreated());
      await fetchPosts();
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
    homeServices.cancelCurrentUpload();
    emit(const PostUploadCanceled());
  }

  Future<void> deletePost(String postId) async {
    try {
      await homeServices.deletePost(postId);
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

  void _resetMedia() {
    selectedImage = null;
    selectedVideo = null;
    selectedDocument = null;
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
      await homeServices.toggleLike(
        postId: post.id,
        userId: userId,
        isLiked: isCurrentlyLiked,
      );
    } catch (e) {
      emit(PostsLoaded(oldState.posts, DateTime.now()));
      debugPrint('Error toggling like: $e');
    }
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

  Future<void> addComment(String postId, String commentText) async {
    if (state is! PostsLoaded) return;
    final oldState = state as PostsLoaded;
    emit(AddingCommentLoading(oldState.posts));

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final userName = currentUserData?.name ?? 'User';
      final oldPosts = oldState.posts;

      final newComment = CommentModel(
        id: DateTime.now().toString(),
        createdAt: DateTime.now().toIso8601String(),
        authorId: userId,
        authorName: userName,
        text: commentText,
        postId: postId,
      );

      final List<PostModel> updatedPosts =
          oldPosts.map((p) {
            if (p.id == postId) {
              final updatedComments = List<CommentModel>.from(p.comments ?? []);
              updatedComments.add(newComment);
              return p.copyWith(comments: updatedComments);
            }
            return p;
          }).toList();

      emit(PostsLoaded(updatedPosts, DateTime.now()));
      await homeServices.addComment(
        postId: postId,
        authorId: userId,
        commentText: commentText,
      );
    } catch (e) {
      debugPrint('Error adding comment: $e');
      emit(AddCommentError(e.toString()));
      emit(oldState);
    }
  }

  void _emitPreviousState() {
    emit(MediaPickingError('Selected Cancelled'));
  }
}
