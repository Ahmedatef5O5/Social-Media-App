import 'package:flutter/material.dart';

class PremiumSelectionCloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;

  const PremiumSelectionCloseButton({
    super.key,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.close_rounded, color: color, size: 22),
        ),
      ),
    );
  }
}

class PremiumSelectionCountLabel extends StatelessWidget {
  final int count;
  final Color color;

  const PremiumSelectionCountLabel({
    super.key,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder:
              (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
          child: Text(
            '$count',
            key: ValueKey(count),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'selected',
          style: TextStyle(
            color: color.withValues(alpha: 0.65),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

enum PremiumActionVisualState { on, off, mixed }

class PremiumSelectionActionIcon extends StatelessWidget {
  final PremiumActionVisualState state;
  final IconData onIcon;
  final IconData offIcon;
  final String onLabel;
  final String offLabel;
  final bool isDestructive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const PremiumSelectionActionIcon({
    super.key,
    required this.state,
    required this.onIcon,
    IconData? offIcon,
    required this.onLabel,
    String? offLabel,
    this.isDestructive = false,
    this.activeColor,
    required this.onTap,
  }) : offIcon = offIcon ?? onIcon,
       offLabel = offLabel ?? onLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isMixed = state == PremiumActionVisualState.mixed;
    final isOn = state == PremiumActionVisualState.on;

    final iconColor =
        isDestructive
            ? Colors.red
            : (isMixed
                ? Theme.of(context).disabledColor
                : (activeColor ?? primary));

    return Material(
      color:
          isDestructive
              ? Colors.red.withValues(alpha: 0.10)
              : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: isMixed ? 'Mixed selection' : (isOn ? onLabel : offLabel),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(isOn ? onIcon : offIcon, color: iconColor, size: 21),
          ),
        ),
      ),
    );
  }
}
