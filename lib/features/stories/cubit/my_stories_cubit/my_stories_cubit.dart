import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/story_model.dart';
import '../../model/story_stat_model.dart';
import '../../services/stories_services.dart';
import '../stories_cubit/stories_cubit.dart';
part 'my_stories_state.dart';

class MyStoriesCubit extends Cubit<MyStoriesState> {
  final StoriesCubit storiesCubit;
  final StoriesServices _storiesServices;

  MyStoriesCubit({
    required List<StoryModel> initialStories,
    required this.storiesCubit,
    StoriesServices? storiesServices,
  }) : _storiesServices = storiesServices ?? StoriesServices(),
       super(
         MyStoriesLoaded(stories: initialStories, statsByStoryId: const {}),
       ) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final rows = await _storiesServices.getMyStoriesOverview();
      final stats = {
        for (final row in rows.map(StoryStatModel.fromMap)) row.storyId: row,
      };
      final current = state;
      if (current is MyStoriesLoaded && !isClosed) {
        emit(current.copyWith(statsByStoryId: stats));
      }
    } catch (e) {
      debugPrint('Error loading my stories overview: $e');
    }
  }

  Future<void> deleteStory(String storyId) async {
    final current = state;
    if (current is! MyStoriesLoaded) return;

    emit(current.copyWith(deletingStoryId: storyId));
    try {
      await storiesCubit.deleteStory(storyId);
      final updatedStories =
          current.stories.where((s) => s.id != storyId).toList();
      final updatedStats = Map<String, StoryStatModel>.from(
        current.statsByStoryId,
      )..remove(storyId);
      emit(
        MyStoriesLoaded(stories: updatedStories, statsByStoryId: updatedStats),
      );
    } catch (e) {
      debugPrint('Error deleting story: $e');
      if (!isClosed) emit(current.copyWith(clearDeleting: true));
    }
  }
}
