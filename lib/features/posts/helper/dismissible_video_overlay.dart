import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DismissibleVideoOverlay extends StatelessWidget {
  const DismissibleVideoOverlay({
    super.key,
    required this.listenable,
    required this.fadeDuration,
    required this.child,
    required this.alignment,
  });

  final ValueListenable<bool> listenable;
  final Duration fadeDuration;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ValueListenableBuilder<bool>(
        valueListenable: listenable,
        builder: (context, visible, _) {
          return IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1.0 : 0.0,
              duration: fadeDuration,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
