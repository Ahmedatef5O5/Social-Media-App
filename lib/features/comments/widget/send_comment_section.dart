import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/widget/comment_attachment_picker_sheet.dart';
import 'package:social_media_app/features/comments/widget/comment_attachment_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../posts/model/post_model.dart';
import '../model/comment_type.dart';

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
  final TextEditingController _commentController = TextEditingController();

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

    cubit.addComment(
      post: widget.post,
      commentText: textComment,
      parentCommentId: widget.replyingToCommentId,
    );
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
    final theme = Theme.of(context);
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
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const Gap(5),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            enabled: !isLoading && !isStickerOnly,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _submitComment(),

                            decoration: InputDecoration(
                              hintText:
                                  isStickerOnly
                                      ? 'Sticker ready to send'
                                      : isReplying
                                      ? 'Reply to @${widget.replyingToAuthorName}...'
                                      : 'Write a comment...',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.grey5,
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor: theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 1.6,
                                ),
                              ),
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
