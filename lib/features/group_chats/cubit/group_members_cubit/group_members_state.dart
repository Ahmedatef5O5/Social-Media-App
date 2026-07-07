part of 'group_members_cubit.dart';

sealed class GroupMembersState {
  const GroupMembersState();
}

final class GroupMembersInitial extends GroupMembersState {
  const GroupMembersInitial();
}

final class GroupMembersLoading extends GroupMembersState {
  const GroupMembersLoading();
}

final class GroupMembersLoaded extends GroupMembersState {
  final List<GroupMemberModel> members;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;

  const GroupMembersLoaded({
    required this.members,
    required this.totalCount,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  GroupMembersLoaded copyWith({
    List<GroupMemberModel>? members,
    int? totalCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GroupMembersLoaded(
      members: members ?? this.members,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final class GroupMembersError extends GroupMembersState {
  final String message;
  const GroupMembersError(this.message);
}
