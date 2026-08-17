import 'package:flutter/material.dart';

class AiSuggestionItem {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const AiSuggestionItem({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });
}
