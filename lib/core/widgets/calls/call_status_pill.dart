import 'package:flutter/material.dart';

class CallStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showLiveDot;

  final Animation<double>? shake;

  const CallStatusPill({
    super.key,
    required this.icon,
    required this.label,
    this.showLiveDot = false,
    this.shake,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLiveDot) ...[const _LiveDot(), const SizedBox(width: 8)],
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    if (shake == null) return pill;

    return AnimatedBuilder(
      animation: shake!,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(shake!.value * 0.4, 0),
          child: child,
        );
      },
      child: pill,
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.greenAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}
