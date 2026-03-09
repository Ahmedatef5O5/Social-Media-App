import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/services/file_picker_services.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/services/home_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_model.dart';
import '../models/post_request_body.dart';
import '../models/story_model.dart';
part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  final homeServices = HomeServices();
  UserData? currentUserData;
  final filePickerServices = FilePickerServices();
  XFile? selectedImage;
  XFile? selectedFile;

  Future<void> getHomeData() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    ([_getCurrentUser(userId), fetchStories(), fetchPosts()]);
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
      if (selectedImage != null) {
        imageUrl = await homeServices.uploadFile(
          File(selectedImage!.path),
          'post_images',
        );
      }
      final postRequest = PostRequestBody(
        text: text,
        authorId: userId,
        imageUrl: imageUrl,
        // fileUrl: fileUrl,
      );
      await homeServices.addPost(postRequest);
      selectedImage = null;
      emit(PostCreated());

      await fetchPosts();
    } catch (e) {
      emit(PostCreateError(e.toString()));
    }
  }

  Future<void> pickImageFromGallery() async {
    emit(ImagePicking());
    try {
      final image = await filePickerServices.pickImageFromGallery();
      if (image != null) {
        selectedImage = image;
        emit(ImagePicked(image));
      } else {
        emit(ImagePickingError('No image selected'));
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      emit(ImagePickingError(e.toString()));
    }
  }

  Future<void> takePhotoByCamera() async {
    emit(ImagePicking());
    try {
      final image = await filePickerServices.takePhotoByCamera();
      if (image != null) {
        selectedImage = image;
        emit(ImagePicked(image));
      }
    } catch (e) {
      debugPrint('Error taking image by camera: $e');
      emit(ImagePickingError(e.toString()));
    }
  }
}
