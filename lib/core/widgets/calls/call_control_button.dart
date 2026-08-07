import 'dart:ui';
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
            child: _buildCircle(context),
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

  Widget _buildCircle(BuildContext context) {
    switch (widget.variant) {
      case CallControlVariant.dangerSolid:
        return _buildSolidCircle();
      case CallControlVariant.neutral:
        return _buildGlassCircle(
          tint: Colors.white,
          glow: Theme.of(context).colorScheme.primary,
        );
      case CallControlVariant.warning:
        return _buildGlassCircle(
          tint: Colors.redAccent,
          glow: Colors.redAccent,
        );
    }
  }

  Widget _buildGlassCircle({required Color tint, required Color glow}) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.32),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: 0.24),
                  tint.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(
                color: tint.withValues(alpha: 0.36),
                width: 1.2,
              ),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size * 0.42,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolidCircle() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade400, Colors.red.shade700],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.42),
    );
  }
}
