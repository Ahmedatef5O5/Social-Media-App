import 'package:flutter/material.dart';
import 'comment_reactions_picker_bubble.dart';

class PickerPosition {
  final double x;
  final double y;

  const PickerPosition({required this.x, required this.y});
}

class CommentOverlayPicker {
  static OverlayEntry create({
    required BuildContext context,
    required Rect anchorRect,
    required void Function(String emoji) onSelect,
    required VoidCallback onDismiss,
    double bubbleWidth = 220,
    double offsetRight = 80,
  }) {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final offset = anchorRect.topLeft;
    final size = anchorRect.size;

    double x = offset.dx + (size.width / 2) - (bubbleWidth / 2);
    x += offsetRight;

    double y = offset.dy + size.height + 8;

    x = x.clamp(12.0, overlayBox.size.width - bubbleWidth - 12);

    return OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              Positioned.fill(child: GestureDetector(onTap: onDismiss)),
              Positioned(
                left: x,
                top: y,
                child: ReactionsPickerBubble(
                  onReactionSelected: onSelect,
                  onDismiss: onDismiss,
                ),
              ),
            ],
          ),
    );
  }
}
