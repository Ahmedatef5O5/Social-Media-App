import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/emoji_helper.dart';
import '../../../core/mentions/widgets/mention_rich_text.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../models/post_model.dart';
import '../models/post_theme_model.dart';
import 'post_txt_content_widget.dart';
import 'themed_post_canvas.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

/// Renders a themed post's text on its gradient canvas (feed, details, and
/// full-screen viewer). Falls back to plain text when the theme id is unknown.
class ThemedPostCard extends StatelessWidget {
  static const int feedCollapsedMaxLines = 7;

  final PostModel post;
  final PostsCubit? postsCubit;
  final String? heroTag;
  final bool isFullScreen;

  const ThemedPostCard({
    super.key,
    required this.post,
    this.postsCubit,
    this.heroTag,
    this.isFullScreen = false,
  });

  void _onMentionTap(BuildContext context, String userId) {
    final currentUserId = SupabaseProvider.idOrNull;
    if (userId == currentUserId) {
      if (post.authorId == currentUserId) {
        AppToast.info(context.l10n.youMentionedYourselfIn3);
      } else {
        final name =
            (post.authorName?.trim().isNotEmpty ?? false)
                ? post.authorName!.trim()
                : context.l10n.someone;
        AppToast.info(context.l10n.mentionedYouInThis3(name));
      }
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);
  }

  void _openFullScreen(BuildContext context, String resolvedHeroTag) {
    final cubit = postsCubit ?? context.read<PostsCubit?>();
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.fullScreenImageViewRoute,
      arguments: <String, dynamic>{
        'url': '',
        'tag': resolvedHeroTag,
        'postId': post.id,
        'themedPost': post,
        if (cubit != null) 'postsCubit': cubit,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = PostThemeSelection.parse(post.backgroundTheme);
    final text = EmojiHelper.normalize(post.text.trim());
    if (selection == null || text.isEmpty) {
      return isFullScreen
          ? const SizedBox.shrink()
          : PostTxtContentWidget(post: post);
    }

    final theme = selection.theme;
    final hasMotifs = selection.hasMotifs;
    final canvasPadding = ThemedPostCanvas.defaultPaddingFor(
      hasMotifs: hasMotifs,
    );
    final isArabic = ChatHelper.isArabic(text);
    final style = ThemedPostCanvas.textStyleFor(
      theme,
      fontSize: ThemedPostCanvas.fontSizeFor(text),
      base: (Theme.of(context).textTheme.titleSmall ?? const TextStyle())
          .copyWith(
            fontFamily: null,
            fontFamilyFallback: AppTypography.fontFallback,
          ),
    );

    final effectiveHeroTag = heroTag ?? 'themed-post-${post.id}';

    Widget buildCanvas(double availableWidth) {
      final maxTextWidth = math.max(
        80.0,
        availableWidth - canvasPadding.horizontal,
      );

      Widget richText = MentionRichText(
        text: text,
        mentions: post.mentions,
        textAlign: TextAlign.center,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: style,
        mentionColor: theme.mentionColor,
        linkColor: theme.linkColor,
        maxTextWidth: maxTextWidth,
        collapsedMaxLines:
            isFullScreen ? 9999 : ThemedPostCard.feedCollapsedMaxLines,
        onMentionTap: (userId, _) => _onMentionTap(context, userId),
      );

      if (isFullScreen) {
        richText = ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.56,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: richText,
          ),
        );
      }

      return ThemedPostCanvas(
        theme: theme,
        motifs: selection.motifs,
        seed: selection.effectiveSeedForPost(post.id),
        minHeight: isFullScreen ? 280 : 220,
        borderRadius: isFullScreen ? 24 : 20,
        padding: canvasPadding,
        child: richText,
      );
    }

    if (isFullScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: LayoutBuilder(
          builder: (context, constraints) => buildCanvas(constraints.maxWidth),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openFullScreen(context, effectiveHeroTag),
            child: Hero(
              tag: effectiveHeroTag,
              child: Material(
                type: MaterialType.transparency,
                child: buildCanvas(constraints.maxWidth),
              ),
            ),
          );
        },
      ),
    );
  }
}
