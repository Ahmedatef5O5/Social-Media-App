import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/group_chats/widgets/group_invite_bottom_sheet.dart';
import '../../deep_link/services/deep_link_service.dart';
import '../../helpers/chat_helper.dart';
import '../../helpers/content_deep_link_navigator.dart';
import '../../helpers/emoji_helper.dart';
import '../../notifications/notification_navigator_key.dart';
import '../models/mention_ref.dart';

class MentionRichText extends StatefulWidget {
  final String text;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final List<MentionRef> mentions;
  final void Function(String userId, String name) onMentionTap;
  final Future<void> Function(String url)? onLinkTap;
  final TextStyle? style;
  final Color? mentionColor;
  final Color? linkColor;
  final int? maxLines;
  final int collapsedMaxLines;
  final TextOverflow? overflow;
  final double? maxTextWidth;
  final String? highlightQuery;
  final TextStyle? highlightStyle;
  final ValueChanged<bool>? onExpandChanged;

  const MentionRichText({
    super.key,
    required this.text,
    this.textAlign,
    this.textDirection,
    required this.mentions,
    required this.onMentionTap,
    this.onLinkTap,
    this.style,
    this.mentionColor,
    this.linkColor,
    this.maxLines,
    this.collapsedMaxLines = 10,
    this.overflow,
    this.maxTextWidth,
    this.highlightQuery,
    this.highlightStyle,
    this.onExpandChanged,
  });

  @override
  State<MentionRichText> createState() => _MentionRichTextState();
}

class _MentionRichTextState extends State<MentionRichText> {
  final List<TapGestureRecognizer> _recognizers = [];
  bool _expanded = false;

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(VoidCallback onTap) {
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);

