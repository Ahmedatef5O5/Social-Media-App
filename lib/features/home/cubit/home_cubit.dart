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

  Future<void> getHomeData() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    await Future.wait([_getCurrentUser(userId), fetchStories(), fetchPosts()]);
  }

  Future<void> _getCurrentUser(String userId) async {
    try {
      currentUserData = await homeServices.fetchCurrentUser(userId);
      emit(UserDataLoaded(currentUserData!));
    } catch (e) {
      debugPrint("Error fetching user: $e");
      emit(UserDataLoadError(e.toString()));
    }
  }

  Future<void> fetchStories() async {
    emit(StoriesLoading());
    try {
      final stories = await homeServices.fetchStories();
      emit(StoriesLoaded(stories));
    } catch (e) {
      emit(StoriesError(e.toString()));
    }
  }

  Future<void> fetchPosts() async {
    emit(PostsLoading());
    try {
      final posts = await homeServices.fetchPosts();
      emit(PostsLoaded(posts));
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
        emit(MediaPickingError('No image selected'));
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
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      emit(MediaPickingError(e.toString()));
    }
  }

  Future<void> toggleLike(PostModel post) async {
    if (state is! PostsLoaded) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    //
    final currentUserImageUrl = user?.userMetadata?['image_url'] ?? '';

    final oldPosts = (state as PostsLoaded).posts;
    final List<PostModel> newPosts =
        oldPosts.map((p) {
          if (p.id == post.id) {
            final updatedLikes = List<String>.from(p.likes ?? []);
            final updatedImages = List<String>.from(p.likersImages ?? []);
            if (updatedLikes.contains(userId)) {
              updatedLikes.remove(userId);
              // updatedImages.remove(currentUserImageUrl);
              updatedImages.removeWhere((img) => img == currentUserImageUrl);
            } else {
              updatedLikes.add(userId);
              if (currentUserImageUrl.isNotEmpty) {
                updatedImages.insert(0, currentUserImageUrl);
              }
            }
            final uniqueImages = updatedImages.toSet().toList();
            return p.copyWith(
              likes: updatedLikes,
              likersImages: List<String>.from(uniqueImages),
            );
            // return p.copyWith(likes: updatedLikes, likersImages: uniqueImages);
          }
          return p;
        }).toList();
    emit(PostsLoaded(newPosts));

    try {
      await homeServices.likePost(
        post.id,
        newPosts.firstWhere((p) => p.id == post.id).likes!,
      );
    } catch (e) {
      emit(PostsLoaded(oldPosts));
      debugPrint('Error liking post: $e');
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

      emit(PostsLoaded(updatedPosts));
      emit(AddCommentSuccess());
      emit(PostsLoaded(updatedPosts));
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
}
