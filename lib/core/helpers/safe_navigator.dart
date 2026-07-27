import 'package:flutter/material.dart';

/// Centralized, race-safe navigation helpers used across the whole app.
extension SafeNavigatorExtension on BuildContext {
  void safePop<T extends Object?>([T? result]) {
    final navigator = Navigator.maybeOf(this);
    if (navigator != null && navigator.canPop()) {
      navigator.pop(result);
    }
  }

  void safePopRoot<T extends Object?>([T? result]) {
    final navigator = Navigator.maybeOf(this, rootNavigator: true);
    if (navigator != null && navigator.canPop()) {
      navigator.pop(result);
    }
  }
}

/// A single-flight lock so that deep-link handlers (notifications) never
/// mutate the root navigator stack (`pushNamedAndRemoveUntil`, etc.) while
/// an interactive pop gesture from the user is already in flight.
class NavigationGuard {
  NavigationGuard._();
  static bool _busy = false;

  static Future<void> runExclusive(Future<void> Function() action) async {
    if (_busy) return; // a competing stack mutation is already running
    _busy = true;
    try {
      await action();
    } finally {
      // give the current frame's animation/gesture time to fully settle
      await Future.delayed(const Duration(milliseconds: 60));
      _busy = false;
    }
  }
}

/// Reusable "close exactly once" guard for gesture + button driven screens
/// (media viewers, story viewers, full-screen sheets...).
class SingleFireGuard {
  bool _fired = false;
  bool tryFire() {
    if (_fired) return false;
    _fired = true;
    return true;
  }

  void reset() => _fired = false;
}
