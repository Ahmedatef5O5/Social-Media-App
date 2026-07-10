import 'package:flutter/material.dart';

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
    if (seconds == null) return const SizedBox.shrink();
    final m = (seconds! ~/ 60).toString().padLeft(2, '0');
    final s = (seconds! % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$m:$s',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
