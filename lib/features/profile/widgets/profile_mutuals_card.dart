import 'package:flutter/material.dart';
import '../models/profile_mutuals_model.dart';
import '../utils/profile_ui_tokens.dart';
import 'profile_avatar_stack.dart';

class ProfileMutualsCard extends StatelessWidget {
  final ProfileMutualsModel mutuals;

  const ProfileMutualsCard({super.key, required this.mutuals});

  @override
  Widget build(BuildContext context) {
    if (mutuals.isEmpty) return const SizedBox.shrink();

    final tokens = ProfileUiTokens.of(context);
    final hasFriends = mutuals.friendsCount > 0;
    final hasGroups = mutuals.groupsCount > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: ProfileUiTokens.screenPadding,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
        border: Border.all(color: tokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFriends) _MutualFriendsRow(mutuals: mutuals, tokens: tokens),
          if (hasFriends && hasGroups)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 0.5, color: tokens.outline),
            ),
          if (hasGroups) _MutualGroupsSection(mutuals: mutuals, tokens: tokens),
        ],
      ),
    );
  }
}

class _MutualFriendsRow extends StatelessWidget {
  final ProfileMutualsModel mutuals;
  final ProfileUiTokens tokens;

  const _MutualFriendsRow({required this.mutuals, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final total = mutuals.friendsCount;
    final subtitle = _buildSentence(mutuals.friends, total);

    return Row(
      children: [
        ProfileAvatarStack(
          imageUrls: mutuals.friends.map((f) => f.imageUrl).toList(),
          size: 28,
          overlap: 10,
          ringWidth: 2,
          ringColor: tokens.surface,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total mutual ${total == 1 ? 'friend' : 'friends'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.onSurface,
                  height: 1.25,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _buildSentence(List<ProfileMutualFriend> friends, int total) {
    final names =
        friends.map((f) => f.name.trim()).where((n) => n.isNotEmpty).toList();
    if (names.isEmpty || total <= 0) return '';

    if (total == 1) return '${names[0]} is friends with both of you';

    if (total == 2) {
      final second = names.length > 1 ? names[1] : '1 other';
      return '${names[0]} and $second are friends with both of you';
    }

    if (names.length < 2) {
      final others = total - 1;
      return '${names[0]} and $others others are friends with both of you';
    }
    final others = total - 2;
    return '${names[0]}, ${names[1]} and $others '
        '${others == 1 ? 'other' : 'others'} are friends with both of you';
  }
}

class _MutualGroupsSection extends StatelessWidget {
  final ProfileMutualsModel mutuals;
  final ProfileUiTokens tokens;

  const _MutualGroupsSection({required this.mutuals, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final total = mutuals.groupsCount;
    final hiddenCount = total - mutuals.groups.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$total mutual ${total == 1 ? 'group' : 'groups'}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.onSurface,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final group in mutuals.groups)
              _GroupChip(
                label: group.name,
                icon: Icons.groups_rounded,
                background: tokens.primaryTonal,
                foreground: tokens.iconAccent,
              ),
            if (hiddenCount > 0)
              _GroupChip(
                label: '+$hiddenCount',
                background: tokens.surfaceVariant,
                foreground: tokens.onSurfaceVariant,
              ),
          ],
        ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  const _GroupChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
