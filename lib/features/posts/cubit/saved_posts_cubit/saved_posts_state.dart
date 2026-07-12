part of 'saved_posts_cubit.dart';

sealed class SavedPostsState {
  const SavedPostsState();
}

final class SavedPostsInitial extends SavedPostsState {}

final class SavedPostsLoading extends SavedPostsState {}

final class SavedPostsLoaded extends SavedPostsState {
  final List<String> postIds;
  const SavedPostsLoaded(this.postIds);
}

final class SavedPostsEmpty extends SavedPostsState {}

final class SavedPostsError extends SavedPostsState {
  final String message;
  const SavedPostsError(this.message);
}
