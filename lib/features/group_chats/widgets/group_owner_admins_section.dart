import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/group_members_cubit/group_members_cubit.dart';
import '../models/group_member_model.dart';

class GroupOwnerAdminsSection extends StatelessWidget {
  final GroupMembersCubit membersCubit;
  final String currentUserId;
  final bool isOwner;
  final void Function(GroupMemberModel admin, String action) onAdminAction;

  const GroupOwnerAdminsSection({
    super.key,
    required this.membersCubit,
    required this.currentUserId,
    required this.isOwner,
    required this.onAdminAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildOwnerCard(context), _buildAdminsList(context)],
    );
  }

  Widget _buildOwnerCard(BuildContext context) {
    return BlocBuilder<GroupMembersCubit, GroupMembersState>(
      bloc: membersCubit,
      builder: (context, memberState) {
        GroupMemberModel? owner;
        if (memberState is GroupMembersLoaded) {
          for (final m in memberState.members) {
            if (m.role == GroupMemberRole.owner) {
              owner = m;
              break;
            }
          }
        }
        if (owner == null) return const SizedBox.shrink();

        final isMe = owner.userId == currentUserId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Owner',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      owner.userAvatar != null
                          ? CachedNetworkImageProvider(owner.userAvatar!)
                          : null,
                  child:
                      owner.userAvatar == null
                          ? Icon(Icons.person, color: Colors.grey.shade400)
                          : null,
                ),
                title: Text(
                  isMe ? 'You' : owner.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 13,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Owner',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildAdminsList(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return BlocBuilder<GroupMembersCubit, GroupMembersState>(
      bloc: membersCubit,
      builder: (context, memberState) {
        List<GroupMemberModel> admins = [];

        if (memberState is GroupMembersLoaded) {
          admins =
              memberState.members
                  .where((m) => m.role == GroupMemberRole.admin)
                  .toList();
        }

        if (admins.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Admins',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: admins.length,
                itemBuilder: (context, index) {
                  final admin = admins[index];
                  final isMe = admin.userId == currentUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          admin.userAvatar != null
                              ? CachedNetworkImageProvider(admin.userAvatar!)
                              : null,
                      child:
                          admin.userAvatar == null
                              ? Icon(Icons.person, color: Colors.grey.shade400)
                              : null,
                    ),
                    title: Text(
                      isMe ? 'You' : admin.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              color: primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 2),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onSelected: (value) => onAdminAction(admin, value),
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'demote',
                                    child: Text('Remove Admin'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Text(
                                      'Remove from group',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
