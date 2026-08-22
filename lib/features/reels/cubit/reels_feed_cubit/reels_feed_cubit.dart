import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../model/reel_model.dart';
import '../../services/reels_services.dart';
part 'reels_feed_state.dart';

class ReelsFeedCubit extends Cubit<ReelsFeedState> {
  final ReelsServices _reelsServices;

  final Set<String> _seenVideoIds = {};
  List<String> _preferredCategories = [];

  static const int _minGap = 2;
  static const int _maxGap = 10;

  static const int _reelsPerSection = 60;

  static const int _loadMoreBatchSize = 20;

  ReelsFeedCubit({ReelsServices? reelsServices})
    : _reelsServices = reelsServices ?? ReelsServices(),
      super(ReelsFeedInitial());

  Future<void> applyPreferredCategoriesAndFetch({
    required List<String> categories,
    required int postsCount,
  }) async {
    _preferredCategories = List<String>.of(categories);
    _seenVideoIds.clear();
    await fetchReels(postsCount: postsCount);
  }

  void updatePreferredCategories(List<String> categories) {
    _preferredCategories = List<String>.of(categories);
  }

  Future<void> fetchReels({required int postsCount}) async {
    emit(ReelsFeedLoading());
    try {
      final indices = _generateInjectionIndices(postsCount);
      if (indices.isEmpty) {
        emit(const ReelsFeedLoaded(injectionIndices: [], sections: []));
        return;
      }

      final excludeFromLastCycle = Set<String>.of(_seenVideoIds);
      _seenVideoIds.clear();

      final limit = indices.length * _reelsPerSection;
      final categories =
          _preferredCategories.isEmpty ? null : _preferredCategories;

      var pool = await _reelsServices.fetchReelsBatch(
        limit: limit,
        excludeIds: excludeFromLastCycle,
        categories: categories,
      );

      if (pool.isEmpty && excludeFromLastCycle.isNotEmpty) {
        pool = await _reelsServices.fetchReelsBatch(
          limit: limit,
          excludeIds: const {},
          categories: categories,
        );
      }

      if (pool.isEmpty && categories != null) {
        debugPrint(
          'Reels pool empty with category_filter=$categories - '
          'retrying without category filter.',
        );
        pool = await _reelsServices.fetchReelsBatch(
          limit: limit,
          excludeIds: const {},
          categories: null,
        );
      }

      if (pool.isEmpty) {
        emit(ReelsFeedEmpty());
        return;
      }

      final sections = <List<ReelModel>>[];
      for (var i = 0; i < pool.length; i += _reelsPerSection) {
        final chunk = pool.skip(i).take(_reelsPerSection).toList();
        if (chunk.isEmpty) continue;
        sections.add(chunk);
        for (final reel in chunk) {
          _seenVideoIds.add(reel.youtubeVideoId);
        }
      }

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
        categories: _preferredCategories.isEmpty ? null : _preferredCategories,
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

      for (final reel in more) {
        _seenVideoIds.add(reel.youtubeVideoId);
      }

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
