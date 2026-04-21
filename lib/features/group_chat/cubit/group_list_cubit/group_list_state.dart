part of 'group_list_cubit.dart';

sealed class GroupListState {}

final class GroupListInitial extends GroupListState {}

final class GroupListLoading extends GroupListState {}

final class GroupListLoaded extends GroupListState {
  final List<GroupModel> groups;
  GroupListLoaded(this.groups);
}

final class GroupListError extends GroupListState {
  final String message;
  GroupListError(this.message);
}
