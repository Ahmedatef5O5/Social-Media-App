import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/attachment/attachment_sheet/picked_attachment.dart';
import '../../../core/audio/voice_recorder/widgets/voice_recorder_input_section.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/directional_text_field.dart';
import '../helpers/ai_chat_dictation_controller.dart';
import '../models/ai_model_option.dart';
import 'ai_chat_staged_file_preview.dart';

class AiChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AiModelOption selectedModel;
  final ValueChanged<AiModelOption> onModelChanged;
  final ValueChanged<String> onSendText;
  final void Function(File file, int durationSeconds) onSendVoice;
  final ValueChanged<PickedAttachment> onAttachmentPicked;
  final String? stagedFileName;
  final int? stagedFileSizeBytes;
  final File? stagedImageFile;
  final VoidCallback? onRemoveStagedFile;
  final VoidCallback? onTapStagedFile;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.selectedModel,
    required this.onModelChanged,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttachmentPicked,
    this.stagedFileName,
    this.stagedFileSizeBytes,
    this.onRemoveStagedFile,
    this.stagedImageFile,
    this.onTapStagedFile,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  bool _hasText = false;

  final AiChatDictationController _dictation = AiChatDictationController();
  bool _isDictating = false;
  String _dictationBaseText = '';
  String _dictationCommitted = '';

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
    _dictation.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty && widget.stagedFileName == null) return;
    if (_isDictating) _toggleDictation();
    widget.onSendText(text);
    widget.controller.clear();
  }

  Future<void> _openAttachmentSheet() async {
    final picked = await AttachmentPickerSheet.show(
      context,
      showVoiceOption: false,
      showFileOption: true,
      showCameraOption: true,
      showVideoOption: false,
      showGifOption: false,
      showStickerOption: false,
    );
    if (picked == null || !mounted) return;
    if (picked.kind == AttachmentKind.voice) return;
    widget.onAttachmentPicked(picked);
  }

  // ---------------------------------------------------------------------
  // Dictation (tap on the mic icon).
  // ---------------------------------------------------------------------

  Future<void> _stopDictation() async {
    if (!_isDictating) return;
    await _dictation.stop();
    if (mounted) setState(() => _isDictating = false);
  }

  Future<void> _toggleDictation() async {
    if (_isDictating) {
      await _stopDictation();
      return;
    }

    _dictationBaseText = widget.controller.text;
    _dictationCommitted = '';
    final started = await _dictation.start(
      onLiveUpdate: _onDictationLiveUpdate,
      onFinalSegment: _onDictationFinalSegment,
    );
    if (!mounted) return;
    if (!started) {
      AppToast.info("Voice dictation isn't available on this device.");
      return;
    }
    setState(() => _isDictating = true);
  }

  void _setComposerText(String text) {
    widget.controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  String get _dictationBase => [
    _dictationBaseText,
    _dictationCommitted,
  ].where((s) => s.trim().isNotEmpty).join(' ');

  void _onDictationLiveUpdate(String liveWords) {
    final display = [
      _dictationBase,
      liveWords,
    ].where((s) => s.trim().isNotEmpty).join(' ');
    _setComposerText(display);
  }

  void _onDictationFinalSegment(String finalWords) {
    _dictationCommitted = [
      _dictationCommitted,
      finalWords,
    ].where((s) => s.trim().isNotEmpty).join(' ');
    _setComposerText(_dictationBase);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.stagedFileName != null)
            AiChatStagedFilePreview(
              fileName: widget.stagedFileName!,
              fileSizeBytes: widget.stagedFileSizeBytes ?? 0,
              imageFile: widget.stagedImageFile,
              onTapLeading: widget.onTapStagedFile,
              onRemove: widget.onRemoveStagedFile ?? () {},
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: VoiceRecorderInputSection(
                  hasText:
                      (_hasText || widget.stagedFileName != null) &&
                      !_isDictating,
                  onShowAttachments: _openAttachmentSheet,
                  onSendVoice: widget.onSendVoice,
                  onMicTap: _toggleDictation,
                  isDictating: _isDictating,
                  onForceStopDictation: _stopDictation,
                  textField: DirectionalTextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: Colors.white70,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
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
            ],
          ),
        ],
      ),
    );
  }
}
