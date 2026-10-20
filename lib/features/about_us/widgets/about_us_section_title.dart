import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
        letterSpacing: context.ls(-0.5),
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}
