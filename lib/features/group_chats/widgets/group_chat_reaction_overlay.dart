import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/group_chats/widgets/group_reaction_picker_bubble.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';

class GroupChatReactionOverlay {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required GroupMessageModel message,
    required Function(GroupMessageModel) onReply,
    Function(GroupMessageModel)? onEdit,
    required Color primary,
    required bool isMe,
  }) {
    dismiss();

    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchorRect = offset & renderBox.size;

    const bubbleWidth = 340.0;
    final screenWidth = overlayBox.size.width;
    final currentUserId =
        anchorKey.currentContext != null
            ? context.read<GroupDetailsCubit>().currentUserId
            : '';

    double x =
        isMe
            ? (anchorRect.right - bubbleWidth).clamp(
              8.0,
              screenWidth - bubbleWidth - 8,
            )
            : anchorRect.left.clamp(8.0, screenWidth - bubbleWidth - 8);

    final double spaceBelow = overlayBox.size.height - anchorRect.bottom;
    final double y =
        spaceBelow > 120 ? anchorRect.bottom + 6 : anchorRect.top - 130;

    final cubit = context.read<GroupDetailsCubit>();

    _currentEntry = OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: dismiss,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: x,
                top: y,
                child: GroupReactionPickerBubble(
                  message: message,
                  currentUserId: currentUserId,
                  primary: primary,
                  isMe: isMe,
                  onReact: (emoji) {
                    dismiss();
                    cubit.toggleReaction(messageId: message.id, emoji: emoji);
                  },
                  onReply: () {
                    dismiss();
                    onReply(message);
                  },
                  onEdit:
                      onEdit != null
                          ? () {
                            dismiss();
                            onEdit(message);
                          }
                          : null,
                  onDelete:
                      message.senderId == currentUserId
                          ? () {
                            dismiss();
                            cubit.deleteMessage(message.id);
                          }
                          : null,
                ),
              ),
            ],
          ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
