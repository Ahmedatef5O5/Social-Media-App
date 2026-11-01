part of 'group_feed_cubit.dart';

sealed class GroupFeedState {
  const GroupFeedState();
}

final class GroupFeedInitial extends GroupFeedState {
  const GroupFeedInitial();
}

final class GroupFeedLoading extends GroupFeedState {
  const GroupFeedLoading();
}

final class GroupFeedLoaded extends GroupFeedState {
  final List<String> postIds;
  final bool hasMore;
  final bool isLoadingMore;

  const GroupFeedLoaded({
    required this.postIds,
    required this.hasMore,
    this.isLoadingMore = false,
  });
}

final class GroupFeedError extends GroupFeedState {
  final String message;
  const GroupFeedError(this.message);
}
