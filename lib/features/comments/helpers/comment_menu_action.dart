import 'package:flutter/material.dart';

class CommentMenuAction {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const CommentMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}
