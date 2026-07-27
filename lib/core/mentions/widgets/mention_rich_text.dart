import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/chat_helper.dart';
import '../models/mention_ref.dart';

class MentionRichText extends StatefulWidget {
  final String text;
  final TextAlign? textAlign;
  final List<MentionRef> mentions;
  final void Function(String userId, String name) onMentionTap;
  final Future<void> Function(String url)? onLinkTap;
  final TextStyle? style;
  final Color? mentionColor;
  final int? maxLines;
  final int collapsedMaxLines;
  final TextOverflow? overflow;
  final double? maxTextWidth;

  const MentionRichText({
    super.key,
    required this.text,
    this.textAlign,
    required this.mentions,
    required this.onMentionTap,
    this.onLinkTap,
    this.style,
    this.mentionColor,
    this.maxLines,
    this.collapsedMaxLines = 10,
    this.overflow,
    this.maxTextWidth,
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
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

    void addLinkifiedSegment(String segment) {
      if (segment.isEmpty) return;
      for (final element in linkify(segment)) {
        if (element is LinkableElement) {
          spans.add(
            TextSpan(
              text: element.text,
              style: defaultStyle.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
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
          spans.add(TextSpan(text: element.text, style: defaultStyle));
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
          text: mentionSlice,
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

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final defaultStyle =
        widget.style ??
        Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 1.4);

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
    final direction = ChatHelper.getTextDirection(widget.text);
    final span = TextSpan(children: spans);

    if (widget.maxLines != null) {
      return Text.rich(
        span,
        style: defaultStyle,
        maxLines: widget.maxLines,
        overflow: widget.overflow ?? TextOverflow.ellipsis,
        textDirection: direction,
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
      return Text.rich(span, style: defaultStyle, textDirection: direction);
    }

    if (_expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(span, style: defaultStyle, textDirection: direction),
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Show less',
                style: defaultStyle.copyWith(
                  color: resolvedMentionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          onTap: () => setState(() => _expanded = true),
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Read more',
              style: defaultStyle.copyWith(
                color: resolvedMentionColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
