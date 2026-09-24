part of 'profile_posts_cubit.dart';

sealed class ProfilePostsState {
  const ProfilePostsState();
}

final class ProfilePostsInitial extends ProfilePostsState {}

final class ProfilePostsLoading extends ProfilePostsState {}

final class ProfilePostsLoaded extends ProfilePostsState {
  final List<String> postIds;
  final bool hasMore;
  final bool isLoadingMore;

  const ProfilePostsLoaded({
    required this.postIds,
    required this.hasMore,
    this.isLoadingMore = false,
  });
}

final class ProfilePostsError extends ProfilePostsState {
  final String message;
  const ProfilePostsError(this.message);
}
