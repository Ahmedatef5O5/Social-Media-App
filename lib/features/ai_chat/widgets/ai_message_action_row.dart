import 'package:flutter/material.dart';

class AiMessageActionRow extends StatelessWidget {
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final bool showRetry;
  final VoidCallback? onRetry;

  const AiMessageActionRow({
    super.key,
    required this.liked,
    required this.onToggleLike,
    required this.onCopy,
    required this.onShare,
    required this.showRetry,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionIcon(
            icon:
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color:
                liked ? Colors.redAccent : Colors.white.withValues(alpha: 0.75),
            onTap: onToggleLike,
            tooltip: 'Like',
          ),
          _ActionIcon(icon: Icons.copy_rounded, onTap: onCopy, tooltip: 'Copy'),
          _ActionIcon(
            icon: Icons.share_rounded,
            onTap: onShare,
            tooltip: 'Share',
          ),
          if (showRetry)
            _ActionIcon(
              icon: Icons.refresh_rounded,
              color: Colors.orangeAccent,
              onTap: onRetry,
              tooltip: 'Retry',
            ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: color ?? Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
