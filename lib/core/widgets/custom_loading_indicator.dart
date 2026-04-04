import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double? radius;
  final Color? color;

  const CustomLoadingIndicator({super.key, this.radius, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(
        radius: radius ?? 10,
        color: color ?? Theme.of(context).primaryColor,
      ),
    );
  }
}
