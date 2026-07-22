part of 'reels_feed_cubit.dart';

sealed class ReelsFeedState {
  const ReelsFeedState();
}

final class ReelsFeedInitial extends ReelsFeedState {}

final class ReelsFeedLoading extends ReelsFeedState {}

final class ReelsFeedLoaded extends ReelsFeedState {
  final List<int> injectionIndices;

  final List<List<ReelModel>> sections;

  const ReelsFeedLoaded({
    required this.injectionIndices,
    required this.sections,
  });
}

final class ReelsFeedEmpty extends ReelsFeedState {}

final class ReelsFeedError extends ReelsFeedState {
  final String message;
  const ReelsFeedError(this.message);
}
