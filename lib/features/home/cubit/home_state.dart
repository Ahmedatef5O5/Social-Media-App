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
  final DateTime fetchedAt;
  const StoriesLoaded(this.stories, this.fetchedAt);
  List<Object?> get props => [stories, fetchedAt];
}

final class StoriesError extends HomeState {
  final String message;

  const StoriesError(this.message);
}

final class AddStoryLoading extends HomeState {}

final class AddStorySuccess extends HomeState {}

final class AddStoryError extends HomeState {
  final String message;

  const AddStoryError(this.message);
}

final class StoryImagePicking extends HomeState {}

final class StoryImagePicked extends HomeState {
  final File file;

  StoryImagePicked({required this.file});
}

final class StoryImagePickeError extends HomeState {
  final String message;

  const StoryImagePickeError(this.message);
}

final class PostsLoading extends HomeState {}

final class PostsLoaded extends HomeState {
  final List<PostModel> posts;
  final DateTime timeStamp;
  const PostsLoaded(this.posts, this.timeStamp);
  List<Object?> get props => [posts, timeStamp];
}

final class PostsError extends HomeState {
  final String message;

  const PostsError(this.message);
}

final class PostCreating extends HomeState {
  final double progress;
  const PostCreating(this.progress);
}

final class PostUploadCanceled extends HomeState {
  const PostUploadCanceled();
}

final class PostCreated extends HomeState {
  const PostCreated();
}

final class PostCreateError extends HomeState {
  final String message;
  PostCreateError(this.message);
}

final class MediaPicking extends HomeState {}

final class MediaPicked extends HomeState {
  final XFile? image;
  MediaPicked(this.image);
}

final class MediaPickingError extends HomeState {
  final String message;
  MediaPickingError(this.message);
}

final class AddingCommentLoading extends HomeState {
  final List<PostModel> oldPosts;

  AddingCommentLoading(this.oldPosts);
}

final class AddCommentSuccess extends HomeState {}

final class AddCommentError extends HomeState {
  final String message;
  AddCommentError(this.message);
}
