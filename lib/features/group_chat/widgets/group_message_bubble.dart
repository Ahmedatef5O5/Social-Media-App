import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/features/group_chat/helpers/swipe_to_reply_wrapper.dart';
import 'package:social_media_app/features/group_chat/widgets/group_message_content.dart';
import '../models/groupe_message_model.dart';

class GroupMessageBubble extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Function(GroupMessageModel) onReply;
  final ItemScrollController itemScrollController;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isCall = message.messageType == 'call';

    return SwipeToReplyWrapper(
      enabled: !isCall,
      isMe: isMe,
      onReply: () => onReply(message),
      child: GroupMessageContent(
        message: message,
        isMe: isMe,
        onReply: onReply,

        itemScrollController: itemScrollController,
      ),
    );
  }
}
