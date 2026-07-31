import 'package:flutter/material.dart';

class FullScreenVideoActions extends StatelessWidget {
  final Widget child;
  final String? label;

  const FullScreenVideoActions({super.key, required this.child, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (label != null && label != '0') ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 5, color: Colors.black87)],
            ),
          ),
        ],
      ],
    );
  }
}
