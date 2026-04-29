import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chat/widgets/date_separator_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/formatted_date.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../helpers/group_chat_input_section.dart';
import '../models/group_call_model.dart';
import '../models/groupe_message_model.dart';
import 'group_message_bubble.dart';
import 'group_typing_indicator_widget.dart';

class GroupMessageItemBuilder extends StatelessWidget {
  final int index;
  final List<GroupMessageModel> messages;
  final List<String> typing;

  const GroupMessageItemBuilder({
    super.key,
    required this.index,
    required this.messages,
    required this.typing,
  });

  @override
  Widget build(BuildContext context) {
    if (typing.isNotEmpty && index == 0) {
      return GroupTypingIndicator(typingUserIds: typing);
    }

    final msgIndex = typing.isNotEmpty ? index - 1 : index;

    if (msgIndex < 0 || msgIndex >= messages.length) {
      return const SizedBox();
    }

    final msg = messages[msgIndex];

    final isMe = msg.senderId == Supabase.instance.client.auth.currentUser!.id;

    final showDate = GroupChatHelpers.shouldShowDate(messages, msgIndex);

    if (msg.messageType == 'group_call') {
      return StreamBuilder<GroupCallModel?>(
        stream: Supabase.instance.client
            .from('group_calls')
            .stream(primaryKey: ['call_id'])
            .eq('call_id', msg.text)
            .map(
              (list) =>
                  list.isNotEmpty ? GroupCallModel.fromMap(list.first) : null,
            ),
        builder: (context, snapshot) {
          final call = snapshot.data;
          if (call == null) return const SizedBox.shrink();

          final isMissed = call.status == GroupCallStatus.missed;
          final isRinging = call.status == GroupCallStatus.ringing;
          final isOngoing =
              call.status == GroupCallStatus.accepted ||
              call.status == GroupCallStatus.ongoing;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isMissed
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  call.type == GroupCallType.video
                      ? Icons.videocam
                      : Icons.phone,
                  color: isMissed ? Colors.red : Colors.green,
                ),
                const Gap(8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.type == GroupCallType.video
                          ? 'Group Video Call'
                          : 'Group Voice Call',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isMissed
                          ? 'Missed Call'
                          : isRinging
                          ? 'Ringing...'
                          : isOngoing
                          ? 'Ongoing • Tap to Join'
                          : (call.duration != null && call.duration!.isNotEmpty)
                          ? 'Ended • ${call.duration}'
                          : 'Ended',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
    return Column(
      key: ValueKey(msg.id),
      children: [
        if (showDate)
          DateSeparator(date: FormattedDate.getChatTime(msg.createdAt)),

        GroupMessageBubble(
          message: msg,
          isMe: isMe,
          onReply: (m) {
            context.read<GroupDetailsCubit>().replyToMessage.value = m;
          },
        ),
      ],
    );
  }
}
