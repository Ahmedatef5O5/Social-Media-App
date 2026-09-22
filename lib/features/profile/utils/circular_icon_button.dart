import 'package:flutter/material.dart';
import 'profile_ui_tokens.dart';

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
    this.size = ProfileUiTokens.iconButtonSize,
    this.tooltip,
  });

  @override
  State<CircularIconButton> createState() => _CircularIconButtonState();
}

class _CircularIconButtonState extends State<CircularIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);
    final Color iconColor = tokens.iconAccent;
    final double iconSize = widget.size * 0.45;

    final button = AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: tokens.surface,
        shape: CircleBorder(side: BorderSide(color: tokens.outline, width: 1)),
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
                        width: iconSize,
                        height: iconSize,
                        color: iconColor,
                      )
                      : Icon(widget.icon, color: iconColor, size: iconSize),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
