import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../posts/model/post_model.dart';
import 'comment_attachment_picker_sheet.dart';
import 'comment_attachment_preview.dart';
import '../../../core/mentions/mentions.dart';

class SendCommentSection extends StatefulWidget {
  final PostModel post;
  final String? replyingToCommentId;
  final String? replyingToAuthorName;
  final VoidCallback? onReplySent;

  const SendCommentSection({
    super.key,
    required this.post,
    this.replyingToCommentId,
    this.replyingToAuthorName,
    this.onReplySent,
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
  }

  @override
  void didUpdateWidget(SendCommentSection old) {
    super.didUpdateWidget(old);
    // When a reply target is set, focus the field automatically
    if (widget.replyingToCommentId != null &&
        old.replyingToCommentId != widget.replyingToCommentId) {
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

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final mentions = _commentController.validMentions;

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
    final draft = await CommentAttachmentPickerSheet.show(context);
    if (draft != null && mounted) {
      context.read<CommentsCubit>().stageAttachment(draft);
    }
  }

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<CommentsCubit>();
                  final isLoading = state is AddingComment || cubit.isUploading;
                  final isStickerOnly =
                      cubit.pendingAttachment?.type == CommentType.sticker;
                  final canSend = _canSend(cubit);

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
