import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import '../../models/story_model.dart';
import '../../models/story_stat_model.dart';
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

    if (_sameStories(myStories, current.stories)) return;

    final validIds = myStories.map((s) => s.id).toSet();
    final prunedSelection = current.selectedStoryIds.intersection(validIds);

    emit(
      current.copyWith(stories: myStories, selectedStoryIds: prunedSelection),
    );

    _loadStats();
  }

  bool _sameStories(List<StoryModel> a, List<StoryModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final sa = a[i];
      final sb = b[i];
      if (sa.id != sb.id) return false;
      if (sa.isPendingUpload != sb.isPendingUpload) return false;
      if (sa.imageUrl != sb.imageUrl) return false;
      if (sa.videoUrl != sb.videoUrl) return false;
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

    emit(
      current.copyWith(
        deletingStoryIds: {...current.deletingStoryIds, storyId},
      ),
    );
    try {
      await storiesCubit.deleteStory(storyId);
      _removeStoriesLocally({storyId});
    } catch (e) {
      debugPrint('Error deleting story: $e');
      final c = state;
      if (!isClosed && c is MyStoriesLoaded) {
        emit(
          c.copyWith(
            deletingStoryIds: c.deletingStoryIds.difference({storyId}),
          ),
        );
      }
    }
  }

  // ── Multi-select ─────────────────────────────────────────────────────────

  void enterSelectionMode(String initialStoryId) {
    final current = state;
    if (current is! MyStoriesLoaded) return;
    if (current.isSelectionMode) return;
    emit(current.copyWith(selectedStoryIds: {initialStoryId}));
  }

  void toggleSelection(String storyId) {
    final current = state;
    if (current is! MyStoriesLoaded) return;

    final updated = Set<String>.from(current.selectedStoryIds);
    if (!updated.remove(storyId)) {
      updated.add(storyId);
    }
    emit(current.copyWith(selectedStoryIds: updated));
  }

  void clearSelection() {
    final current = state;
    if (current is! MyStoriesLoaded) return;
    emit(current.copyWith(selectedStoryIds: const {}));
  }

  Future<void> deleteSelectedStories() async {
    final current = state;
    if (current is! MyStoriesLoaded) return;

    final ids = Set<String>.from(current.selectedStoryIds);
    if (ids.isEmpty) return;

    emit(
      current.copyWith(
        deletingStoryIds: {...current.deletingStoryIds, ...ids},
        selectedStoryIds: const {},
      ),
    );

    final failedIds = <String>{};

    await Future.wait(
      ids.map((id) async {
        try {
          await storiesCubit.deleteStory(id);
        } catch (e) {
          debugPrint('Error deleting story $id: $e');
          failedIds.add(id);
        }
      }),
    );

    final succeededIds = ids.difference(failedIds);
    _removeStoriesLocally(succeededIds);

    if (failedIds.isNotEmpty) {
      final c = state;
      if (!isClosed && c is MyStoriesLoaded) {
        emit(
          c.copyWith(
            deletingStoryIds: c.deletingStoryIds.difference(failedIds),
          ),
        );
      }
      AppToast.warning(
        failedIds.length == 1
            ? 'One story could not be deleted'
            : '${failedIds.length} stories could not be deleted',
      );
    }
  }

  void _removeStoriesLocally(Set<String> ids) {
    if (ids.isEmpty) return;
    final current = state;
    if (current is! MyStoriesLoaded) return;

    final updatedStories =
        current.stories.where((s) => !ids.contains(s.id)).toList();
    final updatedStats = Map<String, StoryStatModel>.from(
      current.statsByStoryId,
    )..removeWhere((id, _) => ids.contains(id));

    emit(
      MyStoriesLoaded(
        stories: updatedStories,
        statsByStoryId: updatedStats,
        deletingStoryIds: current.deletingStoryIds.difference(ids),
        selectedStoryIds: current.selectedStoryIds.difference(ids),
      ),
    );
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
