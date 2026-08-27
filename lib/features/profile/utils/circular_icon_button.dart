import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class CircularIconButton extends StatefulWidget {
  final ThemeData theme;
  final IconData? icon;
  final String? assetPath;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  const CircularIconButton({
    super.key,
    required this.theme,
    this.icon,
    this.assetPath,
    required this.onPressed,
    required this.size,
    this.tooltip,
  });

  @override
  State<CircularIconButton> createState() => _CircularIconButtonState();
}

class _CircularIconButtonState extends State<CircularIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : theme.primaryColor;
    final Color bgColor = isDark
        ? theme.colorScheme.surface
        : theme.scaffoldBackgroundColor.withValues(alpha: 0.99);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.grey3;

    return AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: bgColor,
        shape: CircleBorder(
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        elevation: 1.1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child:
                  widget.assetPath != null
                      ? Image.asset(
                        widget.assetPath!,
                        width: widget.size * 0.43,
                        height: widget.size * 0.43,
                        color: iconColor,
                      )
                      : Icon(
                        widget.icon,
                        color: iconColor,
                        size: widget.size * 0.43,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
