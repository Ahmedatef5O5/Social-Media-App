import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../models/groupe_message_model.dart';

class GroupMessageReplyPreview extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Color primary;

  const GroupMessageReplyPreview({
    super.key,
    required this.message,
    required this.isMe,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: isMe ? Colors.white60 : primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName ?? 'Unknown',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white70 : primary,
            ),
          ),
          Text(
            message.replyToText ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white60 : AppColors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
