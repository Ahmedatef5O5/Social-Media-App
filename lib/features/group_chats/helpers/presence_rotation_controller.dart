import 'dart:async';
import 'package:flutter/foundation.dart';

class PresenceRotationController<T> {
  final ValueNotifier<T?> current = ValueNotifier(null);
  Timer? _rotationTimer;
  List<T> _items = [];
  int _index = 0;

  void update(List<T> items) {
    if (listEquals(items, _items)) return;
    _items = items;
    _index = 0;
    _rotationTimer?.cancel();

    if (_items.isEmpty) {
      current.value = null;
      return;
    }

    current.value = _items[0];
    if (_items.length > 1) {
      _rotationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _index = (_index + 1) % _items.length;
        current.value = _items[_index];
      });
    }
  }

  void dispose() {
    _rotationTimer?.cancel();
    current.dispose();
  }
}
