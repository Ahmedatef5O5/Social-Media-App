import 'package:flutter/material.dart';

class CustomBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final double top;
  final double right;
  final double? left;
  final double? bottom;
  final double? size;
  final double? fontSize;
  final BoxBorder? border;

  const CustomBadge({
    super.key,
    required this.child,
    required this.count,
    this.top = 0,
    this.right = 0,
    this.left,
    this.bottom,
    this.size = 18,
    this.fontSize,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top,
          right: right,
          left: left,
          bottom: bottom,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              border:
                  border != null
                      ? Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      )
                      : null,
            ),
            constraints: BoxConstraints(minWidth: size!, minHeight: size!),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize ?? (size! * 0.5),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
