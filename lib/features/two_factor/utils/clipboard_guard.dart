import 'dart:async';
import 'package:flutter/services.dart';

/// Copies a secret and removes it from the clipboard after [ttl], but only if
/// the clipboard still holds that exact text (never wipes something the user
/// copied afterwards).
class ClipboardGuard {
  ClipboardGuard._();

  static Timer? _timer;

  static Future<void> copySensitive(
    String text, {
    Duration ttl = const Duration(seconds: 60),
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    _timer?.cancel();
    _timer = Timer(ttl, () async {
      try {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {}
    });
  }
}