    final parsed = DeepLinkService.parseInternalLink(uri);
    if (parsed != null) {
      final (type, id) = parsed;
      if (type == 'post') {
        ContentDeepLinkNavigator.openPost(id);
        return;
      } else if (type == 'story') {
        ContentDeepLinkNavigator.openStoryById(id);
        return;
      } else if (type == 'join') {
        final context = navigatorKey.currentContext;
        if (context != null) GroupInviteBottomSheet.show(context, id);
        return;
      }
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<InlineSpan> _buildSpans({
    required TextStyle defaultStyle,
    required TextStyle mentionStyle,
  }) {
    final text = widget.text;
    final mentions = List.of(widget.mentions)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    final spans = <InlineSpan>[];
    int cursor = 0;

    void addLinkifiedSegment(String rawSegment) {
      final segment = EmojiHelper.normalize(rawSegment);
      if (segment.isEmpty) return;
      for (final element in linkify(segment)) {
        if (element is LinkableElement) {
          spans.add(
            TextSpan(
              text: element.text,
              style: defaultStyle.copyWith(
                color: widget.linkColor ?? Colors.blue,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: widget.linkColor ?? Colors.blue,
              ),
              recognizer: _recognizerFor(() async {
                if (widget.onLinkTap != null) {
                  await widget.onLinkTap!(element.url);
                } else {
                  await _openLink(element.url);
                }
              }),
            ),
          );
        } else {
          spans.addAll(_highlightedTextSpans(element.text, defaultStyle));
        }
      }
    }

    for (final mention in mentions) {
      if (mention.startIndex < cursor ||
          mention.endIndex > text.length ||
          mention.startIndex >= mention.endIndex) {
        continue;
      }

      addLinkifiedSegment(text.substring(cursor, mention.startIndex));

      final mentionSlice = text.substring(mention.startIndex, mention.endIndex);
      spans.add(
        TextSpan(
          text: EmojiHelper.normalize(mentionSlice),
          style: mentionStyle,
          recognizer: _recognizerFor(
            () => widget.onMentionTap(
              mention.mentionedUserId,
              mentionSlice.startsWith('@')
                  ? mentionSlice.substring(1)
                  : mentionSlice,
            ),
          ),
        ),
      );
      cursor = mention.endIndex;
    }
    addLinkifiedSegment(text.substring(cursor));
    return spans;
  }

  List<InlineSpan> _highlightedTextSpans(String rawText, TextStyle baseStyle) {
    final text = EmojiHelper.normalize(rawText);
    final query = widget.highlightQuery?.trim() ?? '';
    if (query.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final highlightStyle =
        widget.highlightStyle ??
        baseStyle.copyWith(
          backgroundColor: Colors.yellow.withValues(alpha: 0.55),
          fontWeight: FontWeight.w700,
        );

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <InlineSpan>[];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);
    if (index == -1) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    while (index != -1) {
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final defaultStyle = (widget.style ??
            Theme.of(context).textTheme.bodyMedium ??
            const TextStyle())
        .copyWith(
          fontSize: widget.style?.fontSize ?? 14,
          height: widget.style?.height ?? 1.4,
        );

    final resolvedMentionColor =
        widget.mentionColor ?? Theme.of(context).primaryColor;

    final mentionStyle = defaultStyle.copyWith(
      color: resolvedMentionColor,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: resolvedMentionColor.withValues(alpha: 0.5),
      decorationThickness: 1,
    );

    final spans = _buildSpans(
      defaultStyle: defaultStyle,
      mentionStyle: mentionStyle,
    );
    final normalizedFullText = EmojiHelper.normalize(widget.text);
    final direction = ChatHelper.getTextDirection(normalizedFullText);
    final span = TextSpan(children: spans);

    final toggleAlignment = switch (widget.textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ =>
        direction == TextDirection.rtl
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
    };

    final isArabicText = direction == TextDirection.rtl;
    final readMoreLabel = isArabicText ? '...قراءة المزيد' : 'Read more...';
    final readLessLabel = isArabicText ? 'عرض أقل' : 'Show less';

    if (widget.maxLines != null) {
      return Text.rich(
        span,
        style: defaultStyle,
        maxLines: widget.maxLines,
        overflow: widget.overflow ?? TextOverflow.ellipsis,
        textDirection: direction,
        textAlign: widget.textAlign ?? TextAlign.start,
      );
    }
    final effectiveMaxWidth =
        widget.maxTextWidth ?? MediaQuery.of(context).size.width * 0.75;

    final painter = TextPainter(
      text: span,
      maxLines: widget.collapsedMaxLines,
      textDirection: direction,
    )..layout(maxWidth: effectiveMaxWidth);

    final isOverflowing = painter.didExceedMaxLines;

    if (!isOverflowing) {
      return Text.rich(
        span,
        style: defaultStyle,
        textDirection: direction,
        textAlign: widget.textAlign ?? TextAlign.start,
      );
    }

    if (_expanded) {
      return Column(
        crossAxisAlignment: toggleAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            span,
            style: defaultStyle,
            textDirection: direction,
            textAlign: widget.textAlign ?? TextAlign.start,
          ),
          GestureDetector(
            onTap: () {
              setState(() => _expanded = false);
              widget.onExpandChanged?.call(false);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                readLessLabel,
                style: defaultStyle.copyWith(
                  color: resolvedMentionColor,
                  fontWeight: FontWeight.w700,
                ),
                textDirection: widget.textDirection,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: toggleAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          span,
          style: defaultStyle,
          maxLines: widget.collapsedMaxLines,
          overflow: TextOverflow.ellipsis,
          textDirection: direction,
          textAlign: widget.textAlign,
        ),
        GestureDetector(
          onTap: () {
            setState(() => _expanded = true);
            widget.onExpandChanged?.call(true);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              readMoreLabel,
              style: defaultStyle.copyWith(
                color: resolvedMentionColor,
                fontWeight: FontWeight.w700,
              ),
              textDirection: widget.textDirection,
            ),
          ),
        ),
      ],
    );
  }
}
