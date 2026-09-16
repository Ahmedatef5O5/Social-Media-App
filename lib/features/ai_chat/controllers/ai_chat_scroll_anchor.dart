import 'package:flutter/material.dart';

class AiChatScrollAnchor {
  final ScrollController controller = ScrollController();

  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  /// One stable GlobalKey per message, minted lazily. Keyed by the message's
  /// stableKey so the optimistic -> persisted id swap does not invalidate it.
  GlobalKey keyFor(String stableKey) => _keys.putIfAbsent(
    stableKey,
    () => GlobalKey(debugLabel: 'ai-msg-$stableKey'),
  );

  /// Drops keys for messages that are no longer in the conversation so the
  /// map does not grow without bound over a long session.
  void prune(Iterable<String> aliveStableKeys) {
    if (_keys.length <= 200) return;
    final alive = aliveStableKeys.toSet();
    _keys.removeWhere((key, _) => !alive.contains(key));
  }

  bool get _hasClients => controller.hasClients;

  bool get isPinnedToBottom {
    if (!_hasClients) return true;
    return controller.position.pixels <= 24;
  }

  void pinToBottom() {
    if (!_hasClients || isPinnedToBottom) return;
    controller.jumpTo(0);
  }

  Future<bool> revealMessage({
    required String stableKey,
    required List<String> reversedStableKeys,
  }) async {
    if (!_hasClients) return false;

    final targetIndex = reversedStableKeys.indexOf(stableKey);
    if (targetIndex < 0) return false;

    const maxSweeps = 24;

    for (var sweep = 0; sweep < maxSweeps; sweep++) {
      final context = _keys[stableKey]?.currentContext;

      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          alignment: 0.35,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
        return true;
      }

      int? lowestBuilt;
      int? highestBuilt;

      for (var i = 0; i < reversedStableKeys.length; i++) {
        if (_keys[reversedStableKeys[i]]?.currentContext != null) {
          lowestBuilt ??= i;
          highestBuilt = i;
        }
      }

      final position = controller.position;
      final step = position.viewportDimension * 0.85;

      final double desired;
      if (highestBuilt != null && targetIndex > highestBuilt) {
        desired = position.pixels + step; // towards older messages
      } else if (lowestBuilt != null && targetIndex < lowestBuilt) {
        desired = position.pixels - step; // towards newer messages
      } else {
        desired = position.pixels + step;
      }

      final next = desired.clamp(0.0, position.maxScrollExtent);
      if ((next - position.pixels).abs() < 1) return false;

      controller.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
      if (!_hasClients) return false;
    }

    return false;
  }

  void dispose() {
    controller.dispose();
    _keys.clear();
  }
}
