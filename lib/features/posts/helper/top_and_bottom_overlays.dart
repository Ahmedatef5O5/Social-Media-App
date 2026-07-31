import 'package:flutter/material.dart';
import 'dismissible_video_overlay.dart';

class TopOverlays extends StatelessWidget {
  const TopOverlays({
    super.key,
    required ValueNotifier<bool> showOverlays,
    required Duration fadeDuration,
  }) : _showOverlays = showOverlays,
       _fadeDuration = fadeDuration;

  final ValueNotifier<bool> _showOverlays;
  final Duration _fadeDuration;

  @override
  Widget build(BuildContext context) {
    return DismissibleVideoOverlay(
      listenable: _showOverlays,
      fadeDuration: _fadeDuration,
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomOverlays extends StatelessWidget {
  const BottomOverlays({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
