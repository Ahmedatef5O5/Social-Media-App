import 'package:flutter/material.dart';

class TypingIndicatorWidget extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;

  const TypingIndicatorWidget({
    super.key,
    this.color = Colors.grey,
    this.dotSize = 4.0,
    this.spacing = 2.0,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations =
        _controllers.map((controller) {
          return Tween<double>(begin: 0, end: -1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
        }).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            margin: EdgeInsets.symmetric(horizontal: widget.spacing),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value * (widget.dotSize * 1.2)),
              child: child,
            );
          },
        );
      }),
    );
  }
}
