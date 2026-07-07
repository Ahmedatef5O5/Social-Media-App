import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/reaction_picker_overlay.dart';
import 'package:social_media_app/features/single_chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';
import 'package:social_media_app/features/single_chats/widgets/message_content_container_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/user_chat_avatar_widget.dart';

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

  OverlayEntry? _overlayEntry;
  final GlobalKey _bubbleKey = GlobalKey();

  @override
  void dispose() {
    _dismissPicker(isDisposing: true);
    super.dispose();
  }

  void _showPicker() {
    if (_overlayEntry != null) return;
    final isCall = widget.message.messageType == 'call';
    if (isCall) return;

    try {
      _overlayEntry = ChatReactionOverlay.create(
        context: context,
        anchorKey: _bubbleKey,
        isMe: widget.isMe,
        onSelect: (emoji) {
          _dismissPicker();
          _applyReaction(emoji);
        },
        onDismiss: _dismissPicker,
        selectedEmoji: currentUserReactionEmoji,
      );
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {});
    } catch (_) {}
  }

  void _dismissPicker({bool isDisposing = false}) {
    if (_overlayEntry == null) return;
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (!isDisposing && mounted) {
      setState(() {});
    }
  }

  void _applyReaction(String emoji) {
    HapticFeedback.selectionClick();
    final receiverId =
        widget.isMe ? widget.message.receiverId : widget.message.senderId;

    context.read<ChatDetailsCubit>().toggleReaction(
      messageId: widget.message.id,
      receiverId: receiverId,
      emoji: emoji,
    );
  }

  String? get currentUserReactionEmoji {
    final currentUserId = context.read<ChatDetailsCubit>().currentUserId;
    return widget.message.reactions[currentUserId];
  }

  void _handleLongPress(ChatDetailsCubit cubit) {
    final isCall = widget.message.messageType == 'call';
    final alreadySelecting = cubit.isInSelectionMode;
    HapticFeedback.mediumImpact();

    if (!alreadySelecting) {
      if (!isCall) _showPicker();
      cubit.startSelection(widget.message.id);
    } else {
      cubit.toggleMessageSelection(widget.message.id);
    }
  }

  void _handleTap(ChatDetailsCubit cubit) {
    cubit.toggleMessageSelection(widget.message.id);
  }

  void _showDeleteMenu(BuildContext context) {
    final isCall = widget.message.messageType == 'call';

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
                if (!isCall)
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
                      final receiverId =
                          widget.isMe
                              ? widget.message.receiverId
                              : widget.message.senderId;
                      context.read<ChatDetailsCubit>().deleteMessage(
                        messageId: widget.message.id,
                        receiverId: receiverId,
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
    final isCall = widget.message.messageType == 'call';

    return ValueListenableBuilder<Set<String>>(
      valueListenable: cubit.selectedMessageIds,
      builder: (context, selectedIds, _) {
        final isSelectionMode = selectedIds.isNotEmpty;
        final isSelected = selectedIds.contains(widget.message.id);

        return ValueListenableBuilder<String?>(
          valueListenable: cubit.highlightedMessageId,
          builder: (context, highlightId, _) {
            final isHighlighted = highlightId == widget.message.id;
            final highlightColor = Theme.of(
              context,
            ).primaryColor.withValues(alpha: widget.isMe ? 0.12 : 0.2);
            final selectionColor = Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.16);

            return GestureDetector(
              onTap: isSelectionMode ? () => _handleTap(cubit) : null,
              onLongPress: isCall ? null : () => _handleLongPress(cubit),
              onDoubleTap:
                  isSelectionMode ? null : () => _showDeleteMenu(context),

              onHorizontalDragUpdate:
                  (isCall || isSelectionMode)
                      ? null
                      : (details) {
                        if (widget.isMe && details.delta.dx < 0) {
                          setState(() {
                            _dragOffset = (_dragOffset + details.delta.dx)
                                .clamp(-60.0, 0.0);
                          });
                        } else if (!widget.isMe && details.delta.dx > 0) {
                          setState(() {
                            _dragOffset = (_dragOffset + details.delta.dx)
                                .clamp(0.0, 60.0);
                          });
                        }
                        if (!_triggered && _dragOffset.abs() >= 50) {
                          _triggered = true;
                          HapticFeedback.lightImpact();
                          widget.onReply?.call(widget.message);
                        }
                      },
              onHorizontalDragEnd:
                  (isCall || isSelectionMode)
                      ? null
                      : (_) => setState(() {
                        _dragOffset = 0;
                        _triggered = false;
                      }),

              child: Container(
                color: isSelected ? selectionColor : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment:
                      widget.isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child:
                          isSelectionMode
                              ? Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 22,
                                  color:
                                      isSelected
                                          ? Theme.of(context).primaryColor
                                          : AppColors.grey6,
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),

                    if (!widget.isMe) ...[
                      UserChatAvatar(userImgUrl: widget.userImgUrl),
                      const Gap(8),
                    ],

                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        transform: Matrix4.translationValues(_dragOffset, 0, 0),
                        decoration: BoxDecoration(
                          color:
                              isHighlighted
                                  ? highlightColor
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              widget.isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AbsorbPointer(
                              absorbing: isSelectionMode,
                              child: KeyedSubtree(
                                key: _bubbleKey,
                                child: MessageContentContainer(
                                  message: widget.message,
                                  isMe: widget.isMe,
                                  uploadProgress: widget.uploadProgress,
                                  itemScrollController:
                                      widget.itemScrollController,
                                ),
                              ),
                            ),

                            if (_dragOffset.abs() > 10)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                ),
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
              ),
            );
          },
        );
      },
    );
  }
}
