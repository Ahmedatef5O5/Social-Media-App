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
    return AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.99),
        shape: CircleBorder(
          side: BorderSide(
            color:
                theme.brightness != Brightness.light
                    ? theme.primaryColor.withValues(alpha: 0.65)
                    : AppColors.grey3,
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
                        color: theme.primaryColor,
                      )
                      : Icon(
                        widget.icon,
                        color: theme.primaryColor,
                        size: widget.size * 0.43,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
