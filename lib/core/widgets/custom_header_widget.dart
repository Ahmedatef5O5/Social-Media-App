import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final Widget actions;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;
  const CustomHeader({
    super.key,
    required this.title,
    required this.actions,
    this.style,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          Text(
            title,
            style:
                style ??
                Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 22,
                ),
          ),
          const Spacer(),
          actions,
        ],
      ),
    );
  }
}
