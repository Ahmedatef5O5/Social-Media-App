part of 'stories_cubit.dart';

sealed class StoriesState {
  const StoriesState();
}

final class StoriesInitial extends StoriesState {}

final class StoriesLoading extends StoriesState {}

final class StoriesLoaded extends StoriesState {
  final List<StoryModel> stories;
  final DateTime fetchedAt;
  const StoriesLoaded(this.stories, this.fetchedAt);
  List<Object?> get props => [stories, fetchedAt];
}

final class StoriesError extends StoriesState {
  final String message;

  const StoriesError(this.message);
}

final class AddStoryLoading extends StoriesState {}

final class AddStorySuccess extends StoriesState {}

final class AddStoryError extends StoriesState {
  final String message;

  const AddStoryError(this.message);
}

final class StoryImagePicking extends StoriesState {}

final class StoryImagePicked extends StoriesState {
  final File file;

  StoryImagePicked({required this.file});
}

final class StoryImagePickeError extends StoriesState {
  final String message;

  const StoryImagePickeError(this.message);
}

final class StoryVideoPicked extends StoriesState {
  final File file;
  final Duration videoDuration;

  const StoryVideoPicked({required this.file, required this.videoDuration});
}

final class StoryVideoTooLong extends StoriesState {
  final Duration videoDuration;
  final Duration maxAllowed;

  const StoryVideoTooLong({
    required this.videoDuration,
    required this.maxAllowed,
  });
}

final class StoryVideoPickError extends StoriesState {
  final String message;

  const StoryVideoPickError(this.message);
}
