import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:social_media_app/core/link/model/link_preview_data.dart';
import '../../../features/group_chats/widgets/group_invite_bottom_sheet.dart';
import '../../deep_link/services/deep_link_service.dart';
import '../../helpers/chat_helper.dart';
import '../../helpers/content_deep_link_navigator.dart';

class LinkPreviewCard extends StatelessWidget {
  final LinkPreviewData data;
  final bool onColoredBubble;

  const LinkPreviewCard({
    super.key,
    required this.data,
    this.onColoredBubble = false,
  });

  bool get _looksLikeVideo {
    final host = data.domain.toLowerCase();
    return host.contains('youtube') ||
        host.contains('youtu.be') ||
        (host.contains('facebook.com') &&
            (data.url.contains('/reel') || data.url.contains('/videos'))) ||
        host.contains('tiktok.com');
  }

  void _handleTap(BuildContext context) {
    final uri = Uri.tryParse(data.url);
    if (uri != null && uri.host == DeepLinkService.host) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2) {
        final type = segments[0];
        final id = segments[1];
        if (type == 'join') {
          GroupInviteBottomSheet.show(context, id);
          return;
        } else if (type == 'post') {
          ContentDeepLinkNavigator.openPost(id);
          return;
        } else if (type == 'story') {
          ContentDeepLinkNavigator.openStoryById(id);
          return;
        }
      }
    }

    launchUrl(Uri.parse(data.url), mode: LaunchMode.externalApplication);
  }

  Widget _buildPreviewImage(ThemeData theme, bool useLightContent) {
    final imageUrl = data.imageUrl!;
    final isAsset = !imageUrl.startsWith('http');

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.91 / 1,
          child:
              isAsset
                  ? Image.asset(imageUrl, fit: BoxFit.cover)
                  : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    httpHeaders: const {
                      'User-Agent':
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                      'Accept':
                          'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
                    },
                    errorWidget:
                        (context, url, error) =>
                            _buildElegantFallback(theme, useLightContent),
                  ),
        ),
        if (_looksLikeVideo)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
              border: Border.all(color: Colors.white30, width: 1),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = theme.primaryColor;
    final bubbleIsDark =
        ThemeData.estimateBrightnessForColor(bubbleColor) == Brightness.dark;
    final useLightContent = onColoredBubble && bubbleIsDark;

    final borderColor =
        useLightContent
            ? Colors.white.withValues(alpha: 0.15)
            : theme.dividerColor.withValues(alpha: 0.08);

    final bgColor =
        useLightContent
            ? Colors.white.withValues(alpha: 0.08)
            : (isDark ? Colors.grey.shade900 : Colors.grey.shade50);

    final fg = useLightContent ? Colors.white : theme.colorScheme.onSurface;
    final domainColor =
        useLightContent ? Colors.white70 : theme.colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.hasImage) _buildPreviewImage(theme, useLightContent),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.title != null && data.title!.isNotEmpty)
                    Text(
                      data.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: ChatHelper.getTextDirection(data.title!),
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  if (data.description != null &&
                      data.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      data.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: ChatHelper.getTextDirection(
                        data.description!,
                      ),
                      style: TextStyle(
                        color:
                            useLightContent
                                ? Colors.white60
                                : theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: domainColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.link_rounded,
                            size: 12,
                            color: domainColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            data.domain.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: domainColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantFallback(ThemeData theme, bool useLightContent) {
    return Container(
      color:
          useLightContent
              ? Colors.white.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_rounded,
            color:
                useLightContent
                    ? Colors.white54
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Preview not available',
            style: TextStyle(
              color:
                  useLightContent
                      ? Colors.white54
                      : theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
