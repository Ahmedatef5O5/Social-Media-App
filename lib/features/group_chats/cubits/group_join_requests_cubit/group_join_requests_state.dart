part of 'group_join_requests_cubit.dart';

sealed class GroupJoinRequestsState {
  const GroupJoinRequestsState();
}

final class GroupJoinRequestsInitial extends GroupJoinRequestsState {
  const GroupJoinRequestsInitial();
}

final class GroupJoinRequestsLoading extends GroupJoinRequestsState {
  const GroupJoinRequestsLoading();
}

final class GroupJoinRequestsLoaded extends GroupJoinRequestsState {
  final List<GroupJoinRequestModel> requests;

  /// Request ids currently being accepted / rejected.
  final Set<String> busyIds;

  const GroupJoinRequestsLoaded(this.requests, {this.busyIds = const {}});
}

final class GroupJoinRequestsError extends GroupJoinRequestsState {
  final String message;
  const GroupJoinRequestsError(this.message);
}
