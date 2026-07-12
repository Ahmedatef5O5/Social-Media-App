import 'package:flutter/material.dart';

class AboutUsSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const AboutUsSectionTitle({
    super.key,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}
