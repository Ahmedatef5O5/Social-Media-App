import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../cubits/group_profile_cubit/group_profile_cubit.dart';
import '../models/group_model.dart';
import '../services/group_social_service.dart';
import 'group_role_resolver.dart';

/// Owner-only policy edits (`who_can_post`, `who_can_send`, `privacy`).
/// Applies the change optimistically to every live cubit, then persists it and
/// rolls everything back (rethrowing) when the server refuses.
class GroupPolicyController {
  final String groupId;
  final GroupSocialService service;
  final GroupListCubit listCubit;
  final GroupProfileCubit? profileCubit;
  final GroupDetailsCubit? detailsCubit;

  GroupPolicyController({
    required this.groupId,
    required this.service,
    required this.listCubit,
    this.profileCubit,
    this.detailsCubit,
  });

  void _apply({
    GroupWhoCanPost? whoCanPost,
    GroupWhoCanSend? whoCanSend,
    GroupPrivacy? privacy,
  }) {
    listCubit.applyGroupPolicyInState(
      groupId: groupId,
      whoCanPost: whoCanPost,
      whoCanSend: whoCanSend,
      privacy: privacy,
    );
    profileCubit?.applyPolicyLocal(
      whoCanPost: whoCanPost,
      whoCanSend: whoCanSend,
      privacy: privacy,
    );
    if (detailsCubit != null && !detailsCubit!.isClosed) {
      detailsCubit!.applyPolicyLocal(whoCanSend: whoCanSend);
    }
    GroupRoleResolver.invalidate(groupId);
  }

  Future<void> setWhoCanPost(
    GroupWhoCanPost next,
    GroupWhoCanPost previous,
  ) async {
    _apply(whoCanPost: next);
    try {
      await service.updateWhoCanPost(groupId, next);
    } catch (_) {
      _apply(whoCanPost: previous);
      rethrow;
    }
  }

  Future<void> setWhoCanSend(
    GroupWhoCanSend next,
    GroupWhoCanSend previous,
  ) async {
    _apply(whoCanSend: next);
    try {
      await service.updateWhoCanSend(groupId, next);
    } catch (_) {
      _apply(whoCanSend: previous);
      rethrow;
    }
  }

  Future<void> setPrivacy(GroupPrivacy next, GroupPrivacy previous) async {
    _apply(privacy: next);
    try {
      await service.updatePrivacy(groupId, next);
    } catch (_) {
      _apply(privacy: previous);
      rethrow;
    }
  }
}
