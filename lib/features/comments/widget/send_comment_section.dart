import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/models/post_model.dart';

class SendCommentSection extends StatefulWidget {
  final PostModel post;

  /// When set the comment is sent as a reply to this comment
  final String? replyingToCommentId;
  final String? replyingToAuthorName;

  /// Called after a reply is successfully dispatched so parent can clear state
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

  void _submitComment() {
    final textComment = _commentController.text.trim();
    if (textComment.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (textComment.isNotEmpty) {
      context.read<CommentsCubit>().addComment(
        post: widget.post,
        commentText: textComment,
        parentCommentId: widget.replyingToCommentId,
      );
      _commentController.clear();
      widget.onReplySent?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReplying = widget.replyingToCommentId != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,

      children: [
        Expanded(
          child: BlocConsumer<CommentsCubit, CommentsState>(
            listener: (context, state) {
              if (state is CommentOptimisticAdded) {
                _commentController.clear();
              }
              if (state is CommentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AddingComment;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {},
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
                        enabled: !isLoading,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _submitComment(),

                        decoration: InputDecoration(
                          hintText:
                              isReplying
                                  ? 'Reply to @${widget.replyingToAuthorName}...'
                                  : 'Write a comment...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey5,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          suffixIcon: InkWell(
                            splashColor: AppColors.transparent,
                            onTap: () {},
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          // fillColor: Colors.grey[100],
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
                        ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CustomLoadingIndicator(),
                        )
                        : InkWell(
                          onTap: () {
                            _submitComment();
                          },
                          child: Image.asset(
                            AppImages.sendIcon,
                            width: 24,
                            height: 24,
                            color: Theme.of(context).primaryColor,
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
    );
  }
}
