part of 'search_posts_cubit.dart';

sealed class SearchPostsState {
  const SearchPostsState();
}

final class SearchPostsInitial extends SearchPostsState {}

final class SearchPostsLoading extends SearchPostsState {}

final class SearchPostsLoaded extends SearchPostsState {
  final List<PostModel> posts;
  final bool hasReachedMax;
  const SearchPostsLoaded({required this.posts, required this.hasReachedMax});
}

final class SearchPostsError extends SearchPostsState {
  final String message;
  const SearchPostsError(this.message);
}
