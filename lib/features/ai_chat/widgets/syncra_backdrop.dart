import 'package:flutter/material.dart';
import '../helpers/ai_chat_colors.dart';

class SyncraBackdrop extends StatelessWidget {
  const SyncraBackdrop({super.key, required this.primary});

  final Color primary;

  static List<Color> gradientColors(Color primary) =>
      AiChatColors.backgroundGradient(primary);

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors(primary);
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -60,
          child: GlowBlob(color: primary, size: 240),
        ),
        Positioned(
          bottom: -110,
          left: -80,
          child: GlowBlob(color: primary, size: 280),
        ),
      ],
    );
  }
}

class GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const GlowBlob({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
