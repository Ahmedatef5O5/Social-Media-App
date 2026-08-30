part of 'search_reels_cubit.dart';

sealed class SearchReelsState {
  const SearchReelsState();
}

final class SearchReelsInitial extends SearchReelsState {}

final class SearchReelsLoading extends SearchReelsState {}

final class SearchReelsLoaded extends SearchReelsState {
  final List<ReelModel> reels;
  final bool hasReachedMax;
  const SearchReelsLoaded({required this.reels, required this.hasReachedMax});
}

final class SearchReelsError extends SearchReelsState {
  final String message;
  const SearchReelsError(this.message);
}

final class SearchReelsSearching extends SearchReelsState {}

final class SearchReelsSearchResults extends SearchReelsState {
  final List<ReelModel> reels;
  final bool hasReachedMax;
  final String query;
  const SearchReelsSearchResults({
    required this.reels,
    required this.hasReachedMax,
    required this.query,
  });
}
