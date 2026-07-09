import 'package:flutter/material.dart';
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
    final viewCount = stat?.viewCount ?? 0;
    final reactions = stat?.reactions ?? const [];

    return Opacity(
      opacity: isDeleting ? 0.4 : 1.0,
      child: ListTile(
        onTap: isDeleting ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: _buildThumbnail(),
        title: Text(
          _titleFor(story),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                FormattedDate.getFormattedDate(story.createdAt, isShort: true),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.remove_red_eye_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 3),
              Text(
                '$viewCount',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              if (reactions.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(child: _buildReactionsChip(reactions)),
              ],
            ],
          ),
        ),
        trailing:
            isDeleting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: onDelete,
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
      width: 52,
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        );
      case StoryType.video:
        // TODO : ملحوظة: مفيش video thumbnail extraction حالياً وقت الرفع،
        //     فبنعرض placeholder ثابت. ممكن نضيفها كتحسين مستقبلي منفصل.

        return Container(
          color: Colors.grey.shade800,
          child: const Icon(Icons.videocam, color: Colors.white70),
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
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$m:$s',
        style: const TextStyle(color: Colors.white, fontSize: 8),
      ),
    );
  }
}
