import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import '../../model/story_model.dart';
import '../../model/story_stat_model.dart';
import '../../services/stories_services.dart';
import '../stories_cubit/stories_cubit.dart';
part 'my_stories_state.dart';

class MyStoriesCubit extends Cubit<MyStoriesState> {
  final StoriesCubit storiesCubit;
  final StoriesServices _storiesServices;
  StreamSubscription<StoriesState>? _streamSubscription;

  MyStoriesCubit({
    required List<StoryModel> initialStories,
    required this.storiesCubit,
    StoriesServices? storiesServices,
  }) : _storiesServices = storiesServices ?? StoriesServices(),
       super(
         MyStoriesLoaded(stories: initialStories, statsByStoryId: const {}),
       ) {
    _loadStats();
    _listenToStoriesUpdates();
  }

  void _listenToStoriesUpdates() {
    _streamSubscription = storiesCubit.stream.listen((storiesState) {
      if (storiesState is StoriesLoaded) {
        _syncFromAllStories(storiesState.stories);
      }
    });
  }

  void _syncFromAllStories(List<StoryModel> allStories) {
    final current = state;
    if (current is! MyStoriesLoaded) return;

    final myUserId = SupabaseProvider.idOrNull;
    if (myUserId == null) return;
    final myStories = allStories.where((s) => s.authorId == myUserId).toList();

    if (_sameStoryIds(myStories, current.stories)) return;

    emit(current.copyWith(stories: myStories));

    _loadStats();
  }

  bool _sameStoryIds(List<StoryModel> a, List<StoryModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
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

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
