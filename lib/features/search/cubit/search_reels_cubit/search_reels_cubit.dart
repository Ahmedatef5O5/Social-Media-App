import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../reels/services/reels_services.dart';
import '../../../reels/model/reel_model.dart';
part 'search_reels_state.dart';

class SearchReelsCubit extends Cubit<SearchReelsState> {
  final ReelsServices _reelsServices;

  SearchReelsCubit({ReelsServices? reelsServices})
    : _reelsServices = reelsServices ?? ReelsServices(),
      super(SearchReelsInitial());

  static const int _pageSize = 30;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final Set<String> _seenVideoIds = {};
  final List<ReelModel> _reels = [];
  String _lastSearchQuery = '';
  bool _searchHasReachedMax = false;
  static const int _searchPageSize = 30;

  Future<void> getReels({bool isRefresh = false}) async {
    if (isRefresh) {
      _seenVideoIds.clear();
      _reels.clear();
      _hasReachedMax = false;
      emit(SearchReelsLoading());
    } else if (_reels.isEmpty) {
      emit(SearchReelsLoading());
    }

    if (_hasReachedMax || _isFetchingMore) return;
    _isFetchingMore = true;

    try {
      final batch = await _reelsServices.fetchReelsBatch(
        limit: _pageSize,
        excludeIds: _seenVideoIds,
      );

      if (batch.isEmpty) {
        _hasReachedMax = true;
      } else {
        _reels.addAll(batch);
        for (final reel in batch) {
          _seenVideoIds.add(reel.youtubeVideoId);
        }
        if (batch.length < _pageSize) _hasReachedMax = true;
      }

      emit(
        SearchReelsLoaded(
          reels: List.of(_reels),
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      emit(
        const SearchReelsError('Something went wrong. Please try again later.'),
      );
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> searchReels(String query) async {
    final trimmed = query.trim();
    _lastSearchQuery = trimmed;

    if (trimmed.isEmpty) {
      // Back to browsing — the pool we already had is still intact.
      emit(
        SearchReelsLoaded(
          reels: List.of(_reels),
          hasReachedMax: _hasReachedMax,
        ),
      );
      return;
    }

    emit(SearchReelsSearching());
    try {
      final results = await _reelsServices.searchReels(
        query: trimmed,
        limit: _searchPageSize,
      );
      if (_lastSearchQuery != trimmed) return;
      _searchHasReachedMax = results.length < _searchPageSize;
      emit(
        SearchReelsSearchResults(
          reels: results,
          hasReachedMax: _searchHasReachedMax,
          query: trimmed,
        ),
      );
    } catch (e) {
      if (_lastSearchQuery != trimmed) return;
      emit(
        const SearchReelsError('Something went wrong. Please try again later.'),
      );
    }
  }

  Future<void> loadMoreSearchResults() async {
    final current = state;
    if (current is! SearchReelsSearchResults || current.hasReachedMax) return;

    try {
      final more = await _reelsServices.searchReels(
        query: current.query,
        limit: _searchPageSize,
        offset: current.reels.length,
      );
      if (_lastSearchQuery != current.query) return;
      _searchHasReachedMax = more.length < _searchPageSize;
      emit(
        SearchReelsSearchResults(
          reels: [...current.reels, ...more],
          hasReachedMax: _searchHasReachedMax,
          query: current.query,
        ),
      );
    } catch (_) {
      // Silent on purpose — keep showing what we already have.
    }
  }
}
