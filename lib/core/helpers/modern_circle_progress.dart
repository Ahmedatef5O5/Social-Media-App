import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/helpers/animated_check_painter.dart';
import 'package:social_media_app/core/helpers/modern_progress_painter.dart';

class ModernCircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final String? label;
  final bool showCheckmark;
  final bool enableHaptic;

  const ModernCircularProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.label,
    this.showCheckmark = false,
    this.enableHaptic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final bgCircleColor =
        theme.brightness == Brightness.light
            ? Colors.grey[300]!
            : Colors.grey[800]!;
    final isCompleted = progress >= 0.99;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutBack,
      onEnd: () {
        if (progress >= 0.99 && enableHaptic) {
          HapticFeedback.mediumImpact();
        }
      },
      builder: (BuildContext context, double value, Widget? child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: (isCompleted && showCheckmark) ? 0.0 : 1.0,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(size, size),
                  painter: ModernProgressPainter(
                    progress: value,
                    backgroundColor: bgCircleColor,
                    progressColor: primaryColor,
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child:
                  (isCompleted && showCheckmark)
                      ? TweenAnimationBuilder<double>(
                        key: const ValueKey('check'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOutBack,
                        builder: (context, checkVal, _) {
                          return CustomPaint(
                            size: Size(size, size),
                            painter: AnimatedCheckPainter(
                              progress: checkVal,
                              color: primaryColor,
                              strokeWidth: size * 0.12,
                            ),
                          );
                        },
                      )
                      : Text(
                        key: const ValueKey('text'),
                        label ?? "${(progress * 100).toInt()}%",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color:
                              theme.brightness == Brightness.light
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.7)
                                  : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: label != null ? size * 0.18 : size * 0.28,
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }
}
