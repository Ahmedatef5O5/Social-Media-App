import 'package:flutter/material.dart';
import 'package:social_media_app/features/ai_chat/controllers/ai_chat_scroll_anchor.dart';
import '../models/ai_chat_message.dart';

class AiChatReplyController {
  final ValueNotifier<AiChatMessage?> replyingTo =
      ValueNotifier<AiChatMessage?>(null);
  final ValueNotifier<String?> highlightedMessageId = ValueNotifier<String?>(
    null,
  );

  bool _isDisposed = false;

  void setReply(AiChatMessage message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  Future<void> revealMessage({
    required String messageId,
    required List<AiChatMessage> messages,
    required AiChatScrollAnchor anchor,
  }) async {
    AiChatMessage? target;
    for (final message in messages) {
      if (message.id == messageId || message.localId == messageId) {
        target = message;
        break;
      }
    }
    if (target == null) return;

    final reversedKeys = messages.reversed
        .map((m) => m.stableKey)
        .toList(growable: false);

    final found = await anchor.revealMessage(
      stableKey: target.stableKey,
      reversedStableKeys: reversedKeys,
    );

    if (_isDisposed || !found) return;

    highlightedMessageId.value = target.stableKey;
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!_isDisposed) highlightedMessageId.value = null;
    });
  }

  void dispose() {
    _isDisposed = true;
    replyingTo.dispose();
    highlightedMessageId.dispose();
  }
}
