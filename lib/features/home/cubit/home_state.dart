part of 'home_cubit.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeInitial extends HomeState {}

final class UserDataLoading extends HomeState {}

final class UserDataLoaded extends HomeState {
  final UserData userData;

  const UserDataLoaded(this.userData);
}

final class UserDataLoadError extends HomeState {
  final String message;

  UserDataLoadError(this.message);
}

final class StoriesLoading extends HomeState {}

final class StoriesLoaded extends HomeState {
  final List<StoryModel> stories;

  const StoriesLoaded(this.stories);
}

final class StoriesError extends HomeState {
  final String message;

  const StoriesError(this.message);
}

final class PostsLoading extends HomeState {}

final class PostsLoaded extends HomeState {
  final List<PostModel> posts;

  const PostsLoaded(this.posts);
}

final class PostsError extends HomeState {
  final String message;

  const PostsError(this.message);
}

final class PostCreating extends HomeState {}

final class PostCreated extends HomeState {
  const PostCreated();
}

final class PostCreateError extends HomeState {
  final String message;
  PostCreateError(this.message);
}

final class ImagePicking extends HomeState {}

final class ImagePicked extends HomeState {
  final XFile? image;
  ImagePicked(this.image);
}

final class ImagePickingError extends HomeState {
  final String message;
  ImagePickingError(this.message);
}
