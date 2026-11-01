import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/group_members_cubit/group_members_cubit.dart';
import '../helpers/members_list_skeleton.dart';
import '../models/group_member_model.dart';
import '../models/group_profile_model.dart';
import 'group_info_members_list_widget.dart';

/// Tab 2 of GroupView: searchable roster, pending-requests banner for
/// owner/admins, and role management (promote / demote / remove).
class GroupMembersTab extends StatefulWidget {
  final GroupProfileModel profile;
  final GroupMembersCubit membersCubit;
  final String currentUserId;
  final VoidCallback onOpenPendingRequests;
  final VoidCallback onAddMembers;

  const GroupMembersTab({
    super.key,
    required this.profile,
    required this.membersCubit,
    required this.currentUserId,
    required this.onOpenPendingRequests,
    required this.onAddMembers,
  });

  @override
  State<GroupMembersTab> createState() => _GroupMembersTabState();
}

class _GroupMembersTabState extends State<GroupMembersTab> {
  String _query = '';

  Future<void> _remove(GroupMemberModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(context.l10n.removeMember),
            content: Text(context.l10n.removeFromTheGroup(member.userName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  context.l10n.remove,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await widget.membersCubit.removeMember(
        member,
        currentUserId: widget.currentUserId,
      );
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.profile;

    return BlocBuilder<GroupMembersCubit, GroupMembersState>(
      bloc: widget.membersCubit,
      builder: (context, state) {
        if (state is GroupMembersLoading || state is GroupMembersInitial) {
          return const SingleChildScrollView(child: MembersListSkeleton());
        }
        if (state is GroupMembersError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.failedToLoadMembers),
                TextButton(
                  onPressed: widget.membersCubit.loadMembers,
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          );
        }
        final loaded = state as GroupMembersLoaded;
        final q = _query.trim().toLowerCase();
        final members =
            q.isEmpty
                ? loaded.members
                : loaded.members
                    .where((m) => m.userName.toLowerCase().contains(q))
                    .toList();

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical &&
                n.metrics.extentAfter < 300) {
              widget.membersCubit.loadMoreMembers();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              if (p.hasAdminPrivileges && p.pendingRequestsCount > 0)
                SliverToBoxAdapter(
                  child: _PendingBanner(
                    count: p.pendingRequestsCount,
                    onTap: widget.onOpenPendingRequests,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: context.l10n.searchGroupMembers,
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (p.hasAdminPrivileges) ...[
                        const Gap(8),
                        IconButton.filledTonal(
                          tooltip: context.l10n.addMembers,
                          onPressed: widget.onAddMembers,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              GroupInfoMembersList(
                members: members,
                currentUserId: widget.currentUserId,
                isOwner: p.isOwner,
                isAdmin: p.isAdmin,
                primary: theme.primaryColor,
                onPromote: (member) async {
                  try {
                    await widget.membersCubit.promoteToAdmin(
                      member,
                      currentUserId: widget.currentUserId,
                    );
                    if (context.mounted) {
                      AppToast.success(
                        context.l10n.isNowAnAdmin(member.userName),
                      );
                    }
                  } catch (e) {
                    AppToast.error(SupabaseErrorMapper.toUserMessage(e));
                  }
                },
                onDemote: (member) async {
                  try {
                    await widget.membersCubit.demoteAdmin(
                      member,
                      currentUserId: widget.currentUserId,
                    );
                    if (context.mounted) {
                      AppToast.success(
                        context.l10n.isNoLongerAn(member.userName),
                      );
                    }
                  } catch (e) {
                    AppToast.error(SupabaseErrorMapper.toUserMessage(e));
                  }
                },
                onRemove: _remove,
              ),
              if (loaded.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CustomLoadingIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: Gap(32)),
            ],
          ),
        );
      },
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PendingBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              context.l10n.pendingRequests,
              style: theme.textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: context.ls(0),
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: onTap,
            child: Text(context.l10n.viewPendingRequests),
          ),
        ],
      ),
    );
  }
}
