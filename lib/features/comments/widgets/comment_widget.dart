import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/comments/cubits/comments_cubit.dart';
import 'package:social_media_app/features/comments/helpers/comment_menu_action.dart';
import 'package:social_media_app/features/comments/models/comment_model.dart';
import 'package:social_media_app/features/comments/widgets/comment_media_bubble.dart';
import 'package:social_media_app/features/comments/widgets/comment_reaction_summary.dart';
import 'package:social_media_app/features/comments/widgets/comment_reactions_bottom_sheet.dart';
import 'package:social_media_app/features/comments/widgets/thread_painter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/link/widgets/message_link_preview.dart';
import '../../../core/mentions/mentions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../models/comment_type.dart';
import 'comment_constants.dart';
import 'comment_avatar.dart';
import 'comment_action_chip.dart';
import 'comment_overlay_picker.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';

class CommentWidget extends StatefulWidget {
  final CommentModel comment;
  final String postId;
  final String postAuthorId;
  final int depth;
  final void Function(String commentId, String authorName)? onReplyTap;
  final GlobalKey? lastAvatarKey;
  final void Function(CommentModel)? onEditTap;
  final String? highlightCommentId;
  final GlobalKey? highlightKey;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.postId,
    required this.postAuthorId,
    this.depth = 0,
    this.onReplyTap,
    this.lastAvatarKey,
    this.onEditTap,
    this.highlightCommentId,
    this.highlightKey,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget>
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final GlobalKey _reactionKey = GlobalKey();

  late final AnimationController _stemController;
  late final Animation<double> _anim;

  late final AnimationController _highlightController;
  late final Animation<double> _highlightAnim;

  final GlobalKey _lastReplyAvatarKey = GlobalKey();
  double? _stemEndY;

