import 'package:flutter/material.dart';
import 'app_toast_type.dart';

class AppToastRequest {
  final String id;
  final String message;
  final AppToastType type;
  final Duration duration;
  final String? actionLabel;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onAction;

  AppToastRequest({
    required this.id,
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.icon,
    this.iconColor,
    this.onAction,
  });
}
