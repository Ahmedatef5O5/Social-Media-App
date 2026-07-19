import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCallActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;

  final bool emphasized;

  const GlassCallActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 76,
    this.emphasized = false,
  });

  @override
  State<GlassCallActionButton> createState() => _GlassCallActionButtonState();
}

class _GlassCallActionButtonState extends State<GlassCallActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _emphasisController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _emphasisController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.emphasized) _emphasisController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emphasisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelSize = (widget.size * 0.17).clamp(11.0, 14.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _emphasisController,
            builder: (context, child) {
              final emphasisScale =
                  widget.emphasized
                      ? 1.0 + (_emphasisController.value * 0.06)
                      : 1.0;
              final pressScale = _pressed ? 0.92 : 1.0;
              return Transform.scale(
                scale: emphasisScale * pressScale,
                child: child,
              );
            },
            child: _buildGlassCircle(),
          ),
          const SizedBox(height: 12),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircle() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: widget.color.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.95),
                  widget.color.withValues(alpha: 0.75),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}
