import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/attachment/models/media_transfer_state.dart';
import '../../../core/attachment/widgets/file_message_bubble.dart';
import '../../../core/attachment/widgets/media_state_overlay.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/bidi_text_helper.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/widgets/custom_linkify_text.dart';
import '../../single_chats/widgets/image_message_widget.dart';
import '../../single_chats/widgets/video_message_widget.dart';
import '../../single_chats/widgets/voice_message_bubble_widget.dart';
import '../helpers/ai_chat_colors.dart';
import '../helpers/ai_model_display.dart';
import '../helpers/ai_model_iconography.dart';
import '../models/ai_chat_message.dart';
import 'ai_chat_selection_header_bar.dart' show kAiChatStarGold;
import 'ai_swipe_to_reply_wrapper.dart';
import 'ai_typewriter_text.dart';

const _kEntranceDuration = Duration(milliseconds: 380);
const _kMultiSelectLongPressDuration = Duration(milliseconds: 400);

class AiChatBubble extends StatefulWidget {
  final AiChatMessage message;
  final VoidCallback? onCancelUpload;
  final VoidCallback? onRetry;
  final bool animate;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPressSelect;
  final VoidCallback? onTapSelect;
  final bool isStarred;
  final ValueChanged<String>? onTypewriterDone;
  final ValueChanged<String>? onTapReply;
  final bool isHighlighted;
  final ValueChanged<AiChatMessage>? onSwipeReply;
  final AiChatMessage? replyOrigin;

  const AiChatBubble({
    super.key,
    required this.message,
    this.replyOrigin,
    this.onCancelUpload,
    this.onRetry,
    this.animate = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPressSelect,
    this.onTapSelect,
    this.isStarred = false,
    this.isHighlighted = false,
    this.onSwipeReply,
    this.onTypewriterDone,
    this.onTapReply,
  });

  @override
  State<AiChatBubble> createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<AiChatBubble> {
  late bool _typewriterFinished;

  @override
  void initState() {
    super.initState();
    _typewriterFinished = !widget.animate;
  }

  void _handleTypewriterDone() {
    if (!mounted || _typewriterFinished) return;
    setState(() => _typewriterFinished = true);
    widget.onTypewriterDone?.call(widget.message.id);
  }

  @override
  void didUpdateWidget(covariant AiChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _typewriterFinished = !widget.animate;
    }
  }

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

  bool get _isSelectable => !widget.message.isMe;

  void _handleLongPress() {
    if (!_isSelectable) return;
    widget.onLongPressSelect?.call();
  }