  @override
  void initState() {
    super.initState();
    _stemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = CurvedAnimation(
      parent: _stemController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 900),
    );
    _highlightAnim = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    if (widget.comment.id == widget.highlightCommentId) {
      _playHighlight();
    }
  }

  /// Plays a one-shot "flash" on the comment's background: a quick fade in,
  /// a short hold so it's actually noticeable, then a slower fade back to
  /// nothing. Triggered once per highlight event — see [didUpdateWidget].
  Future<void> _playHighlight() async {
    if (!mounted) return;
    await _highlightController.forward(from: 0);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    await _highlightController.reverse();
  }

  @override
  void didUpdateWidget(covariant CommentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool justHighlighted =
        widget.comment.id == widget.highlightCommentId &&
        oldWidget.highlightCommentId != widget.comment.id;
    if (justHighlighted) _playHighlight();
  }

  void _showPicker() {
    if (_overlayEntry != null) return;

    final renderBox =
        _reactionKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final currentUserId = SupabaseProvider.id;
    final isMyComment = widget.comment.authorId == currentUserId;
    final isPostAuthor = widget.postAuthorId == currentUserId;
    final canDelete = isMyComment || isPostAuthor;

    final actions = <CommentMenuAction>[
      if (isMyComment)
        CommentMenuAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: () {
            _dismissPicker();
            widget.onEditTap?.call(widget.comment);
          },
        ),

      if (canDelete)
        CommentMenuAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: Colors.red,
          onTap: () {
            _dismissPicker();
            _confirmDelete(context);
          },
        ),
    ];

    _overlayEntry = CommentOverlayPicker.create(
      context: context,
      anchorRect: offset & renderBox.size,
      onSelect: (emoji) {
        _dismissPicker();
        _applyReaction(emoji);
      },
      onDismiss: _dismissPicker,
      selectedEmoji: currentSelectedEmoji,
      actions: actions,
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => CustomConfirmationDialog(
            title: 'Delete this comment ?',
            img: AppImages.deleteFilesAnimationLot,
            onConfirm: () async {
              Navigator.pop(ctx);
              context.read<CommentsCubit>().deleteComment(
                commentId: widget.comment.id,
                postId: widget.comment.postId,
              );
              if (context.mounted) {
                AppToast.info('Comment deleted successfully');
              }
            },
          ),
    );
  }

  void _showCommentReactions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder:
          (context) =>
              CommentReactionsBottomSheet(commentId: widget.comment.id),
    );
  }

  void _dismissPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  void _applyReaction(String emoji) {
    HapticFeedback.selectionClick();
    context.read<CommentsCubit>().toggleReaction(
      commentId: widget.comment.id,
      commentOwnerId: widget.comment.authorId,
      emoji: emoji,
      postId: widget.postId,
    );
  }

  String? get currentSelectedEmoji {
    try {
      return widget.comment.reactions.firstWhere((r) => r.reactedByMe).emoji;
    } catch (_) {
      return null;
    }
  }

  void _openMentionPreview(String userId, String name) {
    final currentUserId = SupabaseProvider.id;
    final navController = context.read<HomeCubit>().navController;

    if (userId == currentUserId) {
      if (navController != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        navController.jumpToTab(3);
      }
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _stemController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  void _recalculateStem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final avatarBox =
          _lastReplyAvatarKey.currentContext?.findRenderObject() as RenderBox?;
      final thisBox = context.findRenderObject() as RenderBox?;
      if (avatarBox == null || thisBox == null) return;

      final avatarTopLeft = thisBox.globalToLocal(
        avatarBox.localToGlobal(Offset.zero),
      );
      final double stemEnd = avatarTopLeft.dy + avatarBox.size.height / 2;

      if (_stemEndY != stemEnd) {
        setState(() => _stemEndY = stemEnd);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = context.watch<CommentsCubit>().expandedComments.contains(
      widget.comment.id,
    );
    final theme = Theme.of(context);
    final hasReplies = widget.comment.replies.isNotEmpty;
    final replyCount = widget.comment.replies.length;
    final int visualDepth = widget.depth > 2 ? 2 : widget.depth;
    final double aR = avatarRadius(visualDepth);
    final double indentWidth = visualDepth * kIndent;
    final double avatarCenterX = indentWidth + aR;
    final bool isMediaOnlyComment =
        widget.comment.hasMedia && widget.comment.text.isEmpty;
    final currentUserId = SupabaseProvider.id;
    final navController = context.read<HomeCubit>().navController;
    final bool isMe = widget.comment.authorId == currentUserId;
    final GlobalKey? effectiveHighlightKey =
        widget.comment.id == widget.highlightCommentId
            ? widget.highlightKey
            : null;

    return AnimatedBuilder(
      animation: Listenable.merge([_anim, _highlightAnim]),
      builder: (_, __) {
        return Container(
          key: effectiveHighlightKey,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(
              alpha: 0.14 * _highlightAnim.value,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            painter: ThreadPainter(
              depth: widget.depth,
              avatarCenterX: avatarCenterX,
              currentAvatarRadius: aR,
              showVerticalStem: hasReplies && isExpanded && _stemEndY != null,
              stemEndY: (isExpanded && hasReplies) ? _stemEndY : null,
              lineColor: AppColors.grey4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: indentWidth),
                    CommentAvatar(
                      key: widget.lastAvatarKey,
                      comment: widget.comment,
                      imageUrl: widget.comment.authorImageUrl,
                      radius: aR,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onLongPress: _showPicker,
                            child:
                                isMediaOnlyComment
                                    ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 2,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            widget.comment.authorName ?? 'User',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: theme.primaryColor,
                                                  fontSize: 13,
                                                ),
                                          ),
                                        ),
                                        CommentMediaBubble(
                                          comment: widget.comment,
                                        ),
                                      ],
                                    )
                                    : Container(
                                      decoration: BoxDecoration(
                                        color:
                                            widget.depth > 0
                                                ? theme
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.55)
                                                : theme
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.85),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              if (isMe) {
                                                navController?.jumpToTab(3);
                                              } else {
                                                Navigator.of(
                                                  context,
                                                  rootNavigator: true,
                                                ).pushNamed(
                                                  AppRoutes.profileViewRoute,
                                                  arguments:
                                                      widget.comment.authorId,
                                                );
                                              }
                                            },
                                            child: Text(
                                              widget.comment.authorName ??
                                                  'User',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: theme.primaryColor,
                                                    fontSize: 13,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          if (widget.comment.hasMedia) ...[
                                            CommentMediaBubble(
                                              comment: widget.comment,
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          if (widget.comment.text.isNotEmpty)
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: switch (widget
                                                    .comment
                                                    .commentType) {
                                                  CommentType.image ||
                                                  CommentType.video => 180,
                                                  CommentType.gif => 160,
                                                  CommentType.sticker => 96,
                                                  CommentType.voice => 195,
                                                  CommentType.file => 285,
                                                  CommentType.text => 0,
                                                },
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  widget.comment.commentType ==
                                                          CommentType.text
                                                      ? MessageLinkPreview(
                                                        text:
                                                            widget.comment.text,
                                                        textWidget: MentionRichText(
                                                          text:
                                                              widget
                                                                  .comment
                                                                  .text,
                                                          mentions:
                                                              widget
                                                                  .comment
                                                                  .mentions,
                                                          onMentionTap:
                                                              _openMentionPreview,
                                                          style: theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                fontSize: 14,
                                                                height: 1.4,
                                                                color:
                                                                    theme
                                                                        .colorScheme
                                                                        .onSurface,
                                                              ),
                                                        ),
                                                      )
                                                      : MentionRichText(
                                                        text:
                                                            widget.comment.text,
                                                        mentions:
                                                            widget
                                                                .comment
                                                                .mentions,
                                                        onMentionTap:
                                                            _openMentionPreview,
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontSize: 14,
                                                              height: 1.4,
                                                              color:
                                                                  theme
                                                                      .colorScheme
                                                                      .onSurface,
                                                            ),
                                                      ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                          ),
                          SizedBox(
                            height:
                                widget.comment.reactions.isNotEmpty ? 16 : 6,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Row(
                              children: [
                                Text(
                                  FormattedDate.getFormattedDate(
                                    widget.comment.createdAt,
                                    isShort: true,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey6,
                                    fontSize: 11,
                                  ),
                                ),
                                if (widget.comment.isEdited) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '· Edited',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey6,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 12),
                                CommentActionChip(
                                  key: _reactionKey,
                                  label:
                                      widget.comment.reactions.any(
                                            (r) => r.reactedByMe,
                                          )
                                          ? widget.comment.reactions
                                              .firstWhere((r) => r.reactedByMe)
                                              .emoji
                                          : 'Like',
                                  isActive: widget.comment.reactions.any(
                                    (r) => r.reactedByMe,
                                  ),
                                  activeColor: theme.primaryColor,
                                  onTap: () {
                                    if (widget.comment.reactions.any(
                                      (r) => r.reactedByMe,
                                    )) {
                                      _applyReaction(
                                        widget.comment.reactions
                                            .firstWhere((r) => r.reactedByMe)
                                            .emoji,
                                      );
                                    } else {
                                      _showPicker();
                                    }
                                  },
                                  onLongPress: _showPicker,
                                ),
                                const SizedBox(width: 12),
                                CommentActionChip(
                                  label: 'Reply',
                                  onTap:
                                      () => widget.onReplyTap?.call(
                                        widget.comment.id,
                                        widget.comment.authorName ?? 'User',
                                      ),
                                ),
                                const SizedBox(width: 12),
                                CommentReactionsSummary(
                                  reactions: widget.comment.reactions,
                                  onTap: () => _showCommentReactions(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasReplies) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.only(
                      left: visualDepth * kIndent + aR * 2 + 12,
                    ),
                    child: GestureDetector(
                      onTap:
                          () => context.read<CommentsCubit>().toggleReplies(
                            widget.comment.id,
                          ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpanded
                                ? 'Hide replies'
                                : 'View $replyCount ${replyCount == 1 ? "reply" : "replies"}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    onEnd: () {
                      if (isExpanded) _recalculateStem();
                    },
                    child:
                        isExpanded
                            ? NotificationListener<
                              SizeChangedLayoutNotification
                            >(
                              onNotification: (_) {
                                _recalculateStem();
                                return false;
                              },
                              child: SizeChangedLayoutNotifier(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: kRepliesTopPad,
                                  ),
                                  child: Column(
                                    children:
                                        widget.comment.replies.asMap().entries.map((
                                          entry,
                                        ) {
                                          final isLast =
                                              entry.key ==
                                              widget.comment.replies.length - 1;
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom:
                                                  isLast ? 0 : kReplySpacing,
                                            ),
                                            child: CommentWidget(
                                              key: ValueKey(
                                                '${entry.value.id}_${widget.depth}',
                                              ),
                                              comment: entry.value,
                                              postId: widget.postId,
                                              postAuthorId: widget.postAuthorId,
                                              depth: widget.depth + 1,
                                              onReplyTap: widget.onReplyTap,
                                              onEditTap: widget.onEditTap,
                                              lastAvatarKey:
                                                  isLast
                                                      ? _lastReplyAvatarKey
                                                      : null,
                                              highlightCommentId:
                                                  widget.highlightCommentId,
                                              highlightKey: widget.highlightKey,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
