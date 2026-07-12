import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../services/stories_services.dart';
part 'story_reaction_state.dart';

class StoryReactionCubit extends Cubit<StoryReactionState> {
  final String storyId;
  final String storyAuthorId;
  final StoriesServices _storiesServices;

  StoryReactionCubit({
    required this.storyId,
    required this.storyAuthorId,
    StoriesServices? storiesServices,
  }) : _storiesServices = storiesServices ?? StoriesServices(),
       super(const StoryReactionIdle(null)) {
    _loadInitialReaction();
  }

  final String _currentUserId = SupabaseProvider.id;

  bool get _isMyStory => storyAuthorId == _currentUserId;

  Future<void> _loadInitialReaction() async {
    if (_isMyStory) return;
    try {
      final reaction = await _storiesServices.getMyReaction(storyId);
      if (!isClosed) emit(StoryReactionIdle(reaction));
    } catch (e) {
      debugPrint('Error loading story reaction: $e');
    }
  }

  Future<void> toggleReaction(String emoji) async {
    final previous = state.myReaction;
    final optimistic = previous == emoji ? null : emoji;

    emit(StoryReactionSaving(optimistic));

    try {
      final result = await _storiesServices.toggleStoryReaction(
        storyId: storyId,
        reaction: emoji,
      );
      if (!isClosed) emit(StoryReactionIdle(result));
    } catch (e) {
      debugPrint('Error toggling story reaction: $e');
      if (!isClosed) {
        emit(StoryReactionFailed(previous, e.toString()));
        emit(StoryReactionIdle(previous));
      }
    }
  }

  Future<void> markViewed() async {
    if (_isMyStory) return;
    await _storiesServices.markStoryViewed(storyId);
  }
}
