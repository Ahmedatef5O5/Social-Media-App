import 'dart:async';
import 'package:flutter/foundation.dart';

class ChatSearchController<T> {
  final List<T> Function() getMessages;
  final String Function(T message) getSearchableText;
  final String Function(T message) getId;

  ChatSearchController({
    required this.getMessages,
    required this.getSearchableText,
    required this.getId,
  });

  final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  final ValueNotifier<String> query = ValueNotifier<String>('');

  final ValueNotifier<List<String>> matchIds = ValueNotifier<List<String>>(
    const [],
  );

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(-1);

  final ValueNotifier<String> counterTextNotifier = ValueNotifier<String>('');

  Timer? _debounce;

  String? get currentMatchId {
    final ids = matchIds.value;
    final i = currentIndex.value;
    if (ids.isEmpty || i < 0 || i >= ids.length) return null;
    return ids[i];
  }

  String get counterText {
    final ids = matchIds.value;
    if (query.value.trim().isEmpty) return '';
    if (ids.isEmpty) return 'No results';
    final position = ids.length - currentIndex.value;
    return '$position of ${ids.length}';
  }

  void _updateCounterText() {
    final ids = matchIds.value;
    if (query.value.trim().isEmpty) {
      counterTextNotifier.value = '';
      return;
    }
    if (ids.isEmpty) {
      counterTextNotifier.value = 'No results';
      return;
    }
    final position = currentIndex.value + 1;
    counterTextNotifier.value = '$position of ${ids.length}';
  }

  void activate() {
    isActive.value = true;
  }

  void updateQuery(String q) {
    if (query.value == q) return;
    query.value = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  void _runSearch(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      matchIds.value = const [];
      currentIndex.value = -1;
      _updateCounterText();
      return;
    }

    final lower = trimmed.toLowerCase();
    final ids =
        getMessages()
            .where((m) => getSearchableText(m).toLowerCase().contains(lower))
            .map(getId)
            .toList();

    if (_areListsEqual(matchIds.value, ids)) {
      return;
    }

    matchIds.value = ids;
    currentIndex.value = ids.isEmpty ? -1 : 0;
    _updateCounterText();
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void previousMatch() {
    if (currentIndex.value < matchIds.value.length - 1) {
      currentIndex.value += 1;
      _updateCounterText();
    }
  }

  void nextMatch() {
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
      _updateCounterText();
    }
  }

  void deactivate() {
    _debounce?.cancel();
    isActive.value = false;
    query.value = '';
    matchIds.value = const [];
    currentIndex.value = -1;
    counterTextNotifier.value = '';
  }

  void dispose() {
    _debounce?.cancel();
    isActive.dispose();
    query.dispose();
    matchIds.dispose();
    currentIndex.dispose();
    counterTextNotifier.dispose();
  }
}
