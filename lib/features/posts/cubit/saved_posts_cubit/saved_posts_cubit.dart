import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/posts_services.dart';
import '../posts_cubit.dart';
part 'saved_posts_state.dart';

class SavedPostsCubit extends Cubit<SavedPostsState> {
  final PostsServices _postsServices;
  final PostsCubit _postsCubit;

  SavedPostsCubit({
    required PostsServices postsServices,
    required PostsCubit postsCubit,
  }) : _postsServices = postsServices,
       _postsCubit = postsCubit,
       super(SavedPostsInitial());

  Future<void> fetchSavedPosts(String userId) async {
    emit(SavedPostsLoading());
    try {
      final posts = await _postsServices.fetchSavedPosts(userId);

      _postsCubit.mergePostsIntoCache(posts);

      if (posts.isEmpty) {
        emit(SavedPostsEmpty());
      } else {
        emit(SavedPostsLoaded(posts.map((p) => p.id).toList()));
      }
    } catch (e) {
      debugPrint('Error fetching saved posts: $e');
      emit(
        SavedPostsError(
          e.toString().contains('no-internet')
              ? 'No internet connection. Please check your network.'
              : 'Failed to load saved posts.',
        ),
      );
    }
  }
}
