import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../models/group_member_model.dart';

class GroupInfoMembersList extends StatelessWidget {
  final List<GroupMemberModel> members;
  final String currentUserId;
  final bool isAdmin;
  final Color primary;
  final Function(GroupMemberModel) onRemove;

  const GroupInfoMembersList({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.isAdmin,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final member = members[index];
        final isCurrentUser = member.userId == currentUserId;
        final isMemberAdmin = member.role == GroupMemberRole.admin;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: primary.withValues(alpha: 0.12),
            backgroundImage:
                member.userAvatar?.isNotEmpty == true
                    ? CachedNetworkImageProvider(member.userAvatar!)
                    : null,
            child:
                member.userAvatar?.isEmpty != false
                    ? Text(
                      member.userName.isNotEmpty
                          ? member.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          title: Row(
            children: [
              Text(
                isCurrentUser ? 'You' : member.userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isMemberAdmin) ...[
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing:
              isAdmin && !isCurrentUser
                  ? IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    onPressed: () => onRemove(member),
                  )
                  : null,
        );
      }, childCount: members.length),
    );
  }
}
