import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/features/group_chats/widgets/group_input_bar.dart';
import 'package:social_media_app/features/group_chats/widgets/group_media_preview_screen.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/chat_shared/widgets/chat_staged_file_preview.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_chat_command_trigger.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';
import '../helpers/group_chat_transcript_builder.dart';
import 'group_edit_preview_section.dart';
import 'reply_preview_section.dart';

class GroupChatInputBarSection extends StatefulWidget {
  final MentionTextEditingController controller;
  final void Function(String text, List<MentionRef> mentions) onSend;
  final VoidCallback onTyping;
  final List<String>? mentionCandidateIds;

  const GroupChatInputBarSection({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTyping,
    this.mentionCandidateIds,
  });

  @override
  State<GroupChatInputBarSection> createState() =>
      _GroupChatInputBarSectionState();
}

class _GroupChatInputBarSectionState extends State<GroupChatInputBarSection> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FocusNode _focusNode = FocusNode();
  late final GroupDetailsCubit _cubit;

  bool _hasText = false;
  bool _isSending = false;
  List<String>? _membersIds;
  File? _stagedDocument;
  String? _stagedFileName;
  int? _stagedFileSizeBytes;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<GroupDetailsCubit>();
    widget.controller.addListener(_onTextChanged);
    _cubit.editingMessage.addListener(_onEditingMessageChanged);
    _loadMemberIds();
  }

  void _onTextChanged() {
    final notEmpty =
        widget.controller.text.trim().isNotEmpty || _stagedDocument != null;
    if (notEmpty != _hasText) setState(() => _hasText = notEmpty);
    if (notEmpty) {
      widget.onTyping();
      if (_cubit.searchController.isActive.value) {
        _cubit.searchController.deactivate();
      }
    }
  }

  // ── Voice recording ─────────────────────────────────────────

  void _onEditingMessageChanged() {
    final editing = _cubit.editingMessage.value;
    if (editing == null) return;
    final text =
        editing.text.isNotEmpty ? editing.text : (editing.caption ?? '');
    widget.controller.text = text;
    widget.controller.setMentions(editing.mentions);
    widget.controller.selection = TextSelection.collapsed(offset: text.length);
    setState(() => _hasText = text.trim().isNotEmpty);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleSend(String text, List<MentionRef> mentions) {
    if (_isSending) return;
    final editing = _cubit.editingMessage.value;
    if (editing != null) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      _isSending = true;
      _cubit.editMessage(
        messageId: editing.id,
        newText: trimmed,
        mentions: mentions,
      );
      _cubit.editingMessage.value = null;
      _isSending = false;
    } else {
      if (_stagedDocument != null) {
        _isSending = true;
        final docToSend = _stagedDocument!;
        final nameToSend = _stagedFileName;
        final sizeToSend = _stagedFileSizeBytes;
        setState(() {
          _stagedDocument = null;
          _stagedFileName = null;
          _stagedFileSizeBytes = null;
          _hasText = false;
        });
        widget.controller.clear();
        widget.controller.clearMentions();
        _cubit.sendMessage(
          text: '',
          messageType: 'file',
          documentFile: docToSend,
          fileName: nameToSend,
          fileSizeBytes: sizeToSend,
          caption: text.trim().isNotEmpty ? text.trim() : null,
          mentions: mentions,
        );
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _isSending = false;
        });
      } else if (text.trim().isNotEmpty) {
        _isSending = true;
        widget.onSend(text.trim(), mentions);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _isSending = false;
        });
      }
    }
  }

  Future<void> _loadMemberIds() async {
    try {
      final ids =
          await context.read<GroupDetailsCubit>().getMemberIdsForMentions();
      if (mounted) {
        setState(() {
          _membersIds = ids;
        });
      }
    } catch (e) {
      debugPrint('[GroupChatInputBar] failed to load group members: $e');
    }
  }

  Future<void> _openAttachmentSheet() async {
    final picked = await AttachmentPickerSheet.show(
      context,
      showVoiceOption: false,
      showFileOption: true,
      showCameraOption: true,
    );
    if (picked == null || !mounted) return;

    final cubit = context.read<GroupDetailsCubit>();

    switch (picked.kind) {
      case AttachmentKind.image:
        if (picked.localFile == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (ctx) => BlocProvider.value(
                  value: cubit,
                  child: GroupMediaPreviewScreen(
                    file: picked.localFile!,
                    type: 'image',
                    onSend:
                        (caption) => cubit.sendMessage(
                          text: '',
                          messageType: 'image',
                          imageFile: picked.localFile,
                          fileSizeBytes: picked.fileSizeBytes,
                          caption: caption,
                        ),
                  ),
                ),
          ),
        );
        break;

      case AttachmentKind.video:
        if (picked.localFile == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (ctx) => BlocProvider.value(
                  value: cubit,
                  child: GroupMediaPreviewScreen(
                    file: picked.localFile!,
                    type: 'video',
                    onSend:
                        (caption) => cubit.sendMessage(
                          text: '',
                          messageType: 'video',
                          videoFile: picked.localFile,
                          fileSizeBytes: picked.fileSizeBytes,
                          durationSeconds: picked.durationSeconds,
                          caption: caption,
                        ),
                  ),
                ),
          ),
        );
        break;

      case AttachmentKind.file:
        if (picked.localFile == null) return;
        setState(() {
          _stagedDocument = picked.localFile;
          _stagedFileName = picked.fileName;
          _stagedFileSizeBytes = picked.fileSizeBytes;
          _hasText = true;
        });
        break;

      case AttachmentKind.gif:
        cubit.sendMessage(
          text: '',
          messageType: 'gif',
          remoteImageUrl: picked.remoteUrl,
        );
        break;

      case AttachmentKind.sticker:
        cubit.sendMessage(
          text: '',
          messageType: 'sticker',
          remoteImageUrl: picked.remoteUrl,
        );
        break;

      case AttachmentKind.voice:
        break;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _cubit.editingMessage.removeListener(_onEditingMessageChanged);
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GroupEditPreviewSection(cubit: _cubit, controller: widget.controller),
        GroupReplyPreviewSection(cubit: _cubit),

        if (_stagedDocument != null)
          ChatStagedFilePreview(
            fileName: _stagedFileName ?? 'File',
            fileSizeBytes: _stagedFileSizeBytes ?? 0,
            onRemove: () {
              setState(() {
                _stagedDocument = null;
                _stagedFileName = null;
                _stagedFileSizeBytes = null;
                _hasText = widget.controller.text.trim().isNotEmpty;
              });
            },
          ),

        ValueListenableBuilder<GroupMessageModel?>(
          valueListenable: _cubit.replyToMessage,
          builder: (context, replyTo, _) {
            return GroupInputBar(
              hasText: _hasText,
              controller: widget.controller,
              focusNode: _focusNode,
              mentionCandidateIds: _membersIds,
              onTyping: widget.onTyping,
              onSend: _handleSend,
              onShowMedia: _openAttachmentSheet,
              hasReplyContext: replyTo != null,
              targetText:
                  (replyTo == null || replyTo.messageType == 'text')
                      ? replyTo?.text
                      : null,
              mediaCaption:
                  (replyTo != null && replyTo.messageType != 'text')
                      ? replyTo.caption
                      : null,
              targetMediaType: AiTargetMediaType.fromWireMessageType(
                replyTo?.messageType,
              ),
              targetUserName:
                  replyTo == null
                      ? null
                      : (replyTo.senderId == _cubit.currentUserId
                          ? 'You'
                          : replyTo.senderName),
              targetImageUrl:
                  (replyTo != null && replyTo.messageType == 'image')
                      ? replyTo.imageUrl
                      : null,
              onSendVoice: (file, seconds) {
                context.read<GroupDetailsCubit>().sendMessage(
                  text: '',
                  messageType: 'voice',
                  voiceFile: file,
                  durationSeconds: seconds,
                );
              },
              onSlashAiTrigger: () {
                AiChatCommandTrigger.showCommandMenu(
                  context: context,
                  buildTranscript:
                      (maxMessages) => GroupChatTranscriptBuilder.fromMessages(
                        messages: _cubit.cachedMessages,
                        currentUserId: _cubit.currentUserId,
                        maxMessages: maxMessages,
                      ),
                );
              },
              onRecordingStart: () {
                if (_cubit.searchController.isActive.value) {
                  _cubit.searchController.deactivate();
                }
                _cubit.startRecordingAction();
              },
              onRecordingPause: () => _cubit.pauseRecordingAction(),
              onRecordingResume: () => _cubit.resumeRecordingAction(),
              onRecordingStop: () => _cubit.stopRecordingAction(),
              onRecordingCancel: () => _cubit.cancelRecordingAction(),
            );
          },
        ),
      ],
    );
  }
}
