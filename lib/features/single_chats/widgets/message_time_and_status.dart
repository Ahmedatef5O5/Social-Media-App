import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';

class MessageTimeAndStatus extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Color? iconColor;

  const MessageTimeAndStatus({
    super.key,
    required this.message,
    required this.isMe,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        Text(
          FormattedDate.getMessageTime(message.createdAt),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color:
                isMe
                    ? AppColors.white70
                    : Theme.of(context).colorScheme.onSurface,
            fontSize: 9,
          ),
        ),
        if (isMe) ...[
          const Gap(2),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 12,
            color: message.isRead ? Colors.green.shade200 : iconColor,
          ),
        ],
      ],
    );
  }
}
