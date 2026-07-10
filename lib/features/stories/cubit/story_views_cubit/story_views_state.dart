part of 'story_views_cubit.dart';

sealed class StoryViewsState {
  const StoryViewsState();
}

final class StoryViewsLoading extends StoryViewsState {
  const StoryViewsLoading();
}

final class StoryViewsLoaded extends StoryViewsState {
  final List<StoryViewerModel> viewers;
  const StoryViewsLoaded(this.viewers);

  int get viewCount => viewers.length;
  int get reactionCount => viewers.where((v) => v.hasReacted).length;
}

final class StoryViewsError extends StoryViewsState {
  final String message;
  const StoryViewsError(this.message);
}
