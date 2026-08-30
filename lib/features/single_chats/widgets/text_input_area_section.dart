import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/audio/voice_recorder/widgets/voice_recorder_input_section.dart';
import '../../../core/chat_shared/widgets/chat_staged_file_preview.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/directional_text_field.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/helpers/remote_media_fetcher.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import '../../ai_assistant/widgets/ai_chat_command_trigger.dart';
import '../helpers/chat_transcript_builder.dart';
import '../cubits/chat_details_cubit/chat_details_cubit.dart';
import '../helpers/edit_preview_bar.dart';
import '../helpers/reply_preview_bar.dart';
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
  File? _stagedDocument;
  String? _stagedFileName;
  int? _stagedFileSizeBytes;
  bool _isSending = false;

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
    final text = widget.messageController.text;

    if (text.trim().toLowerCase() == AiChatCommandTrigger.trigger) {
      widget.messageController.clear();
      final cubit = context.read<ChatDetailsCubit>();
      AiChatCommandTrigger.showCommandMenu(
        context: context,
        buildTranscript:
            (maxMessages) => ChatTranscriptBuilder.fromMessages(
              messages: cubit.cachedMessages,
              currentUserId: cubit.currentUserId,
              otherUserName: widget.receiverUser.name,
              maxMessages: maxMessages,
            ),
      );
      return;
    }

    final notEmpty = text.trim().isNotEmpty || _stagedDocument != null;
    if (notEmpty != _isTextNotEmpty) setState(() => _isTextNotEmpty = notEmpty);

    final cubit = context.read<ChatDetailsCubit>();
    if (notEmpty) {
      cubit.onUserTyping(widget.receiverUser.id);
      if (cubit.searchController.isActive.value) {
        cubit.searchController.deactivate();
      }
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
    } catch (e) {
      debugPrint('[TextInputArea] failed to send stopTyping on dispose: $e');
    }
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

        if (_stagedDocument != null)
          ChatStagedFilePreview(
            file: _stagedDocument,
            fileName: _stagedFileName ?? 'File',
            fileSizeBytes: _stagedFileSizeBytes ?? 0,
            onRemove: () {
              setState(() {
                _stagedDocument = null;
                _stagedFileName = null;
                _stagedFileSizeBytes = null;
                _isTextNotEmpty =
                    widget.messageController.text.trim().isNotEmpty;
              });
            },
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
                textField: DirectionalTextField(
                  controller: widget.messageController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  cursorColor: Colors.blueGrey.shade400,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hoverColor: AppColors.white,
                    hintText: 'Type a message...',
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    suffixIcon: AiActionIcon(
                      controller: widget.messageController,
                      surface: AiSurfaceType.chatMessage,
                      generationAction: AiActionType.replySuggestion,
                      actionContext: AiActionContext.chatReply,
                      hasReplyContext: widget.replyTo != null,
                      targetText:
                          (widget.replyTo == null ||
                                  widget.replyTo!.messageType == 'text')
                              ? widget.replyTo?.text
                              : null,
                      mediaCaption:
                          (widget.replyTo != null &&
                                  widget.replyTo!.messageType != 'text')
                              ? widget.replyTo!.caption
                              : null,
                      targetMediaType: AiTargetMediaType.fromWireMessageType(
                        widget.replyTo?.messageType,
                      ),
                      targetImageBytesProvider:
                          (widget.replyTo != null &&
                                  widget.replyTo!.messageType == 'image' &&
                                  widget.replyTo!.imageUrl != null)
                              ? () => RemoteMediaFetcher.fetchBytes(
                                widget.replyTo!.imageUrl!,
                              )
                              : null,
                    ),
                  ),
                ),
                hasText: _isTextNotEmpty,
                onShowAttachments: () => _openAttachmentSheet(context),
                sendButton: InkWell(
                  splashColor: AppColors.transparent,
                  onTap: () {
                    if (_isSending) return;
                    if (widget.editingMessage != null) {
                      final text = widget.messageController.text.trim();
                      if (text.isEmpty) return;
                      _isSending = true;
                      context.read<ChatDetailsCubit>().editMessage(
                        messageId: widget.editingMessage!.id,
                        newText: text,
                      );
                      widget.messageController.clear();
                      widget.onEditCancelled?.call();
                      _isSending = false;
                      return;
                    }
                    final text = widget.messageController.text.trim();
                    if (_stagedDocument != null) {
                      _isSending = true;
                      final docToSend = _stagedDocument!;
                      final nameToSend = _stagedFileName;
                      final sizeToSend = _stagedFileSizeBytes;
                      setState(() {
                        _stagedDocument = null;
                        _stagedFileName = null;
                        _stagedFileSizeBytes = null;
                        _isTextNotEmpty = false;
                      });
                      widget.messageController.clear();
                      context.read<ChatDetailsCubit>().stopTyping(
                        widget.receiverUser.id,
                      );
                      widget.onCancelReply?.call();
                      context.read<ChatDetailsCubit>().sendMessage(
                        receiverId: widget.receiverUser.id,
                        messageText: '',
                        messageType: 'file',
                        documentFile: docToSend,
                        fileName: nameToSend,
                        fileSizeBytes: sizeToSend,
                        caption: text.isNotEmpty ? text : null,
                        replyTo: widget.replyTo,
                      );
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) _isSending = false;
                      });
                      return;
                    }
                    if (text.isNotEmpty) {
                      _isSending = true;
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
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) _isSending = false;
                      });
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
                    durationSeconds: seconds,
                    replyTo: widget.replyTo,
                  );
                  widget.onCancelReply?.call();
                },
                onRecordingStart: () {
                  final cubit = context.read<ChatDetailsCubit>();
                  if (cubit.searchController.isActive.value) {
                    cubit.searchController.deactivate();
                  }
                  cubit.startRecordingAction(widget.receiverUser.id);
                },
                onRecordingPause:
                    () => context.read<ChatDetailsCubit>().pauseRecordingAction(
                      widget.receiverUser.id,
                    ),
                onRecordingResume:
                    () => context
                        .read<ChatDetailsCubit>()
                        .resumeRecordingAction(widget.receiverUser.id),
                onRecordingStop:
                    () => context.read<ChatDetailsCubit>().stopRecordingAction(
                      widget.receiverUser.id,
                    ),
                onRecordingCancel:
                    () => context
                        .read<ChatDetailsCubit>()
                        .cancelRecordingAction(widget.receiverUser.id),
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
                          fileSizeBytes: picked.fileSizeBytes,
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
                          fileSizeBytes: picked.fileSizeBytes,
                          durationSeconds: picked.durationSeconds,
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
        setState(() {
          _stagedDocument = picked.localFile;
          _stagedFileName = picked.fileName;
          _stagedFileSizeBytes = picked.fileSizeBytes;
          _isTextNotEmpty = true;
        });
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
