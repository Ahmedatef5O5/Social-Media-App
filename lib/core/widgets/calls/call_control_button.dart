import 'package:flutter/material.dart';

enum CallControlVariant { neutral, warning, dangerSolid }

class CallControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final CallControlVariant variant;
  final VoidCallback onTap;
  final double size;

  final bool emphasized;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.variant = CallControlVariant.neutral,
    this.size = 76,
    this.emphasized = false,
  });

  @override
  State<CallControlButton> createState() => _CallControlButtonState();
}

class _CallControlButtonState extends State<CallControlButton>
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
  void didUpdateWidget(covariant CallControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emphasized == oldWidget.emphasized) return;
    if (widget.emphasized) {
      _emphasisController.repeat(reverse: true);
    } else {
      _emphasisController
        ..stop()
        ..value = 0;
    }
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
            child: _buildCircle(),
          ),
          const SizedBox(height: 12),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle() {
    final Color fill;
    final double borderAlpha;
    switch (widget.variant) {
      case CallControlVariant.neutral:
        fill = const Color(0xFF2B303C);
        borderAlpha = 0.18;
        break;
      case CallControlVariant.warning:
        fill = const Color(0xFFD92D20);
        borderAlpha = 0.22;
        break;
      case CallControlVariant.dangerSolid:
        fill = const Color(0xFFDC2626);
        borderAlpha = 0.22;
        break;
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(
          color: Colors.white.withValues(alpha: borderAlpha),
          width: 1.2,
        ),
      ),
      child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.42),
    );
  }
}
