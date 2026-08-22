import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/chat_helper.dart';
import '../helpers/link_color_helper.dart';

class CustomLinkifyText extends StatelessWidget {
  final String text;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextDirection? textDirection;
  final Color? bubbleColor;

  const CustomLinkifyText({
    super.key,
    required this.text,
    this.maxLines,
    this.overflow,
    this.style,
    this.linkStyle,
    this.textDirection,
    this.bubbleColor,
  });

  Future<void> _onOpen(LinkableElement link) async {
    final uri = Uri.parse(link.url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkColor =
        bubbleColor == null
            ? Colors.blue
            : LinkColorHelper.forBubble(bubbleColor!);

    return Linkify(
      text: text,
      textDirection: textDirection ?? ChatHelper.getTextDirection(text),
      // textDirection,
      onOpen: _onOpen,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      style:
          style ??
          Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 15),
      linkStyle:
          linkStyle ??
          TextStyle(
            color: linkColor,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
            decorationThickness: 0.8,
          ),
    );
  }
}
