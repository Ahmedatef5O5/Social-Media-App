import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/group_chat/widgets/date_separator_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/helpers/formatted_date.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../helper/group_chat_input_section.dart';
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
