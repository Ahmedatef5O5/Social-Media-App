import 'package:flutter/cupertino.dart';
import 'package:social_media_app/features/group_chat/widgets/group_reply_preview_bar_widget.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';

class GroupReplyPreviewSection extends StatelessWidget {
  final GroupDetailsCubit cubit;

  const GroupReplyPreviewSection({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GroupMessageModel?>(
      valueListenable: cubit.replyToMessage,
      builder: (_, reply, __) {
        if (reply == null) return const SizedBox();

        return GroupReplyPreviewBar(
          reply: reply,
          onDismiss: () => cubit.replyToMessage.value = null,
        );
      },
    );
  }
}
