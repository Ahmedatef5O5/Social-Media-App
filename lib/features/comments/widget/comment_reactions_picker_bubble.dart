import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<Map<String, String>> kReactionsList = [
  {'emoji': '👍', 'label': 'Like'},
  {'emoji': '❤️', 'label': 'Love'},
  {'emoji': '😂', 'label': 'Haha'},
  {'emoji': '😮', 'label': 'Wow'},
  {'emoji': '😢', 'label': 'Sad'},
  {'emoji': '😡', 'label': 'Angry'},
];

class ReactionsPickerBubble extends StatefulWidget {
  final void Function(String emoji) onReactionSelected;
  final VoidCallback onDismiss;
  final String? selectedEmoji;

  const ReactionsPickerBubble({
    super.key,
    required this.onReactionSelected,
    required this.onDismiss,
    this.selectedEmoji,
  });

  @override
  State<ReactionsPickerBubble> createState() => _ReactionsPickerBubbleState();
}

class _ReactionsPickerBubbleState extends State<ReactionsPickerBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
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
      scale: _scaleAnim,
      child: PhysicalModel(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.85 : 0.75,
            ),
            // color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.25),
                blurRadius: isDark ? 14 : 10,
                spreadRadius: 1,
                offset: const Offset(2, 2),
              ),
            ],
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.4 : 0.25),
              width: 0.5,
            ),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(kReactionsList.length, (i) {
                final r = kReactionsList[i];
                final isHovered = _hoveredIndex == i;
                final isSelected = widget.selectedEmoji == r['emoji'];
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = i),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onReactionSelected(r['emoji']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.all(6), //
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
                          isHovered
                              ? (Matrix4.identity()
                                ..translate(0.0, -8.0)
                                ..scale(1.35))
                              : Matrix4.identity(),
                      child: Tooltip(
                        message: r['label']!,
                        decoration: BoxDecoration(
                          color: scheme.inverseSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 12,
                        ),
                        preferBelow: false,

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
