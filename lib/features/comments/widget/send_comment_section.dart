import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/attachment/attachment_sheet/picked_attachment.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import '../../posts/model/post_model.dart';
import '../model/comment_attachment_draft.dart';
import '../model/comment_model.dart';
import 'comment_attachment_preview.dart';
import '../../../core/mentions/mentions.dart';
import 'comment_voice_recorder_sheet.dart';

class SendCommentSection extends StatefulWidget {
  final PostModel post;
  final String? replyingToCommentId;
  final String? replyingToAuthorName;
  final VoidCallback? onReplySent;
  final CommentModel? editingComment;
  final VoidCallback? onEditSaved;

  final ValueChanged<MentionTextEditingController>? onControllerReady;

  const SendCommentSection({
    super.key,
    required this.post,
    this.replyingToCommentId,
    this.replyingToAuthorName,
    this.onReplySent,
    this.editingComment,
    this.onEditSaved,
    this.onControllerReady,
  });

  @override
  State<SendCommentSection> createState() => _SendCommentSectionState();
}

class _SendCommentSectionState extends State<SendCommentSection> {
  final MentionTextEditingController _commentController =
      MentionTextEditingController();

  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      final has = _commentController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    widget.onControllerReady?.call(_commentController);
  }

  @override
  void didUpdateWidget(covariant SendCommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingComment != null &&
        widget.editingComment?.id != oldWidget.editingComment?.id) {
      _commentController.text = widget.editingComment!.text;
      _commentController.setMentions(widget.editingComment!.mentions);
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }

    if (oldWidget.editingComment != null && widget.editingComment == null) {
      _commentController.clear();
      _commentController.clearMentions();
    }

    if (widget.replyingToCommentId != null &&
        oldWidget.replyingToCommentId != widget.replyingToCommentId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _canSend(CommentsCubit cubit) =>
      _hasText || cubit.pendingAttachment != null;

  void _submitComment() {
    final cubit = context.read<CommentsCubit>();
    final textComment = _commentController.text.trim();

    if (textComment.isEmpty && cubit.pendingAttachment == null) return;

    final mentions = _commentController.validMentions;

    if (widget.editingComment != null) {
      if (textComment.isEmpty) return;
      cubit.editComment(
        commentId: widget.editingComment!.id,
        newText: textComment,
      );
      _commentController.clear();
      widget.onEditSaved?.call();
      return;
    }
    cubit.addComment(
      post: widget.post,
      commentText: textComment,
      parentCommentId: widget.replyingToCommentId,
      mentions: mentions,
    );
    _commentController.clearMentions();
    _commentController.clear();
    widget.onReplySent?.call();
  }

  Future<void> _openAttachmentPicker() async {
    final picked = await AttachmentPickerSheet.show(
      context,
      showVoiceOption: true,
      showFileOption: true,
      showCameraOption: false,
      onRecordVoice: (ctx) async {
        final draft = await showModalBottomSheet<CommentAttachmentDraft?>(
          context: ctx,
          isScrollControlled: true,
          isDismissible: false,
          backgroundColor: Colors.transparent,
          builder: (_) => const CommentVoiceRecorderSheet(),
        );
        if (draft == null) return null;
        return PickedAttachment(
          kind: AttachmentKind.voice,
          localFile: draft.localFile,
          fileName: draft.fileName,
          fileSizeBytes: draft.fileSizeBytes,
          durationSeconds: draft.durationSeconds,
        );
      },
    );
    if (picked == null || !mounted) return;

    context.read<CommentsCubit>().stageAttachment(
      CommentAttachmentDraft(
        type: _mapKindToCommentType(picked.kind),
        localFile: picked.localFile,
        remoteUrl: picked.remoteUrl,
        fileName: picked.fileName,
        fileSizeBytes: picked.fileSizeBytes,
        durationSeconds: picked.durationSeconds,
      ),
    );
  }

  CommentType _mapKindToCommentType(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => CommentType.image,
    AttachmentKind.video => CommentType.video,
    AttachmentKind.file => CommentType.file,
    AttachmentKind.voice => CommentType.voice,
    AttachmentKind.gif => CommentType.gif,
    AttachmentKind.sticker => CommentType.sticker,
  };

  @override
  Widget build(BuildContext context) {
    final isReplying = widget.replyingToCommentId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CommentAttachmentPreview(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: BlocConsumer<CommentsCubit, CommentsState>(
                listener: (context, state) {
                  if (state is CommentOptimisticAdded) {
                    _commentController.clear();
                  }
                  if (state is CommentError && !state.isConnectivityError) {
                    AppToast.error(state.message);
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<CommentsCubit>();
                  final isLoading = state is AddingComment || cubit.isUploading;
                  final isStickerOnly =
                      cubit.pendingAttachment?.type == CommentType.sticker;
                  final canSend = _canSend(cubit);
                  final pendingMedia = cubit.pendingAttachment;
                  final isMediaCaptionable =
                      pendingMedia?.type == CommentType.image ||
                      pendingMedia?.type == CommentType.video;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: isLoading ? null : _openAttachmentPicker,
                          child: Image.asset(
                            AppImages.attachmentIcon,
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 2),
                          ),
                        ),
                        const Gap(5),
                        Expanded(
                          child: MentionAwareTextField(
                            controller: _commentController,
                            focusNode: _focusNode,
                            enabled: !isLoading && !isStickerOnly,
                            hintText:
                                isStickerOnly
                                    ? 'Sticker ready to send'
                                    : isReplying
                                    ? 'Reply to @${widget.replyingToAuthorName}...'
                                    : 'Write a comment...',
                            onSubmitted: (_) => _submitComment(),
                            trailingIcon: AiActionIcon(
                              controller: _commentController,
                              surface: AiSurfaceType.comment,
                              generationAction: AiActionType.replySuggestion,
                              hasMediaAttached: isMediaCaptionable,
                              hasReplyContext: isReplying,
                              imageBytesProvider:
                                  pendingMedia?.type == CommentType.image &&
                                          pendingMedia?.localFile != null
                                      ? () =>
                                          pendingMedia!.localFile!.readAsBytes()
                                      : null,
                              replyToAuthorName: widget.replyingToAuthorName,
                              parentContentText: widget.post.text,
                            ),
                          ),
                        ),
                        const Gap(8),
                        isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CustomLoadingIndicator(),
                            )
                            : InkWell(
                              onTap: canSend ? _submitComment : null,
                              child: Image.asset(
                                AppImages.sendIcon,
                                width: 24,
                                height: 24,
                                color:
                                    canSend
                                        ? Theme.of(context).primaryColor
                                        : AppColors.grey5,
                              ),
                            ),
                        const Gap(2),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