  void _handleTap() {
    if (widget.isSelectionMode) {
      if (_isSelectable) widget.onTapSelect?.call();
      return;
    }
    if (widget.message.status == AiChatDeliveryStatus.failed) {
      widget.onRetry?.call();
    }
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

    final bubble = RawGestureDetector(
      gestures: _buildBubbleGestures(),
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
          crossAxisAlignment:
              _isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.hasReply)
              SizedBox(
                width: double.infinity,
                child: _buildReplyCard(context, isMe),
              ),

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
                                  : _buildAssistantText(message, textStyle),
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

    final selectionColor = Theme.of(
      context,
    ).primaryColor.withValues(alpha: 0.16);
    final isRowSelected = _isSelectable && widget.isSelected;

    final messageRow = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        color: isRowSelected ? selectionColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child:
                    widget.isSelectionMode
                        ? Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            widget.isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20,
                            color:
                                widget.isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.white.withValues(alpha: 0.4),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              _AssistantAvatar(model: message.model),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: AiSwipeToReplyWrapper(
                isMe: isMe,
                enabled:
                    !widget.isSelectionMode &&
                    widget.message.status != AiChatDeliveryStatus.sending,
                onReply: () => widget.onSwipeReply?.call(message),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        widget.isHighlighted
                            ? AiChatColors.highlightFill(
                              Theme.of(context).primaryColor,
                            )
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          widget.isHighlighted
                              ? AiChatColors.highlightStroke(
                                Theme.of(context).primaryColor,
                              )
                              : Colors.transparent,
                      width: 1.4,
                    ),
                    boxShadow:
                        widget.isHighlighted
                            ? [
                              BoxShadow(
                                color: AiChatColors.highlightGlow(
                                  Theme.of(context).primaryColor,
                                ),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                            : const <BoxShadow>[],
                  ),
                  child: bubble,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
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
  }

  Map<Type, GestureRecognizerFactory> _buildBubbleGestures() {
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
            (instance) => instance.onTap = _handleTap,
          ),
      if (_isSelectable)
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: _kMultiSelectLongPressDuration,
              ),
              (instance) => instance.onLongPress = _handleLongPress,
            ),
    };
  }

  Widget _buildAssistantText(AiChatMessage message, TextStyle textStyle) {
    final bool shouldAnimate = !_typewriterFinished && widget.animate;

    return AiTypewriterText(
      key: ValueKey('ai-typewriter-${message.id}'),
      text: message.text,
      style: textStyle,
      animate: shouldAnimate,
      onDone: _handleTypewriterDone,
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
        if (widget.isStarred) ...[
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 11, color: kAiChatStarGold),
        ],
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

  String get _repliedMediaType =>
      widget.message.replyToMediaType ??
      widget.replyOrigin?.mediaType.name ??
      'none';

  String _repliedMediaLabel() {
    switch (_repliedMediaType) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'voice':
        final seconds = widget.replyOrigin?.durationSeconds;
        return seconds == null
            ? 'Voice message'
            : 'Voice message · ${_formatReplyDuration(seconds)}';
      case 'file':
        return widget.replyOrigin?.fileName ?? 'File';
      default:
        return 'Message';
    }
  }

  IconData? _repliedMediaIcon() {
    switch (_repliedMediaType) {
      case 'image':
        return Icons.photo_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'voice':
        return Icons.mic_rounded;
      case 'file':
        return Icons.insert_drive_file_rounded;
      default:
        return null;
    }
  }

  static String _formatReplyDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${rest.toString().padLeft(2, '0')}';
  }

  Widget _buildReplyCard(BuildContext context, bool isMe) {
    final message = widget.message;
    final origin = widget.replyOrigin;

    final senderTitle =
        message.replyToSenderRole == 'user'
            ? 'You'
            : (origin?.model?.fullLabel ??
                message.model?.fullLabel ??
                'Syncra');

    final replyText = message.replyToText?.trim() ?? '';
    final previewText = replyText.isNotEmpty ? replyText : _repliedMediaLabel();
    final mediaIcon = _repliedMediaIcon();

    final hasThumbnail =
        message.replyToMediaUrl != null &&
        message.replyToMediaUrl!.startsWith('http') &&
        (_repliedMediaType == 'image' || _repliedMediaType == 'video');

    final bodyDirection = BidiTextHelper.detectDirection(
      replyText.isNotEmpty ? replyText : _repliedMediaLabel(),
    );
    final bodyAlign = BidiTextHelper.alignFor(bodyDirection);

    final titleDirection = BidiTextHelper.detectDirection(senderTitle);
    final titleAlign = BidiTextHelper.alignFor(titleDirection);

    final accentColor = isMe ? Colors.white70 : Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        if (message.replyToMessageId != null) {
          widget.onTapReply?.call(message.replyToMessageId!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color:
              isMe
                  ? Colors.white.withValues(alpha: 0.16)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Directionality(
          textDirection: bodyDirection,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3.5, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          senderTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: titleAlign,
                          textDirection: titleDirection,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isMe
                                    ? Colors.white.withValues(alpha: 0.95)
                                    : Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: bodyDirection,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (mediaIcon != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(
                                    mediaIcon,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Expanded(
                                child: Text(
                                  previewText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: bodyAlign,
                                  textDirection: bodyDirection,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasThumbnail)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        message.replyToMediaUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
    final brand = AiModelIconography.brandFromWire(model?.providerLabel);

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: AiModelIconography.buildBrandIcon(
          brand,
          size: 14,
          useOriginalColors: true,
        ),
      ),
    );
  }
}
