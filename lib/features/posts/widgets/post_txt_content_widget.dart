import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/emoji_helper.dart';
import '../../../core/link/widgets/message_link_preview.dart';
import '../../../core/mentions/widgets/mention_rich_text.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/post_model.dart';

class PostTxtContentWidget extends StatefulWidget {
  const PostTxtContentWidget({super.key, required this.post});

  final PostModel post;

  @override
  State<PostTxtContentWidget> createState() => _PostTxtContentWidgetState();
}

class _PostTxtContentWidgetState extends State<PostTxtContentWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String postText = EmojiHelper.normalize(widget.post.text.trim());

    if (postText.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool hasMedia =
        (widget.post.imageUrl?.isNotEmpty ?? false) ||
        (widget.post.videoUrl?.isNotEmpty ?? false) ||
        (widget.post.fileUrl?.isNotEmpty ?? false);
    final int maxLines = hasMedia ? 2 : 5;

    final bool isArabic = ChatHelper.isArabic(postText);
    final TextDirection textDirection =
        isArabic ? TextDirection.rtl : TextDirection.ltr;

    final String readMoreTxt = isArabic ? '...قراءة المزيد' : 'Read more...';
    final String readLessTxt = isArabic ? 'عرض أقل' : 'Show less';

    final textStyle =
        (Theme.of(context).textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 15,
          fontFamily: null,
          fontFamilyFallback: AppTypography.fontFallback,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final TextPainter textPainter = TextPainter(
                text: TextSpan(text: postText, style: textStyle),
                maxLines: maxLines,
                textDirection: textDirection,
              )..layout(maxWidth: constraints.maxWidth);

              final bool isOverflowing = textPainter.didExceedMaxLines;

              return GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTap:
                    (_isExpanded || !isOverflowing)
                        ? null // Let the tap bubble up to the post item if already expanded
                        : () {
                          setState(() {
                            _isExpanded = true;
                          });
                        },
                child: MessageLinkPreview(
                  text: postText,
                  isMe: false,
                  textWidget: Column(
                    crossAxisAlignment:
                        isArabic
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      MentionRichText(
                        text: postText,
                        mentions: widget.post.mentions,
                        maxLines: _isExpanded ? null : maxLines,
                        overflow:
                            _isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                        style: textStyle,
                        onMentionTap: (userId, name) {
                          final currentUserId = SupabaseProvider.idOrNull;
                          if (userId == currentUserId) return;
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.profileViewRoute,
                            arguments: userId,
                          );
                        },
                      ),

                      if (isOverflowing)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 4.0,
                              bottom: 2.0,
                            ),
                            child: Text(
                              _isExpanded ? readLessTxt : readMoreTxt,
                              style: textStyle.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: null,
                                fontFamilyFallback: AppTypography.fontFallback,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Gap(8),
        ],
      ),
    );
  }
}
