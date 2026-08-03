import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/services/file_picker_services.dart';
import '../../../core/toast/app_toast.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';
import '../cubit/story_reply_cubit/story_reply_cubit.dart';
import '../helpers/story_reaction_btn.dart';
import '../model/story_model.dart';

class StoryReplyInputBar extends StatefulWidget {
  final StoryModel story;
  final VoidCallback onComposingStart;
  final VoidCallback onComposingEnd;
  final VoidCallback onSent;

  const StoryReplyInputBar({
    super.key,
    required this.story,
    required this.onComposingStart,
    required this.onComposingEnd,
    required this.onSent,
  });

  @override
  State<StoryReplyInputBar> createState() => _StoryReplyInputBarState();
}

class _StoryReplyInputBarState extends State<StoryReplyInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _filePicker = FilePickerServices();

  File? _pickedFile;
  String? _pickedType;

  bool get _hasContent =>
      _controller.text.trim().isNotEmpty || _pickedFile != null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onComposingStart();
      } else if (!_hasContent) {
        widget.onComposingEnd();
      }
    });
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool isVideo}) async {
    widget.onComposingStart();
    final picked =
        isVideo
            ? await _filePicker.pickVideoFromGallery()
            : await _filePicker.pickImageFromGallery();
    if (picked == null) return;
    setState(() {
      _pickedFile = File(picked.path);
      _pickedType = isVideo ? 'video' : 'image';
    });
  }

  void _removePickedMedia() {
    setState(() {
      _pickedFile = null;
      _pickedType = null;
    });
  }

  void _openMediaPreview() {
    if (_pickedFile == null) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder:
            (_) => FullScreenMediaView(
              imageUrl: _pickedType == 'image' ? _pickedFile!.path : null,
              videoUrl: _pickedType == 'video' ? _pickedFile!.path : null,
              isLocal: true,
              showActions: false,
            ),
      ),
    );
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Photo',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(isVideo: false);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.videocam, color: Colors.white),
                    title: const Text(
                      'Video',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(isVideo: true);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pickedFile == null) return;

    await context.read<StoryReplyCubit>().sendReply(
      story: widget.story,
      text: text,
      mediaFile: _pickedFile,
      mediaMessageType: _pickedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoryReplyCubit, StoryReplyState>(
      listener: (context, state) {
        if (state is StoryReplySent) {
          _controller.clear();
          setState(() {
            _pickedFile = null;
            _pickedType = null;
          });
          _focusNode.unfocus();
          widget.onComposingEnd();
          widget.onSent();
          context.read<StoryReplyCubit>().reset();
        } else if (state is StoryReplyFailed) {
          AppToast.error('Failed to send reply: ${state.message}');
          context.read<StoryReplyCubit>().reset();
        }
      },
      builder: (context, state) {
        final isSending = state is StoryReplySending;

        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_pickedFile != null) _buildMediaChip(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _buildTextField(isSending)),
                  const Gap(8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder:
                        (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child:
                        _hasContent
                            ? _buildSendButton(isSending)
                            : StoryReactionButton(
                              key: const ValueKey('react_button'),
                              onOpen: widget.onComposingStart,
                              onClose: () {
                                if (!_hasContent && !_focusNode.hasFocus) {
                                  widget.onComposingEnd();
                                }
                              },
                            ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(bool isSending) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 96, minHeight: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.white,
              size: 20,
            ),
            onPressed: isSending ? null : _showAttachSheet,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isSending,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: "Reply to ${widget.story.authorName}'s story…",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                suffixIcon: AiActionIcon(
                  controller: _controller,
                  surface: AiSurfaceType.chatMessage,
                  generationAction: AiActionType.replySuggestion,
                  hasReplyContext: true,
                  replyToText:
                      widget.story.storyType == StoryType.text
                          ? widget.story.contentText
                          : widget.story.caption,
                  replyToAuthorName: widget.story.authorName,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(bool isSending) {
    final canSend = _hasContent;
    return CircleAvatar(
      key: const ValueKey('send_button'),
      radius: 24,
      backgroundColor:
          canSend ? Theme.of(context).primaryColor : Colors.white24,
      child:
          isSending
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CustomLoadingIndicator(color: Colors.white),
              )
              : IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 24),
                onPressed: canSend ? _send : null,
              ),
    );
  }

  Widget _buildMediaChip() {
    final isVideo = _pickedType == 'video';
    return GestureDetector(
      onTap: _openMediaPreview,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  isVideo
                      ? Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey.shade800,
                        child: const Icon(
                          Icons.videocam,
                          color: Colors.white70,
                        ),
                      )
                      : Image.file(
                        _pickedFile!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
            ),
            const Gap(8),
            Text(
              isVideo ? 'Video • tap to preview' : 'Photo • tap to preview',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Gap(6),
            GestureDetector(
              onTap: _removePickedMedia,
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
