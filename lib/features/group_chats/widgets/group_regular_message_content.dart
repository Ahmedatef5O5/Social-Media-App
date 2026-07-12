import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../single_chats/widgets/image_message_widget.dart';
import '../../single_chats/widgets/video_message_widget.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';
import 'group_message_reply_preview.dart';
import 'group_time_row.dart';
import 'group_voice_message_bubble.dart';

class GroupRegularMessageContent extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final bool isUploading;
  final Color textColor;
  final Color primary;
  final ItemScrollController itemScrollController;

  const GroupRegularMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.isUploading,
    required this.textColor,
    required this.primary,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = message.messageType == 'image';
    final isVideo = message.messageType == 'video';
    final isVoice = message.messageType == 'voice';

    final currentUserId = SupabaseProvider.id;
    final displayText = message.caption ?? message.text;
    final timeWidget = GroupTimeRow(message: message, isMe: isMe);

    final hasReactions = message.reactions.isNotEmpty;
    double minBubbleWidth = 0;
    if (hasReactions) {
      final uniqueEmojis = message.reactions.values.toSet().length;
      minBubbleWidth = (uniqueEmojis * 36.0) + 24.0;
      final maxWidth = MediaQuery.of(context).size.width * 0.75;
      minBubbleWidth = minBubbleWidth.clamp(0.0, maxWidth);
    }

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(minWidth: minBubbleWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyToMessageId != null)
              GestureDetector(
                onTap: () {
                  final cubit = context.read<GroupDetailsCubit>();
                  if (itemScrollController.isAttached) {
                    cubit.scrollToMessage(
                      messageId: message.replyToMessageId!,
                      itemScrollController: itemScrollController,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GroupReplyBubblePreview(
                    message: message,
                    isMe: isMe,
                    currentUserId: currentUserId,
                  ),
                ),
              ),

            if (!isMe)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 4,
                  left: isVideo || isImage ? 6 : 0,
                ),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

            if (isImage)
              SizedBox(
                width: 305,
                height: 320,
                child:
                    message.imageUrl != null
                        ? ImageMessageWidget(
                          imageUrl: message.imageUrl!,
                          caption: message.caption,
                          isMe: isMe,
                        )
                        : const SizedBox.shrink(),
              ),

            if (isVideo)
              SizedBox(
                height: 200,
                width: 280,
                child:
                    message.videoUrl != null
                        ? VideoMessageWidget(
                          videoUrl: message.videoUrl!,
                          caption: message.caption,
                          isMe: isMe,
                        )
                        : const SizedBox.shrink(),
              ),

            if (isVoice)
              GroupVoiceMessageBubbleWidget(
                voiceUrl: message.voiceUrl ?? '',
                isMe: isMe,
                timestamp: message.createdAt,
                isUploading: isUploading,
              ),

            if (displayText.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: (isImage || isVideo) ? 8 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    Align(alignment: Alignment.bottomRight, child: timeWidget),
                  ],
                ),
              ),

            if (displayText.isEmpty && (isImage || isVideo))
              Align(alignment: Alignment.bottomRight, child: timeWidget),
          ],
        ),
      ),
    );
  }
}
