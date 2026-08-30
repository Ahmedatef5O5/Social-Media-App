import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/group_chats/widgets/group_invite_bottom_sheet.dart';
import '../deep_link/services/deep_link_service.dart';
import '../design/tokens/typography.dart';
import '../helpers/chat_helper.dart';
import '../helpers/content_deep_link_navigator.dart';
import '../helpers/emoji_helper.dart';
import '../helpers/link_color_helper.dart';
import '../notifications/notification_navigator_key.dart';

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
    final uri = Uri.tryParse(link.url);

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

  @override
  Widget build(BuildContext context) {
    final linkColor =
        bubbleColor == null
            ? Colors.blue
            : LinkColorHelper.forBubble(bubbleColor!);

    final normalizedText = EmojiHelper.normalize(text);

    return Linkify(
      text: normalizedText,
      textDirection: textDirection ?? ChatHelper.getTextDirection(text),
      onOpen: _onOpen,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      style: (style ??
              Theme.of(context).textTheme.bodyMedium ??
              const TextStyle())
          .copyWith(
            fontSize: style?.fontSize ?? 15,
            fontFamily: null,
            fontFamilyFallback: AppTypography.fontFallback,
          ),
      linkStyle:
          linkStyle ??
          TextStyle(
            color: linkColor,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
            decorationThickness: 0.8,
            fontFamily: null,
            fontFamilyFallback: AppTypography.fontFallback,
          ),
    );
  }
}
