part of 'search_friends_cubit.dart';

sealed class SearchFriendsState {
  const SearchFriendsState();
}

final class SearchFriendsInitial extends SearchFriendsState {}

final class SearchFriendsLoading extends SearchFriendsState {}

final class SearchFriendsLoaded extends SearchFriendsState {
  final List<FriendListItemModel> friends;
  final bool hasReachedMax;
  const SearchFriendsLoaded({
    required this.friends,
    required this.hasReachedMax,
  });
}

final class SearchFriendsError extends SearchFriendsState {
  final String message;
  const SearchFriendsError(this.message);
}
