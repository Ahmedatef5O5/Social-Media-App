import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/ai_chat_scroll_anchor.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_model_option.dart';
import '../models/ai_reply_phase.dart';
import 'ai_chat_bubble.dart';
import 'ai_thinking_bubble.dart';

class AiChatMessageList extends StatelessWidget {
  final AiChatScrollAnchor scrollAnchor;
  final List<AiChatMessage> messages;
  final ValueListenable<AiReplyPhase?> replyPhase;
  final AiModelOption? activeModel;
  final bool Function(AiChatMessage)? shouldAnimateText;
  final ValueChanged<String>? onTypewriterDone;
  final ValueChanged<AiChatMessage>? onRetry;
  final ValueChanged<AiChatMessage>? onCancelUpload;
  final ValueListenable<Set<String>> selectedMessageIds;
  final ValueListenable<Set<String>> starredMessageIds;
  final ValueListenable<String?> highlightedMessageId;
  final ValueChanged<AiChatMessage> onLongPressMessage;
  final ValueChanged<AiChatMessage> onTapSelectMessage;
  final ValueChanged<AiChatMessage>? onSwipeReply;
  final ValueChanged<String>? onTapReply;

  const AiChatMessageList({
    super.key,
    required this.scrollAnchor,
    required this.messages,
    required this.replyPhase,
    required this.selectedMessageIds,
    required this.starredMessageIds,
    required this.highlightedMessageId,
    required this.onLongPressMessage,
    required this.onTapSelectMessage,
    this.activeModel,
    this.shouldAnimateText,
    this.onTypewriterDone,
    this.onRetry,
    this.onCancelUpload,
    this.onSwipeReply,
    this.onTapReply,
  });

  @override
  Widget build(BuildContext context) {
    final reversed = messages.reversed.toList(growable: false);

    final byId = <String, AiChatMessage>{};
    for (final message in messages) {
      byId[message.id] = message;
      final local = message.localId;
      if (local != null) byId[local] = message;
    }

    scrollAnchor.prune(messages.map((m) => m.stableKey));

    return ListView.builder(
      controller: scrollAnchor.controller,
      reverse: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      cacheExtent: 900,
      itemCount: reversed.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildThinkingSlot();

        final message = reversed[index - 1];
        final replyOriginId = message.replyToMessageId;
        final replyOrigin = replyOriginId == null ? null : byId[replyOriginId];

        return _MessageSlot(
          // Stable across the optimistic -> persisted id swap.
          key: ValueKey(message.stableKey),
          anchorKey: scrollAnchor.keyFor(message.stableKey),
          message: message,
          replyOrigin: replyOrigin,
          selectedMessageIds: selectedMessageIds,
          starredMessageIds: starredMessageIds,
          highlightedMessageId: highlightedMessageId,
          animate: shouldAnimateText?.call(message) ?? false,
          onTypewriterDone: onTypewriterDone,
          onRetry: onRetry,
          onCancelUpload: onCancelUpload,
          onLongPressMessage: onLongPressMessage,
          onTapSelectMessage: onTapSelectMessage,
          onSwipeReply: onSwipeReply,
          onTapReply: onTapReply,
        );
      },
    );
  }

  Widget _buildThinkingSlot() {
    return ValueListenableBuilder<AiReplyPhase?>(
      valueListenable: replyPhase,
      builder: (context, phase, _) {
        final showThinking = phase != null && activeModel != null;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              showThinking
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AiThinkingBubble(
                      key: const ValueKey('ai-thinking-bubble'),
                      phase: phase,
                      model: activeModel!,
                    ),
                  )
                  : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}

class _MessageSlot extends StatelessWidget {
  final GlobalKey anchorKey;
  final AiChatMessage message;
  final AiChatMessage? replyOrigin;
  final ValueListenable<Set<String>> selectedMessageIds;
  final ValueListenable<Set<String>> starredMessageIds;
  final ValueListenable<String?> highlightedMessageId;
  final bool animate;
  final ValueChanged<String>? onTypewriterDone;
  final ValueChanged<AiChatMessage>? onRetry;
  final ValueChanged<AiChatMessage>? onCancelUpload;
  final ValueChanged<AiChatMessage> onLongPressMessage;
  final ValueChanged<AiChatMessage> onTapSelectMessage;
  final ValueChanged<AiChatMessage>? onSwipeReply;
  final ValueChanged<String>? onTapReply;

  const _MessageSlot({
    super.key,
    required this.anchorKey,
    required this.message,
    required this.replyOrigin,
    required this.selectedMessageIds,
    required this.starredMessageIds,
    required this.highlightedMessageId,
    required this.animate,
    required this.onLongPressMessage,
    required this.onTapSelectMessage,
    this.onTypewriterDone,
    this.onRetry,
    this.onCancelUpload,
    this.onSwipeReply,
    this.onTapReply,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: anchorKey,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: selectedMessageIds,
        builder: (context, selectedIds, _) {
          return ValueListenableBuilder<Set<String>>(
            valueListenable: starredMessageIds,
            builder: (context, starredIds, __) {
              return ValueListenableBuilder<String?>(
                valueListenable: highlightedMessageId,
                builder: (context, highlightId, ___) {
                  return AiChatBubble(
                    message: message,
                    replyOrigin: replyOrigin,
                    animate: animate,
                    onTypewriterDone: onTypewriterDone,
                    onCancelUpload:
                        onCancelUpload == null
                            ? null
                            : () => onCancelUpload!(message),
                    onRetry: onRetry == null ? null : () => onRetry!(message),
                    isSelectionMode: selectedIds.isNotEmpty,
                    isSelected: selectedIds.contains(message.id),
                    isStarred: starredIds.contains(message.id),
                    isHighlighted: highlightId == message.stableKey,
                    onLongPressSelect: () => onLongPressMessage(message),
                    onTapSelect: () => onTapSelectMessage(message),
                    onSwipeReply: onSwipeReply,
                    onTapReply: onTapReply,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
