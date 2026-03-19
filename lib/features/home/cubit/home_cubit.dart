import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> pickAndAddStory({required ImageSource source}) async {
    try {
      final XFile? pickedFile =
          source == ImageSource.camera
              ? await filePickerServices.takePhotoByCamera()
              : await filePickerServices.pickImageFromGallery();
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (currentUserData != null) {
          await addStory(file: file, user: currentUserData!);
        } else {
          debugPrint('User data is not loaded yet, cannot add story');
        }
      }
    } catch (e) {
      debugPrint('Error in pickAndAddStory: $e');
      emit(AddStoryError(e.toString()));
    }
  }

  Future<void> fetchStories({bool isRefresh = false}) async {
    if (!isRefresh) emit(StoriesLoading());
    try {
      final stories = await homeServices.fetchStories();
      emit(StoriesLoaded(stories));
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      emit(StoriesError(e.toString()));
    }
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (!isRefresh) emit(PostsLoading());
    try {
      final posts = await homeServices.fetchPosts();
      emit(PostsLoaded(posts, DateTime.now()));
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> createPost({
    required String text,
    File? image,
    File? file,
  }) async {
    emit(PostCreating());
    try {
      //
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? imageUrl;
      String? videoUrl;
      String? fileUrl;
      if (selectedImage != null) {
        imageUrl = await homeServices.uploadFile(
          File(selectedImage!.path),
          'post_images',
          'images',
        );
      }
      if (selectedVideo != null) {
        videoUrl = await homeServices.uploadFile(
          File(selectedVideo!.path),
          'post_images',
          'videos',
        );
      }
      if (selectedDocument != null) {
        fileUrl = await homeServices.uploadFile(
          File(selectedDocument!.path),
          'post_images',
          'documents',
        );
      }
      final postRequest = PostRequestBody(
        text: text,
        authorId: userId,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        fileUrl: fileUrl,
      );
      await homeServices.addPost(postRequest);
      selectedImage = null;
      selectedVideo = null;
      selectedDocument = null;
      emit(PostCreated());

      await fetchPosts();
    } catch (e) {
      emit(PostCreateError(e.toString()));
    }
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
    final String currentUserImageUrl =
        user?.userMetadata?['image_url'] ?? currentUserData?.imageUrl ?? '';

    //
    final oldState = state as PostsLoaded;

    final bool isCurrentlyLiked = post.isLikedBy(userId);

    final List<PostModel> updatedPosts =
        oldState.posts.map((p) {
          if (p.id == post.id) {
            final updatedLikes = List<String>.from(p.likes ?? []);
            final updatedImages = List<String>.from(p.likersImages ?? []);

            if (isCurrentlyLiked) {
              updatedLikes.remove(userId);
              if (updatedImages.contains(currentUserImageUrl)) {
                updatedImages.remove(currentUserImageUrl);
              } else {
                updatedImages.removeWhere(
                  (img) => img.trim() == currentUserImageUrl.trim(),
                );
              }
            } else {
              updatedLikes.add(userId);
              if (currentUserImageUrl.isNotEmpty) {
                updatedImages.insert(0, currentUserImageUrl);
              }
            }

            return p.copyWith(
              likes: updatedLikes,
              likersImages:
                  updatedImages.where((img) => img.isNotEmpty).toSet().toList(),
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
      // emit(AddCommentSuccess());
      // emit(PostsLoaded(updatedPosts, DateTime.now()));
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
