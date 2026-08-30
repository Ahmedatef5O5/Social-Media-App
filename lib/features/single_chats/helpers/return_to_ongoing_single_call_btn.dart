import 'package:flutter/material.dart';

class ReturnToOngoingSingleCallButton extends StatelessWidget {
  final bool isVideo;
  final VoidCallback onTap;
  final bool isMe;

  const ReturnToOngoingSingleCallButton({
    super.key,
    required this.isVideo,
    required this.onTap,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isMe
                    ? Colors.white.withValues(alpha: 0.5)
                    : accent.withValues(alpha: isDark ? 0.28 : 0.16),
                isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : accent.withValues(alpha: isDark ? 0.16 : 0.08),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.55 : 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                size: 15,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                'Return to call',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
