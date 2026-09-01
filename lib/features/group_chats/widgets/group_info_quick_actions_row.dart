import 'package:flutter/material.dart';

class GroupInfoQuickActionsRow extends StatelessWidget {
  final bool isMuted;
  final bool isMember;
  final VoidCallback onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onVideo;
  final VoidCallback onToggleMute;

  const GroupInfoQuickActionsRow({
    super.key,
    required this.isMuted,
    required this.isMember,
    required this.onMessage,
    this.onCall,
    this.onVideo,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickAction(
            icon: Icons.chat_bubble_rounded,
            label: 'Message',
            color: primary,
            onTap: onMessage,
          ),
          if (isMember) ...[
            _QuickAction(
              icon: Icons.call_rounded,
              label: 'Call',
              color: primary,
              onTap: onCall!,
            ),
            _QuickAction(
              icon: Icons.videocam_rounded,
              label: 'Video',
              color: primary,
              onTap: onVideo!,
            ),
          ],
          _QuickAction(
            icon:
                isMuted
                    ? Icons.notifications_off_rounded
                    : Icons.notifications_rounded,
            label: isMuted ? 'Unmute' :   'Mute',
            color: isMuted ? Colors.orange : primary,
            onTap: onToggleMute,
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
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
