part of 'my_stories_cubit.dart';

sealed class MyStoriesState {
  const MyStoriesState();
}

final class MyStoriesLoaded extends MyStoriesState {
  final List<StoryModel> stories;
  final Map<String, StoryStatModel> statsByStoryId;
  final Set<String> deletingStoryIds;
  final Set<String> selectedStoryIds;

  const MyStoriesLoaded({
    required this.stories,
    required this.statsByStoryId,
    this.deletingStoryIds = const {},
    this.selectedStoryIds = const {},
  });

  bool get isSelectionMode => selectedStoryIds.isNotEmpty;

  MyStoriesLoaded copyWith({
    List<StoryModel>? stories,
    Map<String, StoryStatModel>? statsByStoryId,
    Set<String>? deletingStoryIds,
    Set<String>? selectedStoryIds,
  }) {
    return MyStoriesLoaded(
      stories: stories ?? this.stories,
      statsByStoryId: statsByStoryId ?? this.statsByStoryId,
      deletingStoryIds: deletingStoryIds ?? this.deletingStoryIds,
      selectedStoryIds: selectedStoryIds ?? this.selectedStoryIds,
    );
  }
}
