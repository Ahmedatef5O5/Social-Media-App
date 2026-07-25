import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/mentions/widgets/mention_aware_text_field.dart';
import 'package:social_media_app/core/audio/voice_recorder/widgets/voice_recorder_input_section.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../../../core/mentions/widgets/mention_text_editing_controller.dart';
import '../helpers/send_button.dart';

class GroupInputBar extends StatelessWidget {
  final bool hasText;
  final MentionTextEditingController controller;
  final FocusNode focusNode;
  final List<String>? mentionCandidateIds;

  final VoidCallback onTyping;
  final void Function(String text, List<MentionRef> mentions) onSend;
  final VoidCallback onShowMedia;
  final void Function(File file, int durationSeconds) onSendVoice;

  const GroupInputBar({
    super.key,
    required this.hasText,
    required this.controller,
    required this.focusNode,
    this.mentionCandidateIds,
    required this.onTyping,
    required this.onSend,
    required this.onShowMedia,
    required this.onSendVoice,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: VoiceRecorderInputSection(
        textField: MentionAwareTextField(
          controller: controller,
          focusNode: focusNode,
          enabled: true,
          hintText: 'Type a message...',
          restrictSuggestionsToUserIds: mentionCandidateIds,
          onSubmitted: (_) => _send(),
        ),
        hasText: hasText,
        onShowAttachments: onShowMedia,
        sendButton: SendButton(primary: primary, onTap: _send),
        onSendVoice: onSendVoice,
      ),
    );
  }
}
