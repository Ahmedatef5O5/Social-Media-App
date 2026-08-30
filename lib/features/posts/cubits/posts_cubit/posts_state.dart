part of 'posts_cubit.dart';

sealed class PostsState {
  const PostsState();
}

final class PostsInitial extends PostsState {}

final class PostsRefreshFeedback extends PostsState {}

final class PostsLoading extends PostsState {}

final class PostsLoaded extends PostsState {
  final List<PostModel> posts;
  final DateTime timeStamp;
  const PostsLoaded(this.posts, this.timeStamp);
  List<Object?> get props => [posts, timeStamp];
}

final class PostsPendingUpdated extends PostsState {
  final int pendingCount;
  const PostsPendingUpdated(this.pendingCount);
}

final class PostsLoadError extends PostsState {
  final String message;
  PostsLoadError(this.message);
}

final class PostsError extends PostsState {
  final String message;
  const PostsError(this.message);
}

final class PostCreating extends PostsState {
  final double progress;
  final int sentBytes;
  final int totalBytes;
  const PostCreating(this.progress, {this.sentBytes = 0, this.totalBytes = 0});
}

final class PostUploadCanceled extends PostsState {
  const PostUploadCanceled();
}

final class PostCreated extends PostsState {
  const PostCreated();
}

final class PostCreateError extends PostsState {
  final String message;
  final bool isConnectivityError;
  PostCreateError(this.message, {this.isConnectivityError = false});
}

final class MediaPicking extends PostsState {}

final class MediaPicked extends PostsState {
  final XFile? image;
  MediaPicked(this.image);
}

final class MediaPickingError extends PostsState {
  final String message;
  MediaPickingError(this.message);
}
