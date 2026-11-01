import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/toast/app_toast.dart';
import '../cubits/group_profile_cubit/group_profile_cubit.dart';
import '../models/group_model.dart';
import '../services/group_social_service.dart';

/// Owner-only control for `groups.who_can_post` (all members / admins only).
class GroupPostingPolicySection extends StatefulWidget {
  final GroupWhoCanPost initial;
  final GroupProfileCubit? profileCubit;
  final String groupId;
  final GroupSocialService service;

  const GroupPostingPolicySection({
    super.key,
    required this.initial,
    required this.groupId,
    required this.service,
    this.profileCubit,
  });

  @override
  State<GroupPostingPolicySection> createState() =>
      _GroupPostingPolicySectionState();
}

class _GroupPostingPolicySectionState extends State<GroupPostingPolicySection> {
  late GroupWhoCanPost _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.profileCubit?.profile?.whoCanPost ?? widget.initial;
  }

  Future<void> _set(GroupWhoCanPost next) async {
    if (next == _value || _saving) return;
    final previous = _value;
    setState(() {
      _value = next;
      _saving = true;
    });
    try {
      if (widget.profileCubit != null) {
        await widget.profileCubit!.setWhoCanPost(next);
      } else {
        await widget.service.updateWhoCanPost(widget.groupId, next);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _value = previous);
        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.whoCanPost,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: context.ls(0),
          ),
        ),
        const Gap(10),
        SegmentedButton<GroupWhoCanPost>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: GroupWhoCanPost.all,
              icon: const Icon(Icons.groups_rounded, size: 18),
              label: Text(context.l10n.allMembers),
            ),
            ButtonSegment(
              value: GroupWhoCanPost.adminsOnly,
              icon: const Icon(Icons.shield_rounded, size: 18),
              label: Text(context.l10n.adminsOnly),
            ),
          ],
          selected: {_value},
          onSelectionChanged: _saving ? null : (s) => _set(s.first),
        ),
      ],
    );
  }
}
