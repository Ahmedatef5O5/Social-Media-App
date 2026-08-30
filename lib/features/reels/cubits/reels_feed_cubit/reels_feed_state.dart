part of 'reels_feed_cubit.dart';

sealed class ReelsFeedState {
  const ReelsFeedState();
}

class ReelsFeedInitial extends ReelsFeedState {}

class ReelsFeedLoading extends ReelsFeedState {}

class ReelsFeedEmpty extends ReelsFeedState {}

class ReelsFeedError extends ReelsFeedState {
  final String message;
  const ReelsFeedError(this.message);
}

class ReelsFeedLoaded extends ReelsFeedState {
  final List<int> injectionIndices;
  final List<List<ReelModel>> sections;
  final Set<int> loadingMoreSectionIndices;
  final Set<int> exhaustedSectionIndices;

  const ReelsFeedLoaded({
    required this.injectionIndices,
    required this.sections,
    this.loadingMoreSectionIndices = const {},
    this.exhaustedSectionIndices = const {},
  });

  ReelsFeedLoaded copyWith({
    List<int>? injectionIndices,
    List<List<ReelModel>>? sections,
    Set<int>? loadingMoreSectionIndices,
    Set<int>? exhaustedSectionIndices,
  }) {
    return ReelsFeedLoaded(
      injectionIndices: injectionIndices ?? this.injectionIndices,
      sections: sections ?? this.sections,
      loadingMoreSectionIndices:
          loadingMoreSectionIndices ?? this.loadingMoreSectionIndices,
      exhaustedSectionIndices:
          exhaustedSectionIndices ?? this.exhaustedSectionIndices,
    );
  }
}
