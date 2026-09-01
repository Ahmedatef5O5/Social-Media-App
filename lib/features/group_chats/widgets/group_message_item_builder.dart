import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/messaging/message_reconciler.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../single_chats/helpers/chat_date_separator_helper.dart';
import '../../single_chats/widgets/date_separator_glassmorphism_widget.dart';
import '../../group_calls/models/group_call_model.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../helpers/group_system_event_text_builder.dart';
import '../models/groupe_message_model.dart';
import 'group_message_bubble.dart';
import 'group_system_event_separator.dart';

class GroupMessageItemBuilder extends StatelessWidget {
  final int index;
  final List<GroupMessageModel> messages;
  final ItemScrollController itemScrollController;
  final bool isMember;

  const GroupMessageItemBuilder({
    super.key,
    required this.index,
    required this.messages,
    required this.itemScrollController,
    required this.isMember,
  });

  @override
  Widget build(BuildContext context) {
    final msgIndex = index;

    if (msgIndex < 0 || msgIndex >= messages.length) {
      return const SizedBox();
    }

    final msg = messages[msgIndex];
    final stableKey = correlationKeyFor(
      id: msg.id,
      clientMessageId: msg.clientMessageId,
    );

    final isMe = msg.senderId == SupabaseProvider.id;

    final showDate = ChatDateSeparatorHelper.shouldShowDate<GroupMessageModel>(
      messages: messages,
      index: msgIndex,
      getCreatedAt: (m) => m.createdAt,
    );

    if (msg.isSystemEvent) {
      return Column(
        key: ValueKey(stableKey),
        children: [
          if (showDate)
            DateSeparatorGlassmorphismWidget(
              date: FormattedDate.getChatTime(msg.createdAt),
            ),
          GroupSystemEventSeparator(
            text: GroupSystemEventTextBuilder.build(
              message: msg,
              currentUserId: SupabaseProvider.id,
            ),
          ),
        ],
      );
    }

    if (msg.messageType == 'group_call') {
      return StreamBuilder<GroupCallModel?>(
        stream: SupabaseProvider.client
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

    final belowMsg = msgIndex > 0 ? messages[msgIndex - 1] : null;
    final isBrokenBySpecialNeighbor =
        belowMsg != null &&
        (belowMsg.isSystemEvent || belowMsg.messageType == 'group_call');

    final showAvatar =
        isBrokenBySpecialNeighbor ||
        ChatDateSeparatorHelper.isLastInSenderCluster<GroupMessageModel>(
          messages: messages,
          index: msgIndex,
          getSenderId: (m) => m.senderId,
          getCreatedAt: (m) => m.createdAt,
        );

    return Column(
      key: ValueKey(stableKey),
      children: [
        if (showDate)
          DateSeparatorGlassmorphismWidget(
            date: FormattedDate.getChatTime(msg.createdAt),
          ),

        GroupMessageBubble(
          message: msg,
          isMe: isMe,
          isMember: isMember,
          onReply: (m) {
            final cubit = context.read<GroupDetailsCubit>();
            cubit.editingMessage.value = null;
            cubit.replyToMessage.value = m;
          },
          onEdit: (m) {
            final cubit = context.read<GroupDetailsCubit>();
            cubit.replyToMessage.value = null;
            cubit.editingMessage.value = m;
          },
          itemScrollController: itemScrollController,
          showAvatar: showAvatar,
        ),
      ],
    );
  }
}
