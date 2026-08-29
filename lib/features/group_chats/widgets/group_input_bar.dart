import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/mentions/widgets/mention_aware_text_field.dart';
import '../../../core/audio/voice_recorder/widgets/voice_recorder_input_section.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../../../core/mentions/widgets/mention_text_editing_controller.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/helpers/remote_media_fetcher.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
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
  final bool hasReplyContext;
  final String? targetText;
  final String? mediaCaption;
  final String? targetUserName;
  final AiTargetMediaType targetMediaType;
  final String? targetImageUrl;
  final VoidCallback? onSlashAiTrigger;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingPause;
  final VoidCallback? onRecordingResume;
  final VoidCallback? onRecordingStop;
  final VoidCallback? onRecordingCancel;

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
    this.hasReplyContext = false,
    this.targetText,
    this.mediaCaption,
    this.targetUserName,
    this.targetMediaType = AiTargetMediaType.none,
    this.targetImageUrl,
    this.onSlashAiTrigger,
    this.onRecordingStart,
    this.onRecordingPause,
    this.onRecordingResume,
    this.onRecordingStop,
    this.onRecordingCancel,
  });

  void _send() {
    final text = controller.text.trim();
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          fillColor: Colors.transparent,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          trailingIcon: AiActionIcon(
            controller: controller,
            surface: AiSurfaceType.chatMessage,
            generationAction: AiActionType.replySuggestion,
            actionContext: AiActionContext.chatReply,
            hasReplyContext: hasReplyContext,
            targetText: targetText,
            mediaCaption: mediaCaption,
            targetUserName: targetUserName,
            targetMediaType: targetMediaType,
            targetImageBytesProvider:
                targetImageUrl != null
                    ? () => RemoteMediaFetcher.fetchBytes(targetImageUrl!)
                    : null,
          ),
          onSlashAiTrigger: onSlashAiTrigger,
        ),
        hasText: hasText,
        onShowAttachments: onShowMedia,
        sendButton: SendButton(primary: primary, onTap: _send),
        onSendVoice: onSendVoice,
        onRecordingStart: onRecordingStart,
        onRecordingPause: onRecordingPause,
        onRecordingResume: onRecordingResume,
        onRecordingStop: onRecordingStop,
        onRecordingCancel: onRecordingCancel,
      ),
    );
  }
}
