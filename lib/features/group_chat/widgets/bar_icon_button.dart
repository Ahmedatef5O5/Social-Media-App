import 'package:flutter/material.dart';

class BarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const BarIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: onTap, child: Icon(icon, color: color, size: 27));
}
