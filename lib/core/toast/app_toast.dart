import 'package:flutter/material.dart';
import 'app_toast_request.dart';
import 'app_toast_type.dart';

class AppToast {
  AppToast._();

  static final ValueNotifier<AppToastRequest?> requestNotifier =
      ValueNotifier<AppToastRequest?>(null);

  static int _counter = 0;

  static void _show({
    required String message,
    required AppToastType type,
    IconData? icon,
    Color? iconColor,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _counter++;
    requestNotifier.value = AppToastRequest(
      id: 'toast_$_counter',
      message: message,
      type: type,
      icon: icon,
      iconColor: iconColor,
      duration: duration ?? _defaultDuration(type),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static Duration _defaultDuration(AppToastType type) {
    switch (type) {
      case AppToastType.error:
        return const Duration(seconds: 3);
      case AppToastType.warning:
        return const Duration(milliseconds: 2800);
      case AppToastType.success:
        return const Duration(milliseconds: 2500);
      case AppToastType.info:
        return const Duration(seconds: 2);
      case AppToastType.save:
        return const Duration(seconds: 2);
    }
  }

  static void success(
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _show(
    message: message,
    icon: icon,
    type: AppToastType.success,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  static void error(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _show(
    message: message,
    type: AppToastType.error,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  static void warning(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _show(
    message: message,
    type: AppToastType.warning,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  static void info(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _show(
    message: message,
    type: AppToastType.info,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  static void save(
    String message, {
    IconData? icon,
    Color? iconColor,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    message: message,
    type: AppToastType.save,
    icon: icon,
    iconColor: iconColor,
    duration: duration ?? const Duration(milliseconds: 1800),
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
