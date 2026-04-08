import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:social_media_app/features/chats/widgets/message_content_container_widget.dart';
import 'package:social_media_app/features/chats/widgets/user_chat_avatar_widget.dart';

class ChatBubble extends StatefulWidget {
  final bool isMe;
  final MessageModel message;
  final ValueChanged<MessageModel>? onReply;
  final String? userImgUrl;
  final double? uploadProgress;
  final bool isHighlighted;
  final ItemScrollController itemScrollController;

  const ChatBubble({
    super.key,
    required this.message,
    this.onReply,
    required this.isMe,
    this.userImgUrl,
    this.uploadProgress,
    this.isHighlighted = false,
    required this.itemScrollController,
  });

  @override
  State<ChatBubble> createState() => ChatBubbleState();
}

class ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _triggered = false;
  final ValueNotifier<String?> highlightedMessageId = ValueNotifier(null);

  void _showReactionAndDeleteMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                        final isSelected = widget.message.reaction == emoji;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            context.read<ChatDetailsCubit>().addReaction(
                              messageId: widget.message.id,
                              reaction: emoji,
                              currentReaction: widget.message.reaction,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.25)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 1.5,
                                      )
                                      : null,
                            ),
                            child: Text(
                              emoji,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium!.copyWith(fontSize: 28),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.reply_all_outlined),
                  title: const Text('Replay'),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onReply?.call(widget.message);
                  },
                ),
                if (widget.isMe)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(
                      'Delete message',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium!.copyWith(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      final String actualReceiverId =
                          widget.isMe
                              ? widget.message.receiverId
                              : widget.message.senderId;
                      context.read<ChatDetailsCubit>().deleteMessage(
                        messageId: widget.message.id,
                        receiverId: actualReceiverId,
                      );
                    },
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatDetailsCubit>();

    return ValueListenableBuilder<String?>(
      valueListenable: cubit.highlightedMessageId,
      builder: (BuildContext context, value, Widget? child) {
        final bool isHighlighted = value == widget.message.id;
        final highlightColor = Theme.of(
          context,
        ).primaryColor.withValues(alpha: widget.isMe ? 0.12 : 0.2);

        return GestureDetector(
          onLongPress: () => _showReactionAndDeleteMenu(context),

          onHorizontalDragUpdate: (details) {
            if (widget.isMe && details.delta.dx < 0) {
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dx).clamp(
                  -60.0,
                  0.0,
                );
              });
            } else if (!widget.isMe && details.delta.dx > 0) {
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, 60.0);
              });
            }
            if (!_triggered && _dragOffset.abs() >= 50) {
              _triggered = true;
              HapticFeedback.lightImpact();
              widget.onReply?.call(widget.message);
            }
          },
          onHorizontalDragEnd: (_) {
            setState(() {
              _dragOffset = 0;
              _triggered = false;
            });
          },

          child: Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                UserChatAvatar(userImgUrl: widget.userImgUrl),
                const Gap(8),
              ],

              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  transform: Matrix4.translationValues(_dragOffset, 0, 0),
                  decoration: BoxDecoration(
                    color: isHighlighted ? highlightColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        widget.isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MessageContentContainer(
                        message: widget.message,
                        isMe: widget.isMe,
                        uploadProgress: widget.uploadProgress,
                        itemScrollController: widget.itemScrollController,
                      ),

                      if (_dragOffset.abs() > 10)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4),
                          child: Icon(
                            Icons.reply,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
