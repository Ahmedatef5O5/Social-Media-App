import 'package:flutter/material.dart';
import '../utilities/file_size_formatter.dart';

class MediaDurationBadge extends StatelessWidget {
  final int? seconds;
  final double fontSize;

  const MediaDurationBadge({
    super.key,
    required this.seconds,
    this.fontSize = 9,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = formatMediaDuration(seconds);
    if (formatted.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        formatted,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
