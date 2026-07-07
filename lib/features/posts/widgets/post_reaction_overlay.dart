import 'package:flutter/material.dart';
import 'post_reactions_picker_bubble.dart';

class PostReactionOverlay {
  static OverlayEntry create({
    required BuildContext context,
    required Rect anchorRect,
    required void Function(String emoji) onSelect,
    required VoidCallback onDismiss,
    String? selectedEmoji,
    double bubbleWidth = 230,
    double bubbleHeight = 52,
  }) {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final offset = anchorRect.topLeft;
    final size = anchorRect.size;

    double x = offset.dx + (size.width / 2) - (bubbleWidth / 2);
    double y = offset.dy - bubbleHeight - 8;

    x = x.clamp(12.0, overlayBox.size.width - bubbleWidth - 12);
    y = y.clamp(12.0, overlayBox.size.height - bubbleHeight - 12);

    return OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              Positioned.fill(child: GestureDetector(onTap: onDismiss)),
              Positioned(
                left: x,
                top: y,
                child: PostReactionsPickerBubble(
                  onReactionSelected: onSelect,
                  onDismiss: onDismiss,
                  selectedEmoji: selectedEmoji,
                ),
              ),
            ],
          ),
    );
  }
}
