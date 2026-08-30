part of 'friends_list_cubit.dart';

sealed class FriendsListState {
  const FriendsListState();
}

class FriendsListInitial extends FriendsListState {}

class FriendsListLoading extends FriendsListState {}

class FriendsListLoaded extends FriendsListState {
  final List<FriendListItemModel> friends;
  final bool hasReachedMax;
  const FriendsListLoaded({required this.friends, required this.hasReachedMax});
}

class FriendsListError extends FriendsListState {
  final String message;
  const FriendsListError(this.message);
}
