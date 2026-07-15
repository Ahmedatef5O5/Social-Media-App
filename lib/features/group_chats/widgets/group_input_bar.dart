import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/mentions/widgets/mention_aware_text_field.dart';
import 'package:social_media_app/features/group_chats/helpers/bar_icon_button.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../../../core/mentions/widgets/mention_text_editing_controller.dart';
import '../helpers/mic_button.dart';
import '../helpers/recording_indicator.dart';
import '../helpers/send_button.dart';

class InputBar extends StatelessWidget {
  final bool isRecording;
  final bool hasText;
  final int seconds;
  final MentionTextEditingController controller;
  final FocusNode focusNode;
  final List<String>? mentionCandidateIds;

  final VoidCallback onTyping;
  final void Function(String text, List<MentionRef> mentions) onSend;
  final VoidCallback onShowMedia;
  final Future<void> Function() onStartRecording;
  final Future<void> Function() onStopRecording;

  const InputBar({
    super.key,
    required this.isRecording,
    required this.hasText,
    required this.seconds,
    required this.controller,
    required this.focusNode,
    this.mentionCandidateIds,
    required this.onTyping,
    required this.onSend,
    required this.onShowMedia,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    onSend(text, controller.validMentions);
    controller.clear();
    controller.clearMentions();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          BarIconButton(icon: Icons.add, color: primary, onTap: onShowMedia),

          const Gap(4),

          Expanded(
            child: AnimatedContainer(
              // padding: const EdgeInsets.symmetric(horizontal: 10),
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isRecording
                        ? Colors.red.withValues(alpha: 0.10)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : primary.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(24),
              ),
              child:
                  isRecording
                      ? RecordingIndicator(seconds: seconds)
                      : MentionAwareTextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: true,
                        hintText: 'Type a message...',

                        restrictSuggestionsToUserIds: mentionCandidateIds,
                        onSubmitted: (_) => _send(),
                      ),
            ),
          ),

          const Gap(8),

          hasText
              ? SendButton(primary: primary, onTap: _send)
              : MicButton(
                isRecording: isRecording,
                primary: primary,
                onStart: onStartRecording,
                onEnd: onStopRecording,
              ),
        ],
      ),
    );
  }
}
