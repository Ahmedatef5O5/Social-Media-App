import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/attachment/models/media_transfer_state.dart';
import '../../../core/attachment/widgets/file_message_bubble.dart';
import '../../../core/attachment/widgets/media_state_overlay.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_linkify_text.dart';
import '../../single_chats/widgets/image_message_widget.dart';
import '../../single_chats/widgets/video_message_widget.dart';
import '../../single_chats/widgets/voice_message_bubble_widget.dart';
import '../helpers/ai_chat_colors.dart';
import '../helpers/ai_model_display.dart';
import '../models/ai_chat_message.dart';
import 'ai_message_action_row.dart';
import 'ai_typewriter_text.dart';

const _kEntranceDuration = Duration(milliseconds: 380);
const _kActionsVisibleDuration = Duration(milliseconds: 4500);
const _kActionsFadeDuration = Duration(milliseconds: 220);

class AiChatBubble extends StatefulWidget {
  final AiChatMessage message;
  final VoidCallback? onCancelUpload;
  final VoidCallback? onRetry;
  final VoidCallback? onForward;
  final bool animate;

  const AiChatBubble({
    super.key,
    required this.message,
    this.onCancelUpload,
    this.onRetry,
    this.onForward,
    this.animate = false,
  });

  @override
  State<AiChatBubble> createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<AiChatBubble> {
  bool _actionsVisible = false;
  Timer? _hideTimer;
  bool _liked = false;

  bool get _isUploading =>
      widget.message.status == AiChatDeliveryStatus.sending &&
      widget.message.mediaType != AiChatMediaType.none;

  double? get _fixedMediaWidth =>
      (widget.message.mediaType == AiChatMediaType.image ||
              widget.message.mediaType == AiChatMediaType.video ||
              widget.message.mediaType == AiChatMediaType.file)
          ? 240
          : null;

  bool get _isRtl =>
      ChatHelper.getTextDirection(widget.message.text) == TextDirection.rtl;

  Alignment get _contentAlignmentGeometry =>
      _isRtl ? Alignment.centerRight : Alignment.centerLeft;

  Alignment get _statusRowAlignmentGeometry =>
      _isRtl ? Alignment.centerLeft : Alignment.centerRight;

  @override
  void initState() {
    super.initState();
    if (widget.message.isMe) return;

    final hasText = widget.message.text.trim().isNotEmpty;
    if (widget.animate && hasText) {
      return;
    }

    Future.delayed(_kEntranceDuration, _revealActions);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _revealActions() {
    if (!mounted || widget.message.isMe) return;
    _hideTimer?.cancel();
    if (!_actionsVisible) {
      setState(() => _actionsVisible = true);
    }
    _hideTimer = Timer(_kActionsVisibleDuration, () {
      if (mounted) setState(() => _actionsVisible = false);
    });
  }

  void _handleLongPress() {
    _revealActions();
    widget.onForward?.call();
  }

  void _handleTap() {
    _revealActions();
    if (widget.message.status == AiChatDeliveryStatus.failed) {
      widget.onRetry?.call();
    }
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.message.text));
    if (mounted) AppToast.success('Copied to clipboard');
    _revealActions();
  }

  Future<void> _handleShare() async {
    _revealActions();
    await SharePlus.instance.share(ShareParams(text: widget.message.text));
  }

  void _handleToggleLike() {
    setState(() => _liked = !_liked);
    _revealActions();
  }

  BorderRadius _radius(bool isMe) => BorderRadius.only(
    topLeft: const Radius.circular(16),
    topRight: const Radius.circular(16),
    bottomLeft: Radius.circular(isMe ? 16 : 4),
    bottomRight: Radius.circular(isMe ? 4 : 16),
  );

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = message.isMe;
    final hasMedia = message.mediaType != AiChatMediaType.none;
    final hasText = message.text.trim().isNotEmpty;

    final textStyle = TextStyle(
      color: isMe ? Colors.white : Colors.white.withValues(alpha: 0.92),
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w500,
      fontFamily: null,
      fontFamilyFallback: AppTypography.fontFallback,
    );

