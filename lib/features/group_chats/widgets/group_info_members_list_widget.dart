import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_image_provider.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../models/group_member_model.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class GroupInfoMembersList extends StatelessWidget {
  final List<GroupMemberModel> members;
  final String currentUserId;
  final bool isOwner;
  final bool isAdmin;
  final Color primary;
  final Function(GroupMemberModel) onPromote;
  final Function(GroupMemberModel) onDemote;
  final Function(GroupMemberModel) onRemove;

  const GroupInfoMembersList({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.isOwner,
    required this.isAdmin,
    required this.primary,
    required this.onPromote,
    required this.onDemote,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sortedMembers = _sortedMembers();
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final member = sortedMembers[index];
        final isCurrentUser = member.userId == currentUserId;
        final isMemberOwner = member.role == GroupMemberRole.owner;
        final isMemberAdmin = member.role == GroupMemberRole.admin;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: GestureDetector(
            onTap:
                isCurrentUser
                    ? () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        AppRoutes.fullScreenImageViewRoute,
                        arguments: {
                          'url':
                              (member.userAvatar != null &&
                                      member.userAvatar!.isNotEmpty)
                                  ? member.userAvatar!
                                  : AppImages.defaultUserImg,
                          'tag': member.id,
                          'isAsset':
                              member.userAvatar == null ||
                              member.userAvatar!.isEmpty,
                        },
                      );
                    }
                    : () {
                      final user = ChatUserModel(
                        id: member.userId,
                        name: member.userName,
                        imageUrl: member.userAvatar,
                      );

                      showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder:
                            (_) => UserPreviewDialog(
                              user: user,
                              showContactOptions: true,
                            ),
                      );
                    },
            child: Hero(
              tag: member.id,
              child: PresenceAvatarWidget(
                userId: member.userId,
                avatarSize: 48,
                showBorder: false,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  backgroundImage:
                      member.userAvatar?.isNotEmpty == true
                          ? AppImageProvider.avatar(
                            member.userAvatar!,
                            radius: 24,
                          )
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
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                isCurrentUser ? context.l10n.you : member.userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isMemberOwner) ...[
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 11,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 3),
                      Text(
                        context.l10n.owner,
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isMemberAdmin) ...[
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
                    context.l10n.admin,
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
          trailing: _buildTrailing(
            context,
            member,
            isCurrentUser,
            isMemberOwner,
            isMemberAdmin,
          ),
        );
      }, childCount: sortedMembers.length),
    );
  }

  List<GroupMemberModel> _sortedMembers() {
    final owners = <GroupMemberModel>[];
    final admins = <GroupMemberModel>[];
    GroupMemberModel? me;
    final others = <GroupMemberModel>[];

    for (final m in members) {
      if (m.role == GroupMemberRole.owner) {
        owners.add(m);
      } else if (m.role == GroupMemberRole.admin) {
        admins.add(m);
      } else if (m.userId == currentUserId) {
        me = m;
      } else {
        others.add(m);
      }
    }

    return [...owners, ...admins, if (me != null) me, ...others];
  }

  Widget? _buildTrailing(
    BuildContext context,
    GroupMemberModel member,
    bool isCurrentUser,
    bool isMemberOwner,
    bool isMemberAdmin,
  ) {
    if (isCurrentUser || isMemberOwner) return null;

    if (isOwner) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
        onSelected: (value) {
          if (value == 'promote') onPromote(member);
          if (value == 'demote') onDemote(member);
          if (value == 'remove') onRemove(member);
        },
        itemBuilder:
            (context) => [
              if (!isMemberAdmin)
                PopupMenuItem(
                  value: 'promote',
                  child: Text(context.l10n.makeAdmin),
                )
              else
                PopupMenuItem(
                  value: 'demote',
                  child: Text(context.l10n.removeAdmin),
                ),
              PopupMenuItem(
                value: 'remove',
                child: Text(
                  context.l10n.removeFromGroup,
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
      );
    }

    if (isAdmin) {
      return IconButton(
        icon: const Icon(
          Icons.remove_circle_outline_rounded,
          color: Colors.redAccent,
          size: 22,
        ),
        onPressed: () => onRemove(member),
      );
    }

    return null;
  }
}
