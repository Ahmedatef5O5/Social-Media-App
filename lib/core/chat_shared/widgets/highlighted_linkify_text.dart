import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/group_chats/widgets/group_invite_bottom_sheet.dart';
import '../../deep_link/services/deep_link_service.dart';
import '../../design/tokens/typography.dart';
import '../../helpers/chat_helper.dart';
import '../../helpers/content_deep_link_navigator.dart';
import '../../helpers/emoji_helper.dart';
import '../../notifications/notification_navigator_key.dart';

class HighlightedLinkifyText extends StatefulWidget {
  final String text;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextDirection? textDirection;
  final String? highlightQuery;
  final TextStyle? highlightStyle;

  const HighlightedLinkifyText({
    super.key,
    required this.text,
    this.maxLines,
    this.overflow,
    this.style,
    this.linkStyle,
    this.textDirection,
    this.highlightQuery,
    this.highlightStyle,
  });

  @override
  State<HighlightedLinkifyText> createState() => _HighlightedLinkifyTextState();
}

class _HighlightedLinkifyTextState extends State<HighlightedLinkifyText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _onOpen(String url) async {
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

  List<InlineSpan> _buildSpans(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final baseStyle = (widget.style ??
            Theme.of(context).textTheme.bodyMedium ??
            const TextStyle())
        .copyWith(
          fontSize: widget.style?.fontSize ?? 15,
          fontFamilyFallback: AppTypography.fontFallback,
        );
    final linkStyle =
        widget.linkStyle ??
        const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
          decorationThickness: 0.8,
          fontFamilyFallback: AppTypography.fontFallback,
        );
    final highlightStyle =
        widget.highlightStyle ??
        TextStyle(
          backgroundColor: Colors.yellow.withValues(alpha: 0.55),
          color: baseStyle.color,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: AppTypography.fontFallback,
        );

    final normalizedText = EmojiHelper.normalize(widget.text);
    final query = widget.highlightQuery?.trim() ?? '';
    final elements = linkify(normalizedText);
    final spans = <InlineSpan>[];

    for (final element in elements) {
      if (element is LinkableElement) {
        final recognizer =
            TapGestureRecognizer()..onTap = () => _onOpen(element.url);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: element.text,
            style: linkStyle,
            recognizer: recognizer,
          ),
        );
      } else {
        spans.addAll(
          _highlightPlainText(element.text, query, baseStyle, highlightStyle),
        );
      }
    }

    return spans;
  }

  List<InlineSpan> _highlightPlainText(
    String rawText,
    String query,
    TextStyle baseStyle,
    TextStyle highlightStyle,
  ) {
    final text = EmojiHelper.normalize(rawText);
    if (query.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

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
    final normalizedText = EmojiHelper.normalize(widget.text);
    final direction =
        widget.textDirection ?? ChatHelper.getTextDirection(normalizedText);
    return RichText(
      textDirection: direction,
      textAlign:
          direction == TextDirection.rtl ? TextAlign.right : TextAlign.left,
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.ellipsis,
      text: TextSpan(children: _buildSpans(context)),
    );
  }
}
