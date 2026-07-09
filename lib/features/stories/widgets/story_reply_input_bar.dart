import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/services/file_picker_services.dart';
import '../cubit/story_reply_cubit/story_reply_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onComposingStart();
      } else if (_controller.text.trim().isEmpty && _pickedFile == null) {
        widget.onComposingEnd();
      }
    });
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send reply: ${state.message}')),
          );
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
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
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
                                hintText:
                                    "Reply to ${widget.story.authorName}'s story…",
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final canSend =
                          value.text.trim().isNotEmpty || _pickedFile != null;
                      return CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            canSend
                                ? Theme.of(context).primaryColor
                                : Colors.white24,
                        child:
                            isSending
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: canSend ? _send : null,
                                ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaChip() {
    final isVideo = _pickedType == 'video';
    return Container(
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
                      child: const Icon(Icons.videocam, color: Colors.white70),
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
            isVideo ? 'Video attached' : 'Photo attached',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Gap(6),
          GestureDetector(
            onTap: _removePickedMedia,
            child: const Icon(Icons.close, color: Colors.white70, size: 16),
          ),
        ],
      ),
    );
  }
}
