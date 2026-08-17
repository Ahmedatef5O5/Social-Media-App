import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/attachment/attachment_sheet/picked_attachment.dart';
import '../../../core/audio/voice_recorder/widgets/voice_recorder_input_section.dart';
import '../../../core/widgets/directional_text_field.dart';
import '../models/ai_model_option.dart';
import 'ai_model_selector.dart';

class AiChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AiModelOption selectedModel;
  final ValueChanged<AiModelOption> onModelChanged;
  final ValueChanged<String> onSendText;
  final void Function(File file, int durationSeconds) onSendVoice;
  final ValueChanged<PickedAttachment> onAttachmentPicked;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.selectedModel,
    required this.onModelChanged,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttachmentPicked,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final notEmpty = widget.controller.text.trim().isNotEmpty;
    if (notEmpty != _hasText) setState(() => _hasText = notEmpty);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    widget.controller.clear();
  }

  Future<void> _openAttachmentSheet() async {
    final picked = await AttachmentPickerSheet.show(
      context,
      showVoiceOption: false, // voice already lives in the mic long-press.
      showFileOption: true,
      showCameraOption: true,
    );
    if (picked == null || !mounted) return;
    if (picked.kind == AttachmentKind.voice) return;
    widget.onAttachmentPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: AiModelSelector(
              selected: widget.selectedModel,
              onChanged: widget.onModelChanged,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: VoiceRecorderInputSection(
                  hasText: _hasText,
                  onShowAttachments: _openAttachmentSheet,
                  onSendVoice: widget.onSendVoice,
                  textField: DirectionalTextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: Colors.white70,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      hintText: 'Message Syncra...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  sendButton: InkWell(
                    onTap: _handleSend,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.selectedModel.accentColor,
                            widget.selectedModel.accentColor.withValues(
                              alpha: 0.7,
                            ),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
