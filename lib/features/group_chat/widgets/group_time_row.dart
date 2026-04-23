import 'package:flutter/material.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../models/groupe_message_model.dart';

class GroupTimeRow extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  const GroupTimeRow({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) => Text(
    FormattedDate.getMessageTime(message.createdAt),
    style: TextStyle(
      fontSize: 10,
      color: isMe ? Colors.white60 : AppColors.black38,
    ),
  );
}
