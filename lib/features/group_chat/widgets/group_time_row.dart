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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FormattedDate.getMessageTime(message.createdAt),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white60 : AppColors.black38,
          ),
        ),
        if (isMe) ...[const SizedBox(width: 4), _buildReadReceipt()],
      ],
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