    final bubble = GestureDetector(
      onTap: _handleTap,
      onLongPress: !isMe ? _handleLongPress : null,
      onDoubleTap: !isMe ? _revealActions : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        padding:
            hasMedia
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient:
              isMe
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AiChatColors.outgoingBubbleGradient(
                      Theme.of(context).primaryColor,
                    ),
                  )
                  : null,
          color: isMe ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: _radius(isMe),
          border: Border.all(
            color: Colors.white.withValues(alpha: isMe ? 0.14 : 0.12),
          ),
          boxShadow:
              isMe
                  ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMedia) _buildMedia(context, isMe),
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText)
                    SizedBox(
                      width: _fixedMediaWidth,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: hasMedia ? 8 : 0,
                          left: hasMedia ? 6 : 0,
                          right: hasMedia ? 6 : 0,
                        ),
                        child: Align(
                          alignment: _contentAlignmentGeometry,

                          child:
                              isMe
                                  ? CustomLinkifyText(
                                    text: message.text,
                                    overflow: TextOverflow.visible,

                                    style: textStyle,
                                    textDirection: ChatHelper.getTextDirection(
                                      message.text,
                                    ),
                                    bubbleColor: Theme.of(context).primaryColor,
                                  )
                                  : AiTypewriterText(
                                    text: message.text,
                                    style: textStyle,
                                    animate: widget.animate,
                                  ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                      left: hasMedia && !hasText ? 6 : 0,
                    ),
                    child: Align(
                      alignment: _statusRowAlignmentGeometry,

                      child: _buildStatusRow(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final messageRow = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _AssistantAvatar(model: message.model),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );

    final animatedMessageRow = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _kEntranceDuration,
      curve: Curves.easeOutCubic,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: child,
            ),
          ),
      child: messageRow,
    );

    if (isMe) return animatedMessageRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        animatedMessageRow,
        Padding(
          padding: const EdgeInsets.only(left: 34, top: 2),
          child: AnimatedOpacity(
            duration: _kActionsFadeDuration,
            opacity: _actionsVisible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_actionsVisible,
              child: AiMessageActionRow(
                liked: _liked,
                onToggleLike: _handleToggleLike,
                onCopy: _handleCopy,
                onShare: _handleShare,
                showRetry: message.status == AiChatDeliveryStatus.failed,
                onRetry: widget.onRetry,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1)}…';
  }

  Widget _buildStatusRow() {
    final modelLabel =
        (!widget.message.isMe && widget.message.model != null)
            ? _truncate(widget.message.model!.fullLabel, 30)
            : null;

    final timeStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.55),
      fontSize: 8.5,
    );

    final timeGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FormattedDate.getMessageTime(widget.message.createdAt),
          style: timeStyle,
        ),
        if (widget.message.status == AiChatDeliveryStatus.sending) ...[
          const SizedBox(width: 5),
          SizedBox(
            width: 9,
            height: 9,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
        if (widget.message.status == AiChatDeliveryStatus.failed) ...[
          const SizedBox(width: 5),
          const Icon(
            Icons.error_outline_rounded,
            size: 12,
            color: Colors.redAccent,
          ),
        ],
      ],
    );

    if (modelLabel == null) return timeGroup;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: _isRtl ? TextDirection.ltr : TextDirection.rtl,
      children: [timeGroup, Text(modelLabel, style: timeStyle)],
    );
  }

  Widget _buildMedia(BuildContext context, bool isMe) {
    final message = widget.message;
    final transferState =
        _isUploading
            ? MediaTransferState.uploading(message.uploadProgress ?? 0)
            : const MediaTransferState.completed(
              direction: MediaTransferDirection.upload,
            );

    switch (message.mediaType) {
      case AiChatMediaType.image:
        return SizedBox(
          width: 240,
          height: 220,
          child: MediaStateOverlay(
            state: transferState,
            borderRadius: _radius(isMe),
            onCancelTap: widget.onCancelUpload,
            fileSizeBytes: message.fileSizeBytes,

            child:
                message.mediaUrl == null
                    ? const SizedBox.shrink()
                    : ImageMessageWidget(
                      imageUrl: message.mediaUrl!,
                      isMe: isMe,
                      fileSizeBytes: message.fileSizeBytes,
                      caption:
                          message.text.trim().isEmpty
                              ? null
                              : message.text.trim(),
                    ),
          ),
        );

      case AiChatMediaType.video:
        return SizedBox(
          width: 240,
          height: 200,
          child: MediaStateOverlay(
            state: transferState,
            borderRadius: _radius(isMe),
            isVideo: true,
            durationSeconds: message.durationSeconds,
            onCancelTap: widget.onCancelUpload,
            fileSizeBytes: message.fileSizeBytes,
            child:
                message.mediaUrl == null
                    ? const SizedBox.shrink()
                    : VideoMessageWidget(
                      videoUrl: message.mediaUrl!,
                      isMe: isMe,
                      fileSizeBytes: message.fileSizeBytes,
                      durationSeconds: message.durationSeconds,
                    ),
          ),
        );

      case AiChatMediaType.voice:
        return message.mediaUrl == null
            ? const SizedBox.shrink()
            : VoiceMessageBubbleWidget(
              voiceUrl: message.mediaUrl!,
              isMe: isMe,
              timestamp: message.createdAt,
              isUploading: _isUploading,
              initialDurationSeconds: message.durationSeconds,
            );

      case AiChatMediaType.file:
        return SizedBox(
          width: 240,
          child: FileMessageBubble(
            fileUrl: message.mediaUrl ?? '',
            fileName: message.fileName,
            fileSizeBytes: message.fileSizeBytes,
            isMe: isMe,
            isUploading: _isUploading,
            uploadProgress: message.uploadProgress,
            onCancelTap: widget.onCancelUpload,
          ),
        );

      case AiChatMediaType.none:
        return const SizedBox.shrink();
    }
  }
}

class _AssistantAvatar extends StatelessWidget {
  final AiModelDisplay? model;
  const _AssistantAvatar({this.model});

  @override
  Widget build(BuildContext context) {
    final color = model?.accentColor ?? Theme.of(context).primaryColor;
    final icon = model?.icon ?? Icons.auto_awesome_rounded;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}
