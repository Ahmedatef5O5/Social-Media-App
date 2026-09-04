import 'package:flutter/material.dart';
import '../../../core/utilities/file_size_formatter.dart';

class MediaSizeBadge extends StatelessWidget {
  final int? fileSizeBytes;
  final IconData icon;

  const MediaSizeBadge({
    super.key,
    required this.fileSizeBytes,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : primary.withValues(alpha: 0.22),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? Colors.white70 : primary),
          const SizedBox(width: 5),
          Text(
            formatMediaFileSize(fileSizeBytes),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
