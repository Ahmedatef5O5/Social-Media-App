import 'package:flutter/material.dart';

class LockIndicatorPill extends StatelessWidget {
  final double progress;
  const LockIndicatorPill({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final travel = 22.0 * (1 - progress);

    return Transform.translate(
      offset: Offset(0, travel),
      child: Container(
        width: 38,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: primary.withValues(alpha: 0.5 + progress * 0.5),
              size: 18,
            ),
            const SizedBox(height: 2),
            Icon(Icons.lock_outline_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}
