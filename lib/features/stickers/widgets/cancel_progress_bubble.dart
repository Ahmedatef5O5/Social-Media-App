import 'package:flutter/material.dart';

class CancelProgressBubble extends StatelessWidget {
  final bool visible;
  final double size;
  final double offset;
  final VoidCallback onCancel;

  const CancelProgressBubble({
    super.key,
    required this.visible,
    required this.onCancel,
    this.size = 22,
    this.offset = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      // top: -9,
      // left: -9,
      top: -(size * offset),
      left: -(size * offset),
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedScale(
          scale: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.9),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: size * .58,

                  color:
                      theme.colorScheme
                          .copyWith(onSurface: Colors.white)
                          .onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
