import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'group_restriction_widgets.dart';

/// Message · Call · Video · Posts · Mute on ONE row (Expanded children, single
/// line labels) so it never overflows at 320–360px, even with long Arabic
/// labels ("إلغاء الكتم") or a 1.15 text scale.
class GroupInfoQuickActionsRow extends StatelessWidget {
  final bool isMuted;
  final bool isMember;
  final bool isCallRestricted;
  final VoidCallback onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onVideo;
  final VoidCallback onPosts;
  final VoidCallback onToggleMute;

  const GroupInfoQuickActionsRow({
    super.key,
    required this.isMuted,
    required this.isMember,
    this.isCallRestricted = false,
    required this.onMessage,
    this.onCall,
    this.onVideo,
    required this.onPosts,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.chat_bubble_rounded,
              label: context.l10n.message,
              color: primary,
              onTap: onMessage,
            ),
          ),
          if (isMember && onCall != null && onVideo != null) ...[
            Expanded(
              child: _QuickAction(
                icon: Icons.call_rounded,
                label: context.l10n.call,
                color: primary,
                restricted: isCallRestricted,
                onTap: onCall!,
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: Icons.videocam_rounded,
                label: context.l10n.video,
                color: primary,
                restricted: isCallRestricted,
                onTap: onVideo!,
              ),
            ),
          ],
          Expanded(
            child: _QuickAction(
              icon: Icons.dynamic_feed_rounded,
              label: context.l10n.posts,
              color: primary,
              onTap: onPosts,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon:
                  isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_rounded,
              label: isMuted ? context.l10n.unmute : context.l10n.mute,
              color: isMuted ? Colors.orange : primary,
              onTap: onToggleMute,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool restricted;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.restricted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: restricted ? 0.45 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                if (restricted)
                  const PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: GroupLockBadge(),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
