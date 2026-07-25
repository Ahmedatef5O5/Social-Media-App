import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import 'package:social_media_app/features/group_chats/widgets/group_input_bar.dart';
import 'package:social_media_app/features/group_chats/widgets/group_media_preview_screen.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
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

  List<String>? _membersIds;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<GroupDetailsCubit>();
    widget.controller.addListener(_onTextChanged);
    _cubit.editingMessage.addListener(_onEditingMessageChanged);
    _loadMemberIds();
  }

  void _onTextChanged() {
    final notEmpty = widget.controller.text.trim().isNotEmpty;
    if (notEmpty != _hasText) setState(() => _hasText = notEmpty);
    if (notEmpty) widget.onTyping();
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
    final editing = _cubit.editingMessage.value;
    if (editing != null) {
      _cubit.editMessage(
        messageId: editing.id,
        newText: text,
        mentions: mentions,
      );
      _cubit.editingMessage.value = null;
    } else {
      widget.onSend(text, mentions);
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
    } catch (_) {}
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
                          caption: caption,
                        ),
                  ),
                ),
          ),
        );
        break;

      case AttachmentKind.file:
        if (picked.localFile == null) return;
        cubit.sendMessage(
          text: '',
          messageType: 'file',
          documentFile: picked.localFile,
          fileName: picked.fileName,
          fileSizeBytes: picked.fileSizeBytes,
        );
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

        GroupInputBar(
          hasText: _hasText,
          controller: widget.controller,
          focusNode: _focusNode,
          mentionCandidateIds: _membersIds,
          onTyping: widget.onTyping,
          onSend: _handleSend,
          onShowMedia: _openAttachmentSheet,
          onSendVoice: (file, seconds) {
            context.read<GroupDetailsCubit>().sendMessage(
              text: '',
              messageType: 'voice',
              voiceFile: file,
            );
          },
        ),
      ],
    );
  }
}
