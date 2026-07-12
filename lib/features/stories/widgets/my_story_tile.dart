import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/cache/utils/cloudinary_url_extensions.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../model/story_model.dart';
import '../model/story_stat_model.dart';

class MyStoryTile extends StatelessWidget {
  final StoryModel story;
  final StoryStatModel? stat;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MyStoryTile({
    super.key,
    required this.story,
    required this.stat,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewCount = stat?.viewCount ?? 0;
    final reactions = stat?.reactions ?? const [];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDeleting ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isDeleting ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildThumbnail(),
                  const Gap(14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleFor(story),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.grey5,
                            ),
                            const Gap(4),
                            Text(
                              FormattedDate.getFormattedDate(
                                story.createdAt,
                                isShort: false,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.grey6,
                              ),
                            ),
                          ],
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const Gap(4),
                            Text(
                              '$viewCount',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                                fontSize: 13,
                              ),
                            ),
                            if (reactions.isNotEmpty) ...[
                              const Gap(12),
                              Expanded(child: _buildReactionsChip(reactions)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (isDeleting)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: onDelete,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(StoryModel s) {
    if (s.storyType == StoryType.text) {
      return s.contentText?.trim().isNotEmpty == true
          ? s.contentText!
          : 'Text story';
    }
    if (s.caption?.trim().isNotEmpty == true) return s.caption!;
    return s.storyType == StoryType.video ? 'Video story' : 'Photo story';
  }

  Widget _buildThumbnail() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildThumbnailContent(),
          ),
          if (story.storyType == StoryType.video)
            Positioned(
              right: 3,
              bottom: 3,
              child: _DurationBadge(seconds: story.videoDurationSeconds),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailContent() {
    switch (story.storyType) {
      case StoryType.image:
        return CachedCloudinaryImage(
          secureUrl: story.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        );
      case StoryType.video:
        final thumbUrl = story.videoUrl?.cloudinaryVideoThumbnailUrl;
        return Stack(
          fit: StackFit.expand,
          children: [
            thumbUrl != null
                ? CachedCloudinaryImage(
                  secureUrl: thumbUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget:
                      (_, __) => Container(color: Colors.grey.shade800),
                )
                : Container(color: Colors.grey.shade800),
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ),
          ],
        );

      case StoryType.text:
        return Container(
          color:
              story.backgroundColor != null
                  ? Color(int.parse(story.backgroundColor!, radix: 16))
                  : AppColors.grey6,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: Text(
            story.contentText ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
        );
    }
  }

  Widget _buildReactionsChip(List<StoryReactorModel> reactions) {
    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.reaction] = (counts[r.reaction] ?? 0) + 1;
    }
    final entries =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Text(
      entries.take(4).map((e) => '${e.key} ${e.value}').join('  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final int? seconds;
  const _DurationBadge({this.seconds});

  @override
  Widget build(BuildContext context) {
    if (seconds == null) return const SizedBox.shrink();
    final m = (seconds! ~/ 60).toString().padLeft(2, '0');
    final s = (seconds! % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$m:$s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
