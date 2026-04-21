import 'package:flutter/material.dart';
import 'package:social_media_app/features/group_chat/widgets/group_message_content.dart';
import '../models/groupe_message_model.dart';

class GroupMessageBubble extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Function(GroupMessageModel) onReply;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return GroupMessageContent(message: message, isMe: isMe, onReply: onReply);
  }
}
