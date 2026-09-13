import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/core/widgets/directional_text_field.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/attachment/attachment_sheet/picked_attachment.dart';
import '../../../core/toast/app_toast.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/helpers/remote_media_fetcher.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';
import '../cubits/story_reply_cubit/story_reply_cubit.dart';
import '../helpers/story_reaction_btn.dart';
import '../models/story_model.dart';

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

  File? _pickedFile;
  String? _pickedType;
  String? _remoteMediaUrl;
  String? _pickedFileName;
  int? _pickedFileSizeBytes;
  bool _isAiGenerating = false;

  bool get _hasContent =>
      _controller.text.trim().isNotEmpty ||
      _pickedFile != null ||
      _remoteMediaUrl != null;

  String get _fileExtension {
    if (_pickedFileName == null) return '';
    final dot = _pickedFileName!.lastIndexOf('.');
    if (dot == -1 || dot == _pickedFileName!.length - 1) return '';
    return _pickedFileName!.substring(dot + 1).toUpperCase();
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  void _handlePickedAttachment(PickedAttachment attachment) {
    widget.onComposingStart();
    setState(() {
      switch (attachment.kind) {
        case AttachmentKind.image:
          _pickedFile = attachment.localFile;
          _remoteMediaUrl = null;
          _pickedType = 'image';
          _pickedFileName = attachment.fileName ?? 'Photo';
          _pickedFileSizeBytes = attachment.fileSizeBytes;
          break;
        case AttachmentKind.video:
          _pickedFile = attachment.localFile;
          _remoteMediaUrl = null;
          _pickedType = 'video';
          _pickedFileName = attachment.fileName ?? 'Video';
          _pickedFileSizeBytes = attachment.fileSizeBytes;
          break;
        case AttachmentKind.gif:
          _pickedFile = null;
          _remoteMediaUrl = attachment.remoteUrl;
          _pickedType = 'gif';
          _pickedFileName = 'GIF';
          _pickedFileSizeBytes = null;
          break;
        case AttachmentKind.sticker:
          _pickedFile = null;
          _remoteMediaUrl = attachment.remoteUrl;
          _pickedType = 'sticker';
          _pickedFileName = 'Sticker';
          _pickedFileSizeBytes = null;
          break;
        default:
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onComposingStart();
      } else if (!_hasContent) {
        widget.onComposingEnd();
      }
      if (mounted) setState(() {});
    });
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _removePickedMedia() {
    setState(() {
      _pickedFile = null;
      _remoteMediaUrl = null;
      _pickedType = null;
      _pickedFileName = null;
      _pickedFileSizeBytes = null;
    });
    if (!_hasContent && !_focusNode.hasFocus) {
      widget.onComposingEnd();
    }
  }

  void _openMediaPreview() {
    if (_pickedFile == null && _remoteMediaUrl == null) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder:
            (_) => FullScreenMediaView(
              imageUrl:
                  _pickedType == 'image' ? _pickedFile!.path : _remoteMediaUrl,
              videoUrl: _pickedType == 'video' ? _pickedFile!.path : null,
              isLocal: _pickedFile != null,
              showActions: false,
            ),
      ),
    );
  }

  Future<void> _showAttachSheet() async {
    widget.onComposingStart();

    // Reusing the exact attachment bottom sheet from chats
    final attachment = await AttachmentPickerSheet.show(
      context,
      showVoiceOption: false,
      showFileOption: false,
      showVideoOption: false,
      showCameraOption: false,
      showGifOption: true,
      showStickerOption: true,
    );

    if (attachment == null || !mounted) {
      if (!_hasContent && !_focusNode.hasFocus) {
        widget.onComposingEnd();
      }
      return;
    }

    _handlePickedAttachment(attachment);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pickedFile == null && _remoteMediaUrl == null) return;

    await context.read<StoryReplyCubit>().sendReply(
      story: widget.story,
      text: text,
      mediaFile: _pickedFile,
      mediaMessageType: _pickedType,
      remoteMediaUrl: _remoteMediaUrl,
      fileSizeBytes: _pickedFileSizeBytes,
      fileName: _pickedFileName,
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
            _remoteMediaUrl = null;
            _pickedType = null;
            _pickedFileName = null;
            _pickedFileSizeBytes = null;
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
              if (_pickedFile != null || _remoteMediaUrl != null)
                _buildStagedMediaPreview(),
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
    const double barHeight = 44.0;

    return Container(
      constraints: const BoxConstraints(minHeight: barHeight, maxHeight: 96),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(barHeight / 2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Attachment Button aligned perfectly in center
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(
              minWidth: 38,
              minHeight: barHeight,
            ),
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.white,
              size: 21,
            ),
            onPressed: isSending ? null : _showAttachSheet,
          ),

          // Text Field Centered Vertically
          Expanded(
            child: DirectionalTextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isSending,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              minLines: 1,
              maxLines: 4,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                hintText: "Reply to ${widget.story.authorName}'s story…",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:
                      (_focusNode.hasFocus || _isAiGenerating)
                          ? AiActionIcon(
                            key: const ValueKey('story_ai_icon'),
                            controller: _controller,
                            surface: AiSurfaceType.story,
                            generationAction: AiActionType.replySuggestion,
                            actionContext: AiActionContext.storyReply,
                            hasReplyContext: true,
                            targetText:
                                widget.story.storyType == StoryType.text
                                    ? widget.story.contentText
                                    : null,
                            mediaCaption:
                                widget.story.storyType == StoryType.text
                                    ? null
                                    : widget.story.caption,
                            targetMediaType: switch (widget.story.storyType) {
                              StoryType.text => AiTargetMediaType.text,
                              StoryType.image => AiTargetMediaType.image,
                              StoryType.video => AiTargetMediaType.video,
                            },
                            targetUserName: widget.story.authorName,
                            targetImageBytesProvider:
                                widget.story.storyType == StoryType.image &&
                                        widget.story.imageUrl != null
                                    ? () => RemoteMediaFetcher.fetchBytes(
                                      widget.story.imageUrl!,
                                    )
                                    : null,
                            onGeneratingChanged: (generating) {
                              if (mounted) {
                                setState(() => _isAiGenerating = generating);
                              }
                            },
                          )
                          : const SizedBox.shrink(
                            key: ValueKey('story_ai_icon_hidden'),
                          ),
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
      radius: 22, // 22 radius = 44 diameter matching input field exactly
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
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: canSend ? _send : null,
              ),
    );
  }

  Widget _buildStagedMediaPreview() {
    final isRemote = _remoteMediaUrl != null;
    final isVideo = _pickedType == 'video';
    final ext = _fileExtension;
    final size = _formatFileSize(_pickedFileSizeBytes);
    final subtitle =
        _pickedType == 'gif'
            ? 'GIF Animation'
            : _pickedType == 'sticker'
            ? 'Sticker'
            : (ext.isNotEmpty && size.isNotEmpty)
            ? '$ext · $size'
            : size.isNotEmpty
            ? size
            : (isVideo ? 'Video' : 'Photo');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _openMediaPreview,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 40,
                height: 40,
                child:
                    isRemote
                        ? Image.network(
                          _remoteMediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                        )
                        : (isVideo
                            ? Container(
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white70,
                                size: 22,
                              ),
                            )
                            : Image.file(_pickedFile!, fit: BoxFit.cover)),
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _pickedFileName ??
                      (_pickedType?.toUpperCase() ?? 'Attachment'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _removePickedMedia,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 18, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
