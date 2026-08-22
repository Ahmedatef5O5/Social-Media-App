import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/cache/utils/cloudinary_url_extensions.dart';
import '../../../core/mentions/widgets/mention_rich_text.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../helpers/local_video_thumbnail.dart';
import '../model/story_model.dart';
import '../model/story_stat_model.dart';

class StoryGridTile extends StatelessWidget {
  final StoryModel story;
  final StoryStatModel? stat;
  final bool showAnalytics;
  final VoidCallback onTap;

  const StoryGridTile({
    super.key,
    required this.story,
    required this.stat,
    required this.showAnalytics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnail(),

            if (showAnalytics || story.storyType == StoryType.video)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black38],
                      stops: [0.7, 1.0],
                    ),
                  ),
                ),
              ),

            if (story.storyType == StoryType.video)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),

            if (showAnalytics && (stat?.reactionCount ?? 0) > 0)
              Positioned(
                left: 6,
                bottom: 6,
                child: _AnalyticsChip(
                  icon: Icons.favorite_rounded,
                  value: stat?.reactionCount ?? 0,
                ),
              ),

            if (showAnalytics)
              Positioned(
                right: 6,
                bottom: 6,
                child: _AnalyticsChip(
                  icon: Icons.visibility_rounded,
                  value: stat?.viewCount ?? 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    switch (story.storyType) {
      case StoryType.image:
        if (story.isPendingUpload) {
          return Image.file(File(story.imageUrl!), fit: BoxFit.cover);
        }
        return CachedCloudinaryImage(
          secureUrl: story.imageUrl!,
          fit: BoxFit.cover,
          errorWidget: (_, __) => Container(color: Colors.grey.shade800),
        );

      case StoryType.video:
        if (story.isPendingUpload) {
          // LocalVideoThumbnail renders at a fixed 60x60 — scale it up to
          // fill the (much larger) grid cell.
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 60,
              height: 60,
              child: LocalVideoThumbnail(localPath: story.videoUrl!),
            ),
          );
        }
        final thumbUrl = story.videoUrl?.cloudinaryVideoThumbnailUrl;
        return thumbUrl != null
            ? CachedCloudinaryImage(
              secureUrl: thumbUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __) => Container(color: Colors.grey.shade800),
            )
            : Container(color: Colors.grey.shade800);

      case StoryType.text:
        Color bgColor = AppColors.grey6;
        if (story.backgroundColor != null) {
          final hex = story.backgroundColor!
              .replaceAll('#', '')
              .replaceAll('Color(0x', '')
              .replaceAll(')', '');
          final parsed = int.tryParse(hex, radix: 16);
          if (parsed != null) bgColor = Color(parsed);
        }

        return Container(
          color: bgColor,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          child: IgnorePointer(
            child: MentionRichText(
              text: story.contentText ?? '',
              mentions: story.mentions,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              onMentionTap: (userId, name) {},
              onLinkTap: null,
            ),
          ),
        );
    }
  }
}

class _AnalyticsChip extends StatelessWidget {
  final IconData icon;
  final int value;

  const _AnalyticsChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCount(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          Icon(icon, size: 12, color: Colors.white),
        ],
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}
