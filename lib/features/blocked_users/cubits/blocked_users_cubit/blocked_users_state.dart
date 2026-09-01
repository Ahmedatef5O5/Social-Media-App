part of 'blocked_users_cubit.dart';

abstract class BlockedUsersState {
  const BlockedUsersState();
}

class BlockedUsersInitial extends BlockedUsersState {}

class BlockedUsersLoading extends BlockedUsersState {}

class BlockedUsersLoaded extends BlockedUsersState {
  final List<BlockedUserItemModel> items;
  const BlockedUsersLoaded(this.items);
}

class BlockedUsersError extends BlockedUsersState {
  final String message;
  const BlockedUsersError(this.message);
}
