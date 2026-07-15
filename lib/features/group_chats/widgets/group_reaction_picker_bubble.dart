import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/groupe_message_model.dart';

class GroupReactionPickerBubble extends StatefulWidget {
  final GroupMessageModel message;
  final String currentUserId;
  final Color primary;
  final bool isMe;
  final void Function(String) onReact;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GroupReactionPickerBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.primary,
    required this.isMe,
    required this.onReact,
    required this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<GroupReactionPickerBubble> createState() =>
      _GroupReactionPickerBubbleState();
}

class _GroupReactionPickerBubbleState extends State<GroupReactionPickerBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

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
    final myReaction = widget.message.reactions[widget.currentUserId];
    final isCall = widget.message.messageType == 'call';

    return ScaleTransition(
      scale: _scale,
      alignment: Alignment.topCenter,
      child: PhysicalModel(
        color: Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: bubbleWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.88 : 0.78,
            ),
            borderRadius: BorderRadius.circular(16),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCall) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        _emojis.map((emoji) {
                          final isSelected = myReaction == emoji;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onReact(emoji);
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
                                          color: scheme.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 1,
                                        )
                                        : null,
                              ),
                              transform:
                                  isSelected
                                      ? (Matrix4.identity()..scale(1.15))
                                      : Matrix4.identity(),
                              child: Text(
                                emoji,
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
                          );
                        }).toList(),
                  ),
                  Divider(
                    height: 16,
                    color: scheme.outline.withValues(alpha: 0.2),
                  ),
                  _ActionTile(
                    icon: Icons.reply_all_outlined,
                    label: 'Reply',
                    onTap: widget.onReply,
                  ),
                ],
                if (widget.onEdit != null)
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: widget.onEdit!,
                  ),
                if (widget.onDelete != null)
                  _ActionTile(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: widget.onDelete!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double bubbleWidth = 340.0;
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: c, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
