import 'package:flutter/material.dart';
import '../models/feedback_models.dart';

class FeedbackStatusChip extends StatelessWidget {
  final FeedbackStatus status;
  final bool compact;
  final String? label;

  const FeedbackStatusChip({
    super.key,
    required this.status,
    this.compact = false,
    this.label,
  });

  static Color colorFor(FeedbackStatus s) => switch (s) {
    FeedbackStatus.pending => const Color(0xFFF5A623),
    FeedbackStatus.inProgress => const Color(0xFF2F80ED),
    FeedbackStatus.resolved => const Color(0xFF27AE60),
    FeedbackStatus.closed => const Color(0xFF8E8E93),
  };

  static String emojiFor(FeedbackStatus s) => switch (s) {
    FeedbackStatus.pending => '🟡',
    FeedbackStatus.inProgress => '🔵',
    FeedbackStatus.resolved => '🟢',
    FeedbackStatus.closed => '⚪',
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emojiFor(status), style: TextStyle(fontSize: compact ? 9 : 10)),
          const SizedBox(width: 5),
          Text(
            label ?? status.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
