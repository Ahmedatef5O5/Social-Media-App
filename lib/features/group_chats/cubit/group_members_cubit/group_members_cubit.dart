import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/features/group_chats/models/group_member_model.dart';
import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../models/group_add_members_result.dart';
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
      emit(GroupMembersError(SupabaseErrorMapper.toUserMessage(e)));
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

  bool isCurrentUserOwner(String currentUserId) {
    final s = state;
    if (s is! GroupMembersLoaded) return false;
    return s.members.any(
      (m) => m.userId == currentUserId && m.role == GroupMemberRole.owner,
    );
  }

  bool isCurrentUserAdmin(String currentUserId) {
    final s = state;
    if (s is! GroupMembersLoaded) return false;
    return s.members.any(
      (m) => m.userId == currentUserId && m.role == GroupMemberRole.admin,
    );
  }

  /// True for `admin` **or** `owner`. Use this (not [isCurrentUserAdmin])
  /// everywhere a "can manage the group" gate is needed — e.g. adding /
  /// removing members, editing group info — since the Owner is a superset
  /// of Admin privileges but has a distinct role value in the DB.
  /// [isCurrentUserAdmin] on its own deliberately stays admin-only: it's
  /// still used to render the "Admin" badge for a *specific* member row,
  /// where owner and admin must NOT be conflated.
  bool hasAdminPrivileges(String currentUserId) {
    final s = state;
    if (s is! GroupMembersLoaded) return false;
    return s.members.any(
      (m) =>
          m.userId == currentUserId &&
          (m.role == GroupMemberRole.admin ||
              m.role == GroupMemberRole.owner),
    );
  }

  Future<void> promoteToAdmin(
    GroupMemberModel member, {
    required String currentUserId,
  }) async {
    if (!isCurrentUserOwner(currentUserId)) {
      throw Exception('Only the group owner can promote members');
    }
    final current = state;
    if (current is! GroupMembersLoaded) return;

    final updated =
        current.members.map((m) {
          return m.userId == member.userId
              ? GroupMemberModel(
                id: m.id,
                groupId: m.groupId,
                userId: m.userId,
                userName: m.userName,
                userAvatar: m.userAvatar,
                role: GroupMemberRole.admin,
                joinedAt: m.joinedAt,
              )
              : m;
        }).toList();
    emit(current.copyWith(members: updated));

    try {
      await _services.promoteToAdmin(groupId, member.userId);
    } catch (e) {
      emit(current); // rollback
      rethrow;
    }
  }

  Future<void> demoteAdmin(
    GroupMemberModel member, {
    required String currentUserId,
  }) async {
    if (!isCurrentUserOwner(currentUserId)) {
      throw Exception('Only the group owner can demote admins');
    }
    final current = state;
    if (current is! GroupMembersLoaded) return;

    final updated =
        current.members.map((m) {
          return m.userId == member.userId
              ? GroupMemberModel(
                id: m.id,
                groupId: m.groupId,
                userId: m.userId,
                userName: m.userName,
                userAvatar: m.userAvatar,
                role: GroupMemberRole.member,
                joinedAt: m.joinedAt,
              )
              : m;
        }).toList();
    emit(current.copyWith(members: updated));

    try {
      await _services.demoteAdmin(groupId, member.userId);
    } catch (e) {
      emit(current); // rollback
      rethrow;
    }
  }

  Future<GroupAddMembersResult> addMembers(
    List<String> userIds, {
    required String currentUserId,
  }) async {
    if (!hasAdminPrivileges(currentUserId)) {
      throw Exception('Only group admins can add members');
    }
    if (userIds.isEmpty) {
      return const GroupAddMembersResult(added: [], failed: []);
    }

    final result = await _services.addMembers(groupId, userIds);
    if (result.added.isNotEmpty) {
      await refresh();
    }
    return result;
  }

  Future<void> removeMember(
    GroupMemberModel member, {
    required String currentUserId,
  }) async {
    if (!hasAdminPrivileges(currentUserId)) {
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

  Future<void> blockGroup({
    required String currentUserId,
    required GroupListCubit groupListCubit,
    required bool isCurrentlyMember,
  }) async {
    await _services.blockGroup(groupId, wasMember: isCurrentlyMember);
    await groupListCubit.removeGroupLocally(groupId);
  }

  /// Permanently deletes the group for **everyone** — owner-only, enforced
  /// both here (client-side gate, fast local feedback) and again inside the
  /// `delete_group_permanently` RPC (server-side, can't be bypassed).
  /// Removes the group's messages, members, reactions, mentions, typing
  /// rows and calls, then the group row itself. Other members see the
  /// group vanish from their list on its own — [GroupListCubit] already
  /// listens for `group_members`/`groups` DELETE realtime events and
  /// removes the group from every affected user's local state.
  Future<void> deleteGroup({
    required String currentUserId,
    required GroupListCubit groupListCubit,
  }) async {
    if (!isCurrentUserOwner(currentUserId)) {
      throw Exception('Only the group owner can delete this group');
    }
    await _services.deleteGroupPermanently(groupId);
    await groupListCubit.removeGroupLocally(groupId);
  }
}