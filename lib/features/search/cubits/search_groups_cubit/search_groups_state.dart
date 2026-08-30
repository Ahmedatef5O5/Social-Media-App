part of 'search_groups_cubit.dart';

sealed class SearchGroupsState {
  const SearchGroupsState();
}

final class SearchGroupsInitial extends SearchGroupsState {}

final class SearchGroupsLoading extends SearchGroupsState {}

final class SearchGroupsLoaded extends SearchGroupsState {
  final List<GroupModel> groups;
  const SearchGroupsLoaded(this.groups);
}

final class SearchGroupsError extends SearchGroupsState {
  final String message;
  const SearchGroupsError(this.message);
}
