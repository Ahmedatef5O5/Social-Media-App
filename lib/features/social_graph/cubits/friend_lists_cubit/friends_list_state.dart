part of 'friends_list_cubit.dart';

sealed class FriendsListState {
  const FriendsListState();
}

class FriendsListInitial extends FriendsListState {}

class FriendsListLoading extends FriendsListState {}

class FriendsListLoaded extends FriendsListState {
  final List<FriendListItemModel> friends;
  final bool hasReachedMax;
  final int? totalCount;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  const FriendsListLoaded({
    required this.friends,
    required this.hasReachedMax,
    this.totalCount,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  int get total => totalCount ?? friends.length;
}

class FriendsListError extends FriendsListState {
  final String message;
  const FriendsListError(this.message);
}
