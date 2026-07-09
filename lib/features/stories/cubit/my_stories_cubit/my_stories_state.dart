part of 'my_stories_cubit.dart';

sealed class MyStoriesState {
  const MyStoriesState();
}

final class MyStoriesLoaded extends MyStoriesState {
  final List<StoryModel> stories;
  final Map<String, StoryStatModel> statsByStoryId;
  final String? deletingStoryId;

  const MyStoriesLoaded({
    required this.stories,
    required this.statsByStoryId,
    this.deletingStoryId,
  });

  MyStoriesLoaded copyWith({
    List<StoryModel>? stories,
    Map<String, StoryStatModel>? statsByStoryId,
    String? deletingStoryId,
    bool clearDeleting = false,
  }) {
    return MyStoriesLoaded(
      stories: stories ?? this.stories,
      statsByStoryId: statsByStoryId ?? this.statsByStoryId,
      deletingStoryId:
          clearDeleting ? null : (deletingStoryId ?? this.deletingStoryId),
    );
  }
}
