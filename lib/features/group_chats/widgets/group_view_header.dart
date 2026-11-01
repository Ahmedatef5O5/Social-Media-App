import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/group_profile_model.dart';
import 'group_square_avatar.dart';

/// Cover banner + overlapping rounded-square avatar + identity block + stats
/// card of the group profile. Mirrors the personal ProfileView layout.
class GroupViewHeader extends StatelessWidget {
  final GroupProfileModel profile;
  final bool isUploadingCover;
  final bool isUploadingAvatar;
  final VoidCallback onBack;
  final double topInset;
  final VoidCallback? onEditCover;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onOpenCover;

  const GroupViewHeader({
    super.key,
    required this.profile,
    required this.onBack,
    required this.topInset,
    this.isUploadingCover = false,
    this.isUploadingAvatar = false,
    this.onEditCover,
    this.onEditAvatar,
    this.onOpenCover,
  });

  static const double avatarSize = 92;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final coverHeight = width / 1.7;
    final hasCover = profile.coverUrl != null && profile.coverUrl!.isNotEmpty;
    final top = topInset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: coverHeight + avatarSize / 2 + 8,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── cover ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: coverHeight,
                child: GestureDetector(
                  onTap: hasCover ? onOpenCover : null,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        hasCover
                            ? CachedCloudinaryImage(
                              secureUrl: profile.coverUrl!,
                              fit: BoxFit.cover,
                              width: width,
                              height: coverHeight,
                            )
                            : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.primaryColor,
                                    theme.primaryColor.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                              stops: const [0, 0.45],
                            ),
                          ),
                        ),
                        if (isUploadingCover)
                          const ColoredBox(
                            color: Colors.black38,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── back ──
              PositionedDirectional(
                top: top + 8,
                start: 12,
                child: _CircleBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
              ),

              // ── edit cover ──
              if (onEditCover != null)
                PositionedDirectional(
                  top: top + 8,
                  end: 12,
                  child: _CircleBtn(
                    icon: Icons.photo_camera_rounded,
                    tooltip: context.l10n.changeCover,
                    onTap: isUploadingCover ? null : onEditCover,
                  ),
                ),

              // ── avatar ──
              PositionedDirectional(
                start: 20,
                top: coverHeight - avatarSize / 2,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.85),
                          width: 2.2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GroupSquareAvatar(
                            url: profile.avatarUrl,
                            size: avatarSize - 15,
                            radius: 20,
                          ),
                          if (isUploadingAvatar)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    if (onEditAvatar != null)
                      PositionedDirectional(
                        bottom: -2,
                        end: -2,
                        child: GestureDetector(
                          onTap: isUploadingAvatar ? null : onEditAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── role badge ──
              PositionedDirectional(
                end: 20,
                top: coverHeight + 10,
                child: _RoleChip(profile: profile),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: context.ls(-0.2),
                ),
              ),
              if (profile.title?.trim().isNotEmpty == true) ...[
                const Gap(4),
                Text(
                  profile.title!.trim(),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: context.ls(0),
                  ),
                ),
              ],
              const Gap(16),
              GroupStatsCard(profile: profile),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  const _CircleBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final GroupProfileModel profile;
  const _RoleChip({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, icon) = switch (profile.myRole) {
      GroupMemberRole.owner => (context.l10n.owner, Icons.workspace_premium),
      GroupMemberRole.admin => (context.l10n.admin, Icons.shield_rounded),
      _ => (context.l10n.member, Icons.person_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.primaryColor),
          const Gap(5),
          Text(
            label,
            style: theme.textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: theme.primaryColor,
              letterSpacing: context.ls(0),
            ),
          ),
        ],
      ),
    );
  }
}

/// [X] Members · [Y] Posts · [Z] Media
class GroupStatsCard extends StatelessWidget {
  final GroupProfileModel profile;
  const GroupStatsCard({super.key, required this.profile});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant.withValues(alpha: 0.6);
    final items = [
      (context.l10n.members, _fmt(profile.membersCount)),
      (context.l10n.posts, _fmt(profile.postsCount)),
      (context.l10n.media, _fmt(profile.mediaCount)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                decoration:
                    i == 0
                        ? null
                        : BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(color: outline),
                          ),
                        ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      items[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Row of rounded quick actions: Chat · Invite · Settings · New post.
class GroupQuickActions extends StatelessWidget {
  final GroupProfileModel profile;
  final VoidCallback onChat;
  final VoidCallback onInvite;
  final VoidCallback onSettings;
  final VoidCallback onNewPost;

  const GroupQuickActions({
    super.key,
    required this.profile,
    required this.onChat,
    required this.onInvite,
    required this.onSettings,
    required this.onNewPost,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <_Action>[
      _Action(Icons.chat_bubble_rounded, context.l10n.groupActionChat, onChat),
      _Action(
        Icons.person_add_alt_1_rounded,
        context.l10n.groupActionInvite,
        onInvite,
      ),
      if (profile.hasAdminPrivileges)
        _Action(
          Icons.settings_rounded,
          context.l10n.groupActionSettings,
          onSettings,
        ),
      if (profile.canPost)
        _Action(
          Icons.edit_note_rounded,
          context.l10n.groupActionNewPost,
          onNewPost,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          for (final a in actions) Expanded(child: _ActionButton(action: a)),
        ],
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.onTap);
}

class _ActionButton extends StatelessWidget {
  final _Action action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: action.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(action.icon, color: theme.primaryColor),
            ),
            const Gap(6),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall!.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: context.ls(0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Informational banner for non-admins when posting is restricted.
class GroupPostingRestrictedBanner extends StatelessWidget {
  const GroupPostingRestrictedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const Gap(10),
          Expanded(
            child: Text(
              context.l10n.onlyAdminsCanPostNotice,
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: context.ls(0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Used by the details tab: current posting policy as a readable label.
String whoCanPostLabel(BuildContext context, GroupWhoCanPost v) =>
    v == GroupWhoCanPost.all
        ? context.l10n.allMembers
        : context.l10n.adminsOnly;
