import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/story_viewer_model.dart';
import '../../services/stories_services.dart';

part 'story_views_state.dart';

class StoryViewsCubit extends Cubit<StoryViewsState> {
  final String storyId;
  final StoriesServices _storiesServices;

  StoryViewsCubit({required this.storyId, StoriesServices? storiesServices})
    : _storiesServices = storiesServices ?? StoriesServices(),
      super(const StoryViewsLoading()) {
    _loadViewers();
  }

  Future<void> _loadViewers() async {
    try {
      final viewers = await _storiesServices.getStoryViewers(storyId);
      if (!isClosed) emit(StoryViewsLoaded(viewers));
    } catch (e) {
      debugPrint('Error loading story viewers: $e');
      if (!isClosed) emit(StoryViewsError(e.toString()));
    }
  }

  Future<void> refresh() => _loadViewers();
}
