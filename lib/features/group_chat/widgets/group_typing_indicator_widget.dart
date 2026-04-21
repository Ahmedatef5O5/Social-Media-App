import 'package:flutter/material.dart';

class GroupTypingIndicator extends StatelessWidget {
  final List<String> typingUserIds;
  const GroupTypingIndicator({super.key, required this.typingUserIds});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = typingUserIds.length;
    final label =
        count == 1 ? 'Someone is typing...' : '$count people are typing...';

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
