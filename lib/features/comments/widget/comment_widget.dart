import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/widget/thread_painter.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/widgets/custom_linkify_text.dart';
import 'comment_constants.dart';
import 'comment_avatar.dart';
import 'comment_action_chip.dart';
import 'comment_overlay_picker.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';

class CommentWidget extends StatefulWidget {
  final CommentModel comment;
  final String postId;
  final int depth;
  final void Function(String commentId, String authorName)? onReplyTap;
  final GlobalKey? lastAvatarKey;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.postId,
    this.depth = 0,
    this.onReplyTap,
    this.lastAvatarKey,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final GlobalKey _reactionKey = GlobalKey();
  late List<CommentReaction> _reactions;

  late final AnimationController _stemController;
  late final Animation<double> _anim;

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
    _reactions = List<CommentReaction>.from(widget.comment.reactions);
  }

  @override
  void didUpdateWidget(CommentWidget old) {
    super.didUpdateWidget(old);
    if (!_reactionsEqual(old.comment.reactions, widget.comment.reactions)) {
      setState(
        () => _reactions = List<CommentReaction>.from(widget.comment.reactions),
      );
    }
  }

  bool _reactionsEqual(List<CommentReaction> a, List<CommentReaction> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].emoji != b[i].emoji ||
          a[i].count != b[i].count ||
          a[i].reactedByMe != b[i].reactedByMe) {
        return false;
      }
    }
    return true;
  }

  void _showPicker() {
    if (_overlayEntry != null) return;

    final renderBox =
        _reactionKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    _overlayEntry = CommentOverlayPicker.create(
      context: context,
      anchorRect: offset & renderBox.size,
      onSelect: (emoji) {
        _dismissPicker();
        _applyReaction(emoji);
      },
      onDismiss: _dismissPicker,
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  void _applyReaction(String emoji) {
    HapticFeedback.selectionClick();
    setState(() {
      final updated = List<CommentReaction>.from(_reactions);
      final myIdx = updated.indexWhere((r) => r.reactedByMe);
      if (myIdx >= 0) {
        final old = updated[myIdx];
        if (old.emoji == emoji) {
          old.count <= 1
              ? updated.removeAt(myIdx)
              : updated[myIdx] = old.copyWith(
                count: old.count - 1,
                reactedByMe: false,
              );
        } else {
          old.count <= 1
              ? updated.removeAt(myIdx)
              : updated[myIdx] = old.copyWith(
                count: old.count - 1,
                reactedByMe: false,
              );
          final ni = updated.indexWhere((r) => r.emoji == emoji);
          ni >= 0
              ? updated[ni] = updated[ni].copyWith(
                count: updated[ni].count + 1,
                reactedByMe: true,
              )
              : updated.add(
                CommentReaction(emoji: emoji, count: 1, reactedByMe: true),
              );
        }
      } else {
        final ni = updated.indexWhere((r) => r.emoji == emoji);
        ni >= 0
            ? updated[ni] = updated[ni].copyWith(
              count: updated[ni].count + 1,
              reactedByMe: true,
            )
            : updated.add(
              CommentReaction(emoji: emoji, count: 1, reactedByMe: true),
            );
      }
      _reactions = updated;
    });

    context.read<CommentsCubit>().toggleReaction(
      commentId: widget.comment.id,
      emoji: emoji,
      postId: widget.postId,
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _stemController.dispose();
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
    final isExpanded = context
        .watch<CommentsCubit>()
        .collapsedComments
        .contains(widget.comment.id);
    final theme = Theme.of(context);
    final hasReplies = widget.comment.replies.isNotEmpty;
    final replyCount = widget.comment.replies.length;

    final int visualDepth = widget.depth > 2 ? 2 : widget.depth;
    final double aR = avatarRadius(visualDepth);
    final double indentWidth = visualDepth * kIndent;
    final double avatarCenterX = indentWidth + aR;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return CustomPaint(
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
                          child: Container(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.comment.authorName ?? 'User',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),

                                CustomLinkifyText(
                                  text: widget.comment.text,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _reactions.isNotEmpty ? 16 : 6),
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
                              const SizedBox(width: 12),
                              CommentActionChip(
                                key: _reactionKey,
                                label:
                                    _reactions.any((r) => r.reactedByMe)
                                        ? _reactions
                                            .firstWhere((r) => r.reactedByMe)
                                            .emoji
                                        : 'Like',
                                isActive: _reactions.any((r) => r.reactedByMe),
                                activeColor: theme.primaryColor,
                                onTap: () {
                                  if (_reactions.any((r) => r.reactedByMe)) {
                                    _applyReaction(
                                      _reactions
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
                              _inlineReactionSummary(),
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
                          ? NotificationListener<SizeChangedLayoutNotification>(
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
                                            bottom: isLast ? 0 : kReplySpacing,
                                          ),
                                          child: CommentWidget(
                                            key: ValueKey(
                                              '${entry.value.id}_${widget.depth}',
                                            ),
                                            comment: entry.value,
                                            postId: widget.postId,
                                            depth: widget.depth + 1,
                                            onReplyTap: widget.onReplyTap,
                                            lastAvatarKey:
                                                isLast
                                                    ? _lastReplyAvatarKey
                                                    : null,
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
        );
      },
    );
  }

  Widget _inlineReactionSummary() {
    if (_reactions.isEmpty) return const SizedBox.shrink();
    final total = _reactions.fold<int>(0, (s, r) => s + r.count);
    return Row(
      children: [
        const SizedBox(width: 5),
        Text(
          '$total',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: AppColors.grey6, fontSize: 11),
        ),
        const SizedBox(width: 3),
        ..._reactions
            .take(2)
            .map((r) => Text(r.emoji, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
