import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/audio/voice_recorder/widgets/voice_recorder_input_section.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../helper/edit_preview_bar.dart';
import '../helper/reply_preview_bar.dart';
import '../models/chat_user_model.dart';
import '../models/message_model.dart';
import '../views/media_preview_screen.dart';

class TextInputAreaSection extends StatefulWidget {
  final TextEditingController messageController;
  final ChatUserModel receiverUser;
  final MessageModel? replyTo;
  final MessageModel? editingMessage;
  final VoidCallback? onCancelReply;
  final VoidCallback? onEditCancelled;

  const TextInputAreaSection({
    super.key,
    required this.messageController,
    required this.receiverUser,
    this.replyTo,
    this.editingMessage,
    this.onCancelReply,
    this.onEditCancelled,
  });

  @override
  State<TextInputAreaSection> createState() => _TextInputAreaSectionState();
}

class _TextInputAreaSectionState extends State<TextInputAreaSection> {
  final FocusNode _focusNode = FocusNode();
  bool _isTextNotEmpty = false;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant TextInputAreaSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.editingMessage != null &&
        widget.editingMessage?.id != oldWidget.editingMessage?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }

    if (widget.replyTo != null && oldWidget.replyTo != widget.replyTo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _onTextChanged() {
    final notEmpty = widget.messageController.text.trim().isNotEmpty;
    if (notEmpty != _isTextNotEmpty) setState(() => _isTextNotEmpty = notEmpty);
    final cubit = context.read<ChatDetailsCubit>();
    if (notEmpty) {
      cubit.onUserTyping(widget.receiverUser.id);
    } else {
      cubit.stopTyping(widget.receiverUser.id);
    }
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    _focusNode.dispose();
    try {
      context.read<ChatDetailsCubit>().stopTyping(widget.receiverUser.id);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.editingMessage != null)
          EditPreviewBar(
            editingMessage: widget.editingMessage!,
            onCancel: widget.onEditCancelled ?? () {},
          ),

        if (widget.replyTo != null)
          ReplyPreviewBar(
            replyTo: widget.replyTo!,
            isMe:
                widget.replyTo!.senderId ==
                context.read<ChatDetailsCubit>().currentUserId,
            senderName:
                widget.replyTo!.senderId ==
                        context.read<ChatDetailsCubit>().currentUserId
                    ? 'You'
                    : widget.receiverUser.name,
            onCancel: widget.onCancelReply ?? () {},
          ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: const BoxDecoration(color: AppColors.transparent),
          child: Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 3),
            child: SafeArea(
              top: false,
              bottom: true,
              child: VoiceRecorderInputSection(
                textField: TextField(
                  controller: widget.messageController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  cursorColor: Colors.blueGrey.shade400,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hoverColor: AppColors.white,
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                  ),
                ),
                hasText: _isTextNotEmpty,
                onShowAttachments: () => _openAttachmentSheet(context),
                sendButton: InkWell(
                  splashColor: AppColors.transparent,
                  onTap: () {
                    if (widget.editingMessage != null) {
                      final text = widget.messageController.text.trim();
                      if (text.isEmpty) return;
                      context.read<ChatDetailsCubit>().editMessage(
                        messageId: widget.editingMessage!.id,
                        newText: text,
                      );
                      widget.messageController.clear();
                      widget.onEditCancelled?.call();
                      return;
                    }
                    final text = widget.messageController.text.trim();
                    if (text.isNotEmpty) {
                      context.read<ChatDetailsCubit>().sendMessage(
                        receiverId: widget.receiverUser.id,
                        messageText: text,
                        replyTo: widget.replyTo,
                      );
                      widget.messageController.clear();
                      context.read<ChatDetailsCubit>().stopTyping(
                        widget.receiverUser.id,
                      );
                      widget.onCancelReply?.call();
                    }
                  },
                  child: Image.asset(
                    AppImages.sendIcon,
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.95),
                    width: 28,
                    height: 28,
                  ),
                ),
                onSendVoice: (file, seconds) {
                  context.read<ChatDetailsCubit>().sendMessage(
                    receiverId: widget.receiverUser.id,
                    messageText: '',
                    messageType: 'voice',
                    voiceFile: file,
                    voiceDurationSeconds: seconds,
                    replyTo: widget.replyTo,
                  );
                  widget.onCancelReply?.call();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAttachmentSheet(BuildContext context) async {
    final picked = await AttachmentPickerSheet.show(
      context,
      showVoiceOption: false,
      showFileOption: true,
      showCameraOption: true,
    );
    if (picked == null || !mounted) return;
    if (!context.mounted) return;
    final chatCubit = context.read<ChatDetailsCubit>();

    switch (picked.kind) {
      case AttachmentKind.image:
        if (picked.localFile == null) return;
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BlocProvider.value(
                  value: chatCubit,
                  child: MediaPreviewScreen(
                    file: picked.localFile!,
                    type: 'image',
                    onSend:
                        (caption) => chatCubit.sendMessage(
                          receiverId: widget.receiverUser.id,
                          messageText: '',
                          messageType: 'image',
                          imageFile: picked.localFile,
                          caption: caption,
                          replyTo: widget.replyTo,
                        ),
                  ),
                ),
          ),
        );
        widget.onCancelReply?.call();
        break;

      case AttachmentKind.video:
        if (picked.localFile == null) return;
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BlocProvider.value(
                  value: chatCubit,
                  child: MediaPreviewScreen(
                    file: picked.localFile!,
                    type: 'video',
                    onSend:
                        (caption) => chatCubit.sendMessage(
                          receiverId: widget.receiverUser.id,
                          messageText: '',
                          messageType: 'video',
                          videoFile: picked.localFile,
                          caption: caption,
                          replyTo: widget.replyTo,
                        ),
                  ),
                ),
          ),
        );
        widget.onCancelReply?.call();
        break;

      case AttachmentKind.file:
        if (picked.localFile == null) return;
        chatCubit.sendMessage(
          receiverId: widget.receiverUser.id,
          messageText: '',
          messageType: 'file',
          documentFile: picked.localFile,
          fileName: picked.fileName,
          fileSizeBytes: picked.fileSizeBytes,
          replyTo: widget.replyTo,
        );
        widget.onCancelReply?.call();
        break;

      case AttachmentKind.gif:
        chatCubit.sendMessage(
          receiverId: widget.receiverUser.id,
          messageText: '',
          messageType: 'gif',
          remoteImageUrl: picked.remoteUrl,
          replyTo: widget.replyTo,
        );
        widget.onCancelReply?.call();
        break;

      case AttachmentKind.sticker:
        chatCubit.sendMessage(
          receiverId: widget.receiverUser.id,
          messageText: '',
          messageType: 'sticker',
          remoteImageUrl: picked.remoteUrl,
          replyTo: widget.replyTo,
        );
        widget.onCancelReply?.call();
        break;

      case AttachmentKind.voice:
        break;
    }
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
