import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:social_media_app/features/comments/helpers/comment_menu_action.dart';
import 'comment_action_menu.dart';
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
    String? selectedEmoji,
    List<CommentMenuAction> actions = const [],
    double bubbleWidth = ReactionsPickerBubble.kBubbleWidth,
    double offsetRight = 0,
  }) {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final mediaQuery = MediaQuery.of(context);

    const double horizontalMargin = 12.0;
    const double verticalGap = 8.0;
    const double bottomInputBarReserve = 68.0;

    final double screenHeight = overlayBox.size.height;

    final double actionsHeight =
        actions.isEmpty ? 0.0 : (8.0 + (actions.length * 46.0));
    final double estimatedTotalHeight =
        ReactionsPickerBubble.kBubbleHeight + actionsHeight;

    final double bottomSafeLimit =
        screenHeight -
        mediaQuery.viewInsets.bottom -
        mediaQuery.padding.bottom -
        bottomInputBarReserve;
    final double topSafeLimit = mediaQuery.padding.top + 12.0;

    final double spaceBelow = bottomSafeLimit - anchorRect.bottom;
    final bool showAbove =
        spaceBelow < (estimatedTotalHeight + verticalGap) &&
        (anchorRect.top - topSafeLimit) > spaceBelow;

    double y =
        showAbove
            ? anchorRect.top - estimatedTotalHeight - verticalGap
            : anchorRect.bottom + verticalGap;

    final double maxTop = math.max(
      topSafeLimit,
      screenHeight -
          mediaQuery.viewInsets.bottom -
          estimatedTotalHeight -
          horizontalMargin,
    );
    y = y.clamp(topSafeLimit, maxTop);

    return OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onDismiss,
                  onPanDown: (_) => onDismiss(),
                ),
              ),
              Positioned(
                right: horizontalMargin,
                top: y,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ReactionsPickerBubble(
                      onReactionSelected: onSelect,
                      onDismiss: onDismiss,
                      selectedEmoji: selectedEmoji,
                      scaleAlignment:
                          showAbove
                              ? Alignment.bottomRight
                              : Alignment.topRight,
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      CommentActionMenu(actions: actions),
                    ],
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
