import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../local/story_reaction_local_data_source.dart';
import '../../services/stories_services.dart';
part 'story_reaction_state.dart';

class StoryReactionCubit extends Cubit<StoryReactionState> {
  final String storyId;
  final String storyAuthorId;
  final StoriesServices _storiesServices;
  final StoryReactionLocalDataSource _localDataSource;

  StoryReactionCubit({
    required this.storyId,
    required this.storyAuthorId,
    StoriesServices? storiesServices,
    StoryReactionLocalDataSource? localDataSource,
  }) : _storiesServices = storiesServices ?? StoriesServices(),
       _localDataSource =
           localDataSource ?? StoryReactionLocalDataSource.instance,
       super(
         StoryReactionIdle(
           (localDataSource ?? StoryReactionLocalDataSource.instance)
               .getCachedReaction(storyId),
         ),
       ) {
    _syncWithServerSilently();
  }

  final String _currentUserId = SupabaseProvider.id;

  bool get _isMyStory => storyAuthorId == _currentUserId;

  Future<void> _syncWithServerSilently() async {
    if (_isMyStory) return;
    try {
      final serverReaction = await _storiesServices.getMyReaction(storyId);
      final cachedReaction = _localDataSource.getCachedReaction(storyId);

      if (serverReaction != cachedReaction) {
        await _localDataSource.setCachedReaction(storyId, serverReaction);
        if (!isClosed) {
          emit(StoryReactionIdle(serverReaction));
        }
      }
    } catch (e) {
      debugPrint('Error syncing story reaction: $e');
    }
  }

  Future<void> toggleReaction(String emoji) async {
    final previous = state.myReaction;
    final optimistic = previous == emoji ? null : emoji;

    await _localDataSource.setCachedReaction(storyId, optimistic);

    emit(StoryReactionSaving(optimistic));

    try {
      final result = await _storiesServices.toggleStoryReaction(
        storyId: storyId,
        reaction: emoji,
      );
      await _localDataSource.setCachedReaction(storyId, result);

      if (result != null) {
        unawaited(_notifyStoryAuthor(reaction: result));
      }

      if (!isClosed) emit(StoryReactionIdle(result));
    } catch (e) {
      debugPrint('Error toggling story reaction: $e');
      await _localDataSource.setCachedReaction(storyId, previous);

      if (!isClosed) {
        emit(StoryReactionFailed(previous, e.toString()));
        emit(StoryReactionIdle(previous));
      }
    }
  }

  Future<void> _notifyStoryAuthor({required String reaction}) async {
    try {
      final me =
          await SupabaseProvider.client
              .from('users')
              .select('name, image_url')
              .eq('id', _currentUserId)
              .maybeSingle();

      await FcmService.instance.notifyStoryReact(
        receiverId: storyAuthorId,
        actorId: _currentUserId,
        actorName: (me?['name'] as String?) ?? 'Someone',
        actorImageUrl: (me?['image_url'] as String?) ?? '',
        storyId: storyId,
        reactionType: reaction,
      );
    } catch (e) {
      debugPrint('⚠️ story reaction notification silent error: $e');
    }
  }

  Future<void> markViewed() async {
    if (_isMyStory) return;
    await _storiesServices.markStoryViewed(storyId);
  }
}
