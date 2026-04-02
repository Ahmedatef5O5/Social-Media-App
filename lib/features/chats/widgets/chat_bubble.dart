import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:social_media_app/features/chats/widgets/message_content_container_widget.dart';
import 'package:social_media_app/features/chats/widgets/user_chat_avatar_widget.dart';
import '../../../core/themes/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? userImgUrl;
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.userImgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showReactionAndDeleteMenu(context),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[UserChatAvatar(userImgUrl: userImgUrl), const Gap(8)],
          MessageContentContainer(message: message, isMe: isMe),
        ],
      ),
    );
  }

  void _showReactionAndDeleteMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              // color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
                        final isSelected = message.reaction == emoji;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            context.read<ChatDetailsCubit>().addReaction(
                              messageId: message.id,
                              reaction: emoji,
                              currentReaction: message.reaction,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primaryColor.withValues(
                                        alpha: 0.15,
                                      )
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: AppColors.primaryColor,
                                        width: 1.5,
                                      )
                                      : null,
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),

                          //  Text(
                          //   emoji,
                          //   style: const TextStyle(fontSize: 28),
                          // ),
                        );
                      }).toList(),
                ),
                const Divider(),
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete message'),
                    onTap: () {
                      Navigator.pop(ctx);
                      final String actualReceiverId =
                          isMe ? message.receiverId : message.senderId;
                      context.read<ChatDetailsCubit>().deleteMessage(
                        messageId: message.id,
                        receiverId: actualReceiverId,
                      );
                    },
                  ),
              ],
            ),
          ),
    );
  }
}
