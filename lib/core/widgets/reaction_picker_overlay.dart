import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<Map<String, String>> kChatReactions = [
  {'emoji': '👍', 'label': 'Like'},
  {'emoji': '❤️', 'label': 'Love'},
  {'emoji': '😂', 'label': 'Haha'},
  {'emoji': '😮', 'label': 'Wow'},
  {'emoji': '😢', 'label': 'Sad'},
  {'emoji': '😡', 'label': 'Angry'},
];

class ChatReactionOverlay {
  static OverlayEntry create({
    required BuildContext context,
    required GlobalKey anchorKey,
    required void Function(String emoji) onSelect,
    required VoidCallback onDismiss,
    String? selectedEmoji,
    required bool isMe,
  }) {
    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) throw StateError('anchorKey has no render object');

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchorRect = offset & renderBox.size;

    const bubbleWidth = 260.0;
    final screenWidth = overlayBox.size.width;

    double x =
        isMe
            ? (anchorRect.right - bubbleWidth).clamp(
              8.0,
              screenWidth - bubbleWidth - 8,
            )
            : anchorRect.left.clamp(8.0, screenWidth - bubbleWidth - 8);

    final y = anchorRect.bottom + 6;

    return OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              // Dismiss tap area
              Positioned.fill(
                child: GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: x,
                top: y,
                child: _ReactionPickerBubble(
                  onSelect: onSelect,
                  onDismiss: onDismiss,
                  selectedEmoji: selectedEmoji,
                ),
              ),
            ],
          ),
    );
  }
}

class _ReactionPickerBubble extends StatefulWidget {
  final void Function(String) onSelect;
  final VoidCallback onDismiss;
  final String? selectedEmoji;
  const _ReactionPickerBubble({
    required this.onSelect,
    required this.onDismiss,
    this.selectedEmoji,
  });

  @override
  State<_ReactionPickerBubble> createState() => _ReactionPickerBubbleState();
}

class _ReactionPickerBubbleState extends State<_ReactionPickerBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  int? _hovered;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scale,
      alignment: Alignment.topCenter,
      child: PhysicalModel(
        color: Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.88 : 0.78,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.4 : 0.2),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.20),
                blurRadius: isDark ? 16 : 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(kChatReactions.length, (i) {
                final r = kChatReactions[i];
                final isHov = _hovered == i;
                final isSelected = widget.selectedEmoji == r['emoji'];
                return MouseRegion(
                  onEnter: (_) => setState(() => _hovered = i),
                  onExit: (_) => setState(() => _hovered = null),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSelect(r['emoji']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.all(6),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),

                        color:
                            isSelected
                                ? scheme.primary.withValues(alpha: 0.15)
                                : Colors.transparent,

                        border:
                            isSelected
                                ? Border.all(
                                  color: scheme.primary.withValues(alpha: 0.4),
                                  width: 1,
                                )
                                : null,
                      ),
                      transform:
                          isSelected
                              ? (Matrix4.identity()..scale(1.15))
                              : isHov
                              ? (Matrix4.identity()
                                ..translate(0.0, -8.0)
                                ..scale(1.35))
                              : Matrix4.identity(),
                      child: Tooltip(
                        message: r['label']!,
                        preferBelow: false,
                        decoration: BoxDecoration(
                          color: scheme.inverseSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 12,
                        ),
                        child: Text(
                          r['emoji']!,
                          style: TextStyle(
                            fontSize: 26,
                            shadows:
                                isSelected
                                    ? [
                                      Shadow(
                                        color: scheme.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                    : [],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
