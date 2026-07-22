import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/reel_model.dart';
import '../../services/reels_services.dart';
part 'reels_feed_state.dart';

class ReelsFeedCubit extends Cubit<ReelsFeedState> {
  final ReelsServices _reelsServices;

  final Set<String> _displayedLeadVideoIds = {};

  static const int _minGap = 5;
  static const int _maxGap = 6; // inclusive

  static const int _reelsPerSection = 24;

  ReelsFeedCubit({ReelsServices? reelsServices})
    : _reelsServices = reelsServices ?? ReelsServices(),
      super(ReelsFeedInitial());

  Future<void> fetchReels({required int postsCount}) async {
    emit(ReelsFeedLoading());
    try {
      final indices = _generateInjectionIndices(postsCount);
      if (indices.isEmpty) {
        emit(const ReelsFeedLoaded(injectionIndices: [], sections: []));
        return;
      }

      final pool = await _reelsServices.fetchReelsBatch(
        limit: indices.length * _reelsPerSection,
        excludeIds: _displayedLeadVideoIds,
      );

      if (pool.isEmpty) {
        emit(ReelsFeedEmpty());
        return;
      }

      final sections = <List<ReelModel>>[];
      for (var i = 0; i < pool.length; i += _reelsPerSection) {
        final chunk = pool.skip(i).take(_reelsPerSection).toList();
        if (chunk.isEmpty) continue;
        sections.add(chunk);
        _displayedLeadVideoIds.add(chunk.first.youtubeVideoId);
      }

      final usableIndices = indices.take(sections.length).toList();

      emit(
        ReelsFeedLoaded(injectionIndices: usableIndices, sections: sections),
      );
    } catch (e) {
      debugPrint('Error fetching reels: $e');
      emit(ReelsFeedError(e.toString()));
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
