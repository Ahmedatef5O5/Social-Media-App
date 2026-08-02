import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/features/group_chats/helpers/swipe_to_reply_wrapper.dart';
import 'package:social_media_app/features/group_chats/widgets/group_message_content.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';

class GroupMessageBubble extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final bool isMember;
  final Function(GroupMessageModel) onReply;
  final Function(GroupMessageModel)? onEdit;
  final ItemScrollController itemScrollController;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isMember,
    required this.onReply,
    this.onEdit,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isCall = message.messageType == 'call';
    final cubit = context.read<GroupDetailsCubit>();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: cubit.selectedMessageIds,
      builder: (context, selectedIds, _) {
        final isSelectionMode = selectedIds.isNotEmpty;

        return SwipeToReplyWrapper(
          enabled: !isCall && !isSelectionMode && isMember,
          isMe: isMe,
          onReply: () => onReply(message),
          child: GroupMessageContent(
            message: message,
            isMe: isMe,
            isMember: isMember,
            onReply: onReply,
            onEdit: onEdit,
            itemScrollController: itemScrollController,
          ),
        );
      },
    );
  }
}
