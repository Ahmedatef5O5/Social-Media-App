import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/chat_helper.dart';
import '../models/mention_ref.dart';

class MentionRichText extends StatefulWidget {
  final String text;
  final List<MentionRef> mentions;
  final void Function(String userId, String name) onMentionTap;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const MentionRichText({
    super.key,
    required this.text,
    required this.mentions,
    required this.onMentionTap,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<MentionRichText> createState() => _MentionRichTextState();
}

class _MentionRichTextState extends State<MentionRichText> {
  final List<TapGestureRecognizer> _recognizers = [];

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

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final text = widget.text;
    final defaultStyle =
        widget.style ??
        Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 1.4);
    final mentionStyle = defaultStyle.copyWith(
      color: Theme.of(context).primaryColor,
      fontWeight: FontWeight.w700,
    );
    const linkStyle = TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Colors.blue,
      decorationThickness: 0.8,
    );

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
              style: linkStyle,
              recognizer: _recognizerFor(() => _openLink(element.url)),
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

    return Text.rich(
      TextSpan(children: spans),
      style: defaultStyle,
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.ellipsis,
      textDirection: ChatHelper.getTextDirection(text),
    );
  }
}
