import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/toast/app_toast.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../cubits/group_profile_cubit/group_profile_cubit.dart';
import '../helpers/group_policy_controller.dart';
import '../models/group_model.dart';
import '../services/group_social_service.dart';
import 'group_policy_pill_selector.dart';

/// Owner-only block with the 3 sibling policies: who can post, who can send
/// and group privacy. Render ONLY when the viewer is the owner.
class GroupOwnerPoliciesSection extends StatefulWidget {
  final GroupModel group;
  final GroupListCubit listCubit;
  final GroupProfileCubit? profileCubit;
  final GroupDetailsCubit? detailsCubit;

  const GroupOwnerPoliciesSection({
    super.key,
    required this.group,
    required this.listCubit,
    this.profileCubit,
    this.detailsCubit,
  });

  @override
  State<GroupOwnerPoliciesSection> createState() =>
      _GroupOwnerPoliciesSectionState();
}

class _GroupOwnerPoliciesSectionState extends State<GroupOwnerPoliciesSection> {
  late final GroupPolicyController _controller;
  late GroupWhoCanPost _post;
  late GroupWhoCanSend _send;
  late GroupPrivacy _privacy;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = GroupPolicyController(
      groupId: widget.group.id,
      service: GroupSocialService(),
      listCubit: widget.listCubit,
      profileCubit: widget.profileCubit,
      detailsCubit: widget.detailsCubit,
    );
    final p = widget.profileCubit?.profile;
    _post = p?.whoCanPost ?? widget.group.whoCanPost;
    _send = p?.whoCanSend ?? widget.group.whoCanSend;
    _privacy = p?.privacy ?? widget.group.privacy;
  }

  @override
  void didUpdateWidget(covariant GroupOwnerPoliciesSection old) {
    super.didUpdateWidget(old);
    if (_busy) return;
    _post = widget.group.whoCanPost;
    _send = widget.group.whoCanSend;
    _privacy = widget.group.privacy;
  }

  Future<void> _run(
    VoidCallback optimistic,
    Future<void> Function() request,
    VoidCallback rollback, {
    String? successMessage,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      optimistic();
    });
    try {
      await request();
      if (mounted && successMessage != null) AppToast.success(successMessage);
    } catch (e) {
      if (mounted) {
        setState(rollback);
        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final noOne = l.groupNoOne;

    final postCaption = switch (_post) {
      GroupWhoCanPost.all => l.whoCanPostHelperAll,
      GroupWhoCanPost.adminsOnly => l.whoCanPostHelperAdmins,
      GroupWhoCanPost.ownerOnly => l.whoCanPostHelperOwner,
    };
    final sendCaption = switch (_send) {
      GroupWhoCanSend.all => l.whoCanSendHelperAll,
      GroupWhoCanSend.adminsOnly => l.whoCanSendHelperAdmins,
      GroupWhoCanSend.ownerOnly => l.whoCanSendHelperOwner,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupPolicyBlock<GroupWhoCanPost>(
          title: l.whoCanPost,
          selected: _post,
          caption: postCaption,
          onChanged:
              _busy
                  ? null
                  : (next) {
                    final prev = _post;
                    if (next == prev) return;
                    _run(
                      () => _post = next,
                      () => _controller.setWhoCanPost(next, prev),
                      () => _post = prev,
                    );
                  },
          options: [
            GroupPolicyOption(
              value: GroupWhoCanPost.all,
              icon: Icons.groups_rounded,
              label: l.allMembers,
            ),
            GroupPolicyOption(
              value: GroupWhoCanPost.adminsOnly,
              icon: Icons.shield_rounded,
              label: l.adminsOnly,
            ),
            GroupPolicyOption(
              value: GroupWhoCanPost.ownerOnly,
              icon: Icons.block_rounded,
              label: noOne,
            ),
          ],
        ),
        const Gap(24),
        GroupPolicyBlock<GroupWhoCanSend>(
          title: l.groupWhoCanSend,
          selected: _send,
          caption: sendCaption,
          onChanged:
              _busy
                  ? null
                  : (next) {
                    final prev = _send;
                    if (next == prev) return;
                    _run(
                      () => _send = next,
                      () => _controller.setWhoCanSend(next, prev),
                      () => _send = prev,
                    );
                  },
          options: [
            GroupPolicyOption(
              value: GroupWhoCanSend.all,
              icon: Icons.groups_rounded,
              label: l.allMembers,
            ),
            GroupPolicyOption(
              value: GroupWhoCanSend.adminsOnly,
              icon: Icons.shield_rounded,
              label: l.adminsOnly,
            ),
            GroupPolicyOption(
              value: GroupWhoCanSend.ownerOnly,
              icon: Icons.block_rounded,
              label: noOne,
            ),
          ],
        ),
        const Gap(24),
        GroupPolicyBlock<GroupPrivacy>(
          title: l.groupPrivacyTitle,
          selected: _privacy,
          caption:
              _privacy.isPublic
                  ? l.groupPrivacyPublicHelper
                  : l.groupPrivacyPrivateHelper,
          onChanged:
              _busy
                  ? null
                  : (next) {
                    final prev = _privacy;
                    if (next == prev) return;
                    _run(
                      () => _privacy = next,
                      () => _controller.setPrivacy(next, prev),
                      () => _privacy = prev,
                      successMessage: l.groupPolicyUpdated,
                    );
                  },
          options: [
            GroupPolicyOption(
              value: GroupPrivacy.publicGroup,
              icon: Icons.public_rounded,
              label: l.groupPrivacyPublic,
            ),
            GroupPolicyOption(
              value: GroupPrivacy.privateGroup,
              icon: Icons.lock_rounded,
              label: l.groupPrivacyPrivate,
            ),
          ],
        ),
      ],
    );
  }
}
