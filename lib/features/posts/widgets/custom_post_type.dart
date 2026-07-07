import 'package:flutter/material.dart';

class CustomPostType extends StatelessWidget {
  final Widget? child;
  final Color? bgColor;
  final BoxBorder? border;
  const CustomPostType({super.key, this.child, this.bgColor, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      width: 80,
      height: 82,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: border,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: child,
      ),
    );
  }
}
