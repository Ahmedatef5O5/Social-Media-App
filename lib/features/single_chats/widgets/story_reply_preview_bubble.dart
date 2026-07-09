import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/cache/utils/cloudinary_url_extensions.dart';
import '../../../core/helpers/story_reply_navigator.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../models/message_model.dart';

class StoryReplyPreviewBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const StoryReplyPreviewBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  static const double _thumbnailSize = 46;

  @override
  Widget build(BuildContext context) {
    if (!message.isStoryReply) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final type = message.replyToStoryType;
    final storyText = message.replyToStoryText?.trim();

    final Color surfaceColor =
        isMe
            ? Colors.white.withValues(alpha: 0.16)
            : (isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.grey1);

    final Color accentColor =
        isMe ? Colors.white : Theme.of(context).primaryColor;
    final Color subTextColor =
        isMe
            ? Colors.white70
            : (isDarkMode ? Colors.white60 : AppColors.greyColor);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => StoryReplyNavigator.openOriginalStory(context, message),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accentColor, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildThumbnail(type),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.motion_photos_on,
                          size: 13,
                          color: accentColor,
                        ),
                        const Gap(4),
                        Text(
                          'Replied to Story',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    const Gap(3),
                    Text(
                      _previewLabel(type, storyText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: subTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _previewLabel(String? type, String? storyText) {
    if (storyText != null && storyText.isNotEmpty) return storyText;
    switch (type) {
      case 'video':
        return '🎥 Video';
      case 'image':
        return '📷 Photo';
      default:
        return 'Text status';
    }
  }

  Widget _buildThumbnail(String? type) {
    final mediaUrl = message.replyToStoryMediaUrl;
    final storyText = message.replyToStoryText?.trim();

    if (type == 'text' || mediaUrl == null || mediaUrl.isEmpty) {
      final bg = _parseBgColor(message.replyToStoryBgColor);
      return Container(
        width: _thumbnailSize,
        height: _thumbnailSize,
        padding: const EdgeInsets.all(5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bg, bg.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          storyText?.isNotEmpty == true ? storyText! : 'Aa',
          maxLines: 3,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      );
    }

    final displayUrl =
        type == 'video' ? mediaUrl.cloudinaryVideoThumbnailUrl : mediaUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _thumbnailSize,
        height: _thumbnailSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (displayUrl != null)
              CachedCloudinaryImage(
                secureUrl: displayUrl,
                width: _thumbnailSize,
                height: _thumbnailSize,
                fit: BoxFit.cover,
                errorWidget:
                    (context, error) => Container(color: Colors.grey.shade700),
              )
            else
              Container(color: Colors.grey.shade700),
            if (type == 'video')
              Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseBgColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primaryColor;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.primaryColor;
    }
  }
}
