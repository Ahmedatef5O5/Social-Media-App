import 'package:flutter/material.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_model_option.dart';
import '../models/ai_reply_phase.dart';
import 'ai_chat_bubble.dart';
import 'ai_thinking_bubble.dart';

class AiChatMessageList extends StatelessWidget {
  final List<AiChatMessage> messages;
  final AiReplyPhase? activePhase;
  final AiModelOption? activeModel;
  final ValueChanged<AiChatMessage>? onCancelUpload;
  final ValueChanged<AiChatMessage>? onRetry;
  final ValueChanged<AiChatMessage>? onForward;
  final bool Function(AiChatMessage message)? shouldAnimateText;

  const AiChatMessageList({
    super.key,
    required this.messages,
    this.activePhase,
    this.activeModel,
    this.onCancelUpload,
    this.onRetry,
    this.onForward,
    this.shouldAnimateText,
  });

  @override
  Widget build(BuildContext context) {
    final reversed = messages.reversed.toList(growable: false);
    final showThinking = activePhase != null && activeModel != null;

    return Column(
      children: [
        Expanded(
          child: ListView.custom(
            reverse: true,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) {
                final message = reversed[index];
                return _KeepAliveBubble(
                  key: ValueKey(message.id),
                  child: AiChatBubble(
                    message: message,
                    animate: shouldAnimateText?.call(message) ?? false,
                    onCancelUpload:
                        onCancelUpload == null
                            ? null
                            : () => onCancelUpload!(message),
                    onRetry: onRetry == null ? null : () => onRetry!(message),
                    onForward:
                        onForward == null ? null : () => onForward!(message),
                  ),
                );
              },
              childCount: reversed.length,
              findChildIndexCallback: (key) {
                final id = (key as ValueKey).value as String;
                final index = reversed.indexWhere((m) => m.id == id);
                return index == -1 ? null : index;
              },
            ),
          ),
        ),
        if (showThinking)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AiThinkingBubble(
              key: const ValueKey('ai-thinking-bubble'),
              phase: activePhase!,
              model: activeModel!,
            ),
          ),
      ],
    );
  }
}

class _KeepAliveBubble extends StatefulWidget {
  final Widget child;
  const _KeepAliveBubble({super.key, required this.child});

  @override
  State<_KeepAliveBubble> createState() => _KeepAliveBubbleState();
}

class _KeepAliveBubbleState extends State<_KeepAliveBubble>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return widget.child;
  }
}
