import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FadeDismissWidget extends StatelessWidget {
  const FadeDismissWidget({
    super.key,
    required this.listenable,
    required this.fadeDuration,
    required this.child,
  });

  final ValueListenable<bool> listenable;
  final Duration fadeDuration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
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
    );
  }
}
