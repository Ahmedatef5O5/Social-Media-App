import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/features/group_chats/models/group_member_model.dart';
import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import '../group_list_cubit/group_list_cubit.dart';
part 'group_members_state.dart';

class GroupMembersCubit extends Cubit<GroupMembersState> {
  final GroupChatServices _services;
  final String groupId;

  GroupMembersCubit(this._services, {required this.groupId})
    : super(const GroupMembersInitial());

  static const _pageSize = 20;
  int _currentPage = 0;

  Future<void> loadMembers() async {
    if (isClosed) return;
    _currentPage = 0;
    emit(const GroupMembersLoading());

    try {
      final result = await _services.getGroupMembersPaginated(
        groupId,
        page: 0,
        pageSize: _pageSize,
      );

      emit(
        GroupMembersLoaded(
          members: result.members,
          totalCount: result.totalCount,
          hasMore: result.members.length >= _pageSize,
        ),
      );
    } catch (e) {
      debugPrint('[GroupMembersCubit] loadMembers error: $e');
      emit(GroupMembersError(e.toString()));
    }
  }

  Future<void> loadMoreMembers() async {
    final current = state;
    if (current is! GroupMembersLoaded) return;
    if (!current.hasMore || current.isLoadingMore || isClosed) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      _currentPage++;
      final result = await _services.getGroupMembersPaginated(
        groupId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final updated = [...current.members, ...result.members];

      emit(
        GroupMembersLoaded(
          members: updated,
          totalCount: result.totalCount,
          hasMore: result.members.length >= _pageSize,
        ),
      );
    } catch (e) {
      _currentPage--;
      debugPrint('[GroupMembersCubit] loadMoreMembers error: $e');
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() => loadMembers();

  bool isCurrentUserAdmin(String currentUserId) {
    final s = state;
    if (s is! GroupMembersLoaded) return false;
    return s.members.any(
      (m) => m.userId == currentUserId && m.role == GroupMemberRole.admin,
    );
  }

  Future<void> addMembers(
    List<String> userIds, {
    required String currentUserId,
  }) async {
    if (!isCurrentUserAdmin(currentUserId)) {
      throw Exception('Only group admins can add members');
    }
    if (userIds.isEmpty) return;

    await _services.addMembers(groupId, userIds);
    await refresh();
  }

  Future<void> removeMember(
    GroupMemberModel member, {
    required String currentUserId,
  }) async {
    if (!isCurrentUserAdmin(currentUserId)) {
      throw Exception('Only group admins can remove members');
    }

    if (member.userId == currentUserId) {
      throw Exception('Use "Leave Group" to remove yourself');
    }

    final current = state;
    if (current is! GroupMembersLoaded) return;

    final updatedMembers =
        current.members.where((m) => m.userId != member.userId).toList();
    emit(
      current.copyWith(
        members: updatedMembers,
        totalCount: current.totalCount - 1,
      ),
    );

    try {
      await _services.removeMember(
        groupId,
        member.userId,
        actorId: currentUserId,
      );
    } catch (e) {
      emit(current);
      rethrow;
    }
  }

  Future<void> leaveGroup({
    required String currentUserId,
    required GroupListCubit groupListCubit,
  }) async {
    await _services.leaveGroup(groupId);
    groupListCubit.markGroupAsLeft(groupId);
  }

  Future<void> deleteGroup({
    required String currentUserId,
    required GroupListCubit groupListCubit,
    required bool isCurrentlyMember,
  }) async {
    await groupListCubit.removeGroupLocally(groupId);

    if (isCurrentlyMember) {
      unawaited(
        _services.leaveGroup(groupId).catchError((e) {
          debugPrint(
            '[GroupMembersCubit] deleteGroup: remote leave failed: $e. '
            'Group stays removed locally (tombstoned) regardless.',
          );
        }),
      );
    }
  }
}
