import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/home/services/home_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_model.dart';
import '../models/post_request_body.dart';
import '../models/story_model.dart';
part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  final homeServices = HomeServices();

  Future<void> getHomeData() async {
    await Future.wait([fetchStories(), fetchPosts()]);
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
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final postRequest = PostRequestBody(
        text: text,
        authorId: userId,
        image: image,
        file: file,
      );
      await homeServices.addPost(postRequest);

      emit(PostCreated());

      await fetchPosts();
    } catch (e) {
      emit(PostCreateError(e.toString()));
    }
  }
}
