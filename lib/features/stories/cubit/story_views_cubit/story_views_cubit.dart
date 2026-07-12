import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import '../../model/story_viewer_model.dart';
import '../../services/stories_services.dart';
part 'story_views_state.dart';

class StoryViewsCubit extends Cubit<StoryViewsState> {
  final String storyId;
  final StoriesServices _storiesServices;

  static final Map<String, List<StoryViewerModel>> _memoryCache = {};

  StreamSubscription? _liveViewsSub;

  StoryViewsCubit({required this.storyId, StoriesServices? storiesServices})
    : _storiesServices = storiesServices ?? StoriesServices(),
      super(StoryViewsLoaded(_memoryCache[storyId] ?? _readSnapshot(storyId))) {
    _loadViewers();
    _listenForNewViews();
  }

  static List<StoryViewerModel> _readSnapshot(String storyId) {
    try {
      return LocalSnapshotStore.instance
          .readList(SnapshotKeys.storyViews(storyId))
          .map(StoryViewerModel.fromMap)
          .toList();
    } catch (e) {
      debugPrint('Failed to read story views snapshot: $e');
      return [];
    }
  }

  void _persistSnapshot(List<StoryViewerModel> viewers) {
    unawaited(
      LocalSnapshotStore.instance.saveList(
        SnapshotKeys.storyViews(storyId),
        viewers.map((v) => v.toCacheJson()).toList(),
      ),
    );
  }

  Future<void> _loadViewers() async {
    try {
      final viewers = await _storiesServices.getStoryViewers(storyId);
      _memoryCache[storyId] = viewers;
      _persistSnapshot(viewers);
      if (!isClosed) emit(StoryViewsLoaded(viewers));
    } catch (e) {
      debugPrint('Error loading story viewers: $e');
    }
  }

  void _listenForNewViews() {
    _liveViewsSub = _storiesServices.getStoryViewsStream(storyId).listen((
      rows,
    ) {
      final currentCount =
          state is StoryViewsLoaded
              ? (state as StoryViewsLoaded).viewers.length
              : 0;
      if (rows.length > currentCount) {
        _loadViewers();
      }
    });
  }

  Future<void> refresh() => _loadViewers();

  @override
  Future<void> close() {
    _liveViewsSub?.cancel();
    return super.close();
  }
}
