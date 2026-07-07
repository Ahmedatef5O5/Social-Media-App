import 'package:flutter/material.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../models/groupe_message_model.dart';

class GroupTimeRow extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;

  const GroupTimeRow({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            FormattedDate.getMessageTime(message.createdAt),

            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color:
                  isMe
                      ? AppColors.white70
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
          const SizedBox(width: 4),
          if (isMe) ...[_buildReadReceipt(), const SizedBox(width: 3.5)],
        ],
      ),
    );
  }

  Widget _buildReadReceipt() {
    final isRead = message.readBy.isNotEmpty;

    if (isRead) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.check_rounded,
            size: 13,
            color: Colors.lightBlueAccent.shade100,
          ),
          Positioned(
            left: 5,
            child: Icon(
              Icons.check_rounded,
              size: 13,
              color: Colors.lightBlueAccent.shade100,
            ),
          ),
        ],
      );
    } else {
      return Icon(Icons.check_rounded, size: 13, color: Colors.white54);
    }
  }
}
