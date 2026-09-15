import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GlassIconButton extends StatelessWidget {
  final dynamic icon;
  final Widget? child;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color iconColor;

  const GlassIconButton({
    super.key,
    this.icon,
    this.child,
    this.onTap,
    this.size = 46,
    this.iconSize = 24,
    Color? iconColor,
  }) : assert(
         icon != null || child != null,
         'Either icon or child must be provided to GlassIconButton',
       ),
       iconColor = iconColor ?? Colors.white;

  Widget _buildIconContent() {
    if (child != null) return child!;
    final currentIcon = icon;
    if (currentIcon is Widget) {
      return currentIcon;
    }
    if (currentIcon is FaIconData) {
      return FaIcon(currentIcon, size: iconSize, color: iconColor);
    }
    if (currentIcon is IconData) {
      return Icon(currentIcon, size: iconSize, color: iconColor);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: _buildIconContent(),
          ),
        ),
      ),
    );
  }
}
