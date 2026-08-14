import 'package:flutter/material.dart';

class SettingsItemData {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool? toggle;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final Widget? footer;

  const SettingsItemData({
    required this.icon,
    required this.label,
    this.subtitle,
    this.toggle,
    this.onTap,
    this.onToggle,
    this.footer,
  });
}
