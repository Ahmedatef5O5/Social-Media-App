import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A persisted "resend in Ns" countdown.
///
/// Stores the EXPIRY timestamp, so the countdown survives leaving the screen
/// or killing the app, and can be shortened/extended to match the server's
/// own rate-limit window.
class ResendCooldown {
  ResendCooldown({required this.storageKey, this.defaultSeconds = 60});

  final String storageKey;
  final int defaultSeconds;
  final ValueNotifier<int> remaining = ValueNotifier<int>(0);

  Timer? _timer;
  int _expiryMs = 0;
  bool _disposed = false;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getInt(storageKey);
    if (expiry == null || _disposed) return;
    _begin(expiry);
  }

  Future<void> start([int? seconds]) async {
    if (_disposed) return;
    final secs = (seconds ?? defaultSeconds).clamp(1, 3600).toInt();
    final expiry = DateTime.now().millisecondsSinceEpoch + secs * 1000;
    _begin(expiry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(storageKey, expiry);
  }

  Future<void> clear() async {
    _timer?.cancel();
    _expiryMs = 0;
    if (!_disposed) remaining.value = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  void _begin(int expiryMs) {
    _timer?.cancel();
    _expiryMs = expiryMs;
    _update();
    if (remaining.value > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
    }
  }

  void _update() {
    if (_disposed) return;
    final leftMs = _expiryMs - DateTime.now().millisecondsSinceEpoch;
    final left = (leftMs + 999) ~/ 1000;
    if (left <= 0) {
      remaining.value = 0;
      _timer?.cancel();
    } else {
      remaining.value = left;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    remaining.dispose();
  }
}
