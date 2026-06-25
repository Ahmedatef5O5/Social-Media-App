import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/features/group_chat/models/group_member_model.dart';
import 'package:social_media_app/features/group_chat/services/group_chat_services.dart';
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
}
