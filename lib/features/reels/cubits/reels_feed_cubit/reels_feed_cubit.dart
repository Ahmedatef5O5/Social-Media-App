import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../models/reel_model.dart';
import '../../services/reels_preferences_store.dart';
import '../../services/reels_services.dart';
part 'reels_feed_state.dart';

class ReelsFeedCubit extends Cubit<ReelsFeedState> {
  final ReelsServices _reelsServices;
  final ReelsPreferencesStore _preferencesStore;
  final Set<String> _seenVideoIds = {};
  List<String> _preferredCategories = [];
  bool _hasLoadedPersistedSeenIds = false;

  static const int _minGap = 2;
  static const int _maxGap = 10;

  static const int _reelsPerSection = 60;

  static const int _loadMoreBatchSize = 20;

  ReelsFeedCubit({
    ReelsServices? reelsServices,
    ReelsPreferencesStore? preferencesStore,
  }) : _reelsServices = reelsServices ?? ReelsServices(),
       _preferencesStore = preferencesStore ?? ReelsPreferencesStore.instance,
       super(ReelsFeedInitial());

  Future<void> _loadPersistedSeenIds() async {
    if (_hasLoadedPersistedSeenIds) return;
    _hasLoadedPersistedSeenIds = true;
    try {
      final persisted = await _preferencesStore.getRecentlyViewedIds();
      _seenVideoIds.addAll(persisted);
    } catch (e) {
      debugPrint('Failed to load persisted seen reel ids: $e');
    }
  }

  Future<void> applyPreferredCategoriesAndFetch({
    required List<String> categories,
    required int postsCount,
  }) async {
    _preferredCategories = List<String>.of(categories);
    await fetchReels(postsCount: postsCount);
  }

  void updatePreferredCategories(List<String> categories) {
    _preferredCategories = List<String>.of(categories);
  }

  Future<void> fetchReels({required int postsCount}) async {
    emit(ReelsFeedLoading());
    try {
      await _loadPersistedSeenIds();

      final indices = _generateInjectionIndices(postsCount);
      if (indices.isEmpty) {
        emit(const ReelsFeedLoaded(injectionIndices: [], sections: []));
        return;
      }

      final excludeIds = Set<String>.of(_seenVideoIds);

      final limit = indices.length * _reelsPerSection;
      final preferredCategories =
          _preferredCategories.isEmpty ? null : _preferredCategories;

      var pool = await _reelsServices.fetchReelsBatch(
        limit: limit,
        excludeIds: excludeIds,
        preferredCategories: preferredCategories,
      );

      if (pool.isEmpty && excludeIds.isNotEmpty) {
        _seenVideoIds.clear();
        await _preferencesStore.clearRecentlyViewedIds();
        pool = await _reelsServices.fetchReelsBatch(
          limit: limit,
          excludeIds: const {},
          preferredCategories: preferredCategories,
        );
      }

      if (pool.isEmpty) {
        emit(ReelsFeedEmpty());
        return;
      }

      final sections = <List<ReelModel>>[];
      final newlyViewedIds = <String>[];
      for (var i = 0; i < pool.length; i += _reelsPerSection) {
        final chunk = pool.skip(i).take(_reelsPerSection).toList();
        if (chunk.isEmpty) continue;
        sections.add(chunk);
        for (final reel in chunk) {
          _seenVideoIds.add(reel.youtubeVideoId);
          newlyViewedIds.add(reel.youtubeVideoId);
        }
      }

      unawaited(_preferencesStore.addRecentlyViewedIds(newlyViewedIds));

      final usableIndices = indices.take(sections.length).toList();

      emit(
        ReelsFeedLoaded(injectionIndices: usableIndices, sections: sections),
      );
    } catch (e) {
      debugPrint('Error fetching reels: $e');
      emit(ReelsFeedError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> loadMoreReelsForSection(int sectionIndex) async {
    final current = state;
    if (current is! ReelsFeedLoaded) return;
    if (sectionIndex < 0 || sectionIndex >= current.sections.length) return;

    if (current.loadingMoreSectionIndices.contains(sectionIndex)) return;
    if (current.exhaustedSectionIndices.contains(sectionIndex)) return;

    emit(
      current.copyWith(
        loadingMoreSectionIndices: {
          ...current.loadingMoreSectionIndices,
          sectionIndex,
        },
      ),
    );

    try {
      final more = await _reelsServices.fetchReelsBatch(
        limit: _loadMoreBatchSize,
        excludeIds: _seenVideoIds,
        preferredCategories:
            _preferredCategories.isEmpty ? null : _preferredCategories,
      );

      final latest = state;
      if (latest is! ReelsFeedLoaded) return;
      if (sectionIndex >= latest.sections.length) return;

      final stillLoading = {...latest.loadingMoreSectionIndices}
        ..remove(sectionIndex);

      if (more.isEmpty) {
        emit(
          latest.copyWith(
            loadingMoreSectionIndices: stillLoading,
            exhaustedSectionIndices: {
              ...latest.exhaustedSectionIndices,
              sectionIndex,
            },
          ),
        );
        return;
      }

      final newlyViewedIds = <String>[];
      for (final reel in more) {
        _seenVideoIds.add(reel.youtubeVideoId);
        newlyViewedIds.add(reel.youtubeVideoId);
      }
      unawaited(_preferencesStore.addRecentlyViewedIds(newlyViewedIds));

      final updatedSections = List<List<ReelModel>>.of(latest.sections);
      updatedSections[sectionIndex] = [
        ...updatedSections[sectionIndex],
        ...more,
      ];

      emit(
        latest.copyWith(
          sections: updatedSections,
          loadingMoreSectionIndices: stillLoading,
        ),
      );
    } catch (e) {
      debugPrint('Error loading more reels for section $sectionIndex: $e');
      final latest = state;
      if (latest is! ReelsFeedLoaded) return;
      final stillLoading = {...latest.loadingMoreSectionIndices}
        ..remove(sectionIndex);
      emit(latest.copyWith(loadingMoreSectionIndices: stillLoading));
    }
  }

  List<int> _generateInjectionIndices(int postsCount) {
    final random = Random();
    final indices = <int>[];
    var cursor = _minGap + random.nextInt(_maxGap - _minGap + 1);
    while (cursor < postsCount) {
      indices.add(cursor);
      cursor += _minGap + random.nextInt(_maxGap - _minGap + 1);
    }
    return indices;
  }
}
