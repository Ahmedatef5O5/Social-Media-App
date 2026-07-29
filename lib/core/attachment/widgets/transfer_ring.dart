import 'package:flutter/material.dart';
import '../../helpers/modern_progress_painter.dart';

class GlassPillBadge extends StatelessWidget {
  final Widget leading;
  final String? caption;
  final String? secondaryCaption;

  const GlassPillBadge({
    super.key,
    required this.leading,
    this.caption,
    this.secondaryCaption,
  });

  @override
  Widget build(BuildContext context) {
    final hasCaption = caption != null && caption!.isNotEmpty;
    final hasSecondary =
        secondaryCaption != null && secondaryCaption!.isNotEmpty;
    final hasText = hasCaption || hasSecondary;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          if (hasText) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasSecondary)
                    Text(
                      secondaryCaption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  if (hasCaption)
                    Text(
                      caption!,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: hasSecondary ? 0.82 : 1,
                        ),
                        fontSize: hasSecondary ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TransferRing extends StatelessWidget {
  final double size;
  final double progress;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const TransferRing({
    super.key,
    required this.size,
    required this.progress,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: ModernProgressPainter(
                    progress: value,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    progressColor: primary,
                  ),
                );
              },
            ),
            Icon(icon, size: size * 0.42, color: iconColor ?? Colors.white),
          ],
        ),
      ),
    );
  }
}
