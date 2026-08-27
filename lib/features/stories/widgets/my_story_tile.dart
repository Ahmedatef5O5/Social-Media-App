import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/stories/cubit/stories_cubit/stories_cubit.dart';
import '../../../core/cache/utils/cloudinary_url_extensions.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/emoji_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/mentions/widgets/mention_rich_text.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../helpers/local_video_thumbnail.dart';
import '../helpers/uploading_indicator_story.dart';
import '../model/story_model.dart';
import '../model/story_stat_model.dart';

class MyStoryTile extends StatelessWidget {
  final StoryModel story;
  final StoryStatModel? stat;
  final bool isDeleting;
  final bool isSelectionMode;
  final bool isSelected;
  final StoriesCubit storiesCubit;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const MyStoryTile({
    super.key,
    required this.story,
    required this.stat,
    required this.isDeleting,
    required this.isSelectionMode,
    required this.isSelected,
    required this.storiesCubit,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewCount = stat?.viewCount ?? 0;
    final reactions = stat?.reactions ?? const [];
    final bool isPending = story.isPendingUpload;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDeleting ? 0.4 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              isSelected
                  ? Border.all(color: theme.primaryColor, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
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
            onLongPress: isDeleting ? null : onLongPress,
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
                          EmojiHelper.normalize(_titleFor(story)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection:
                              story.storyType == StoryType.text
                                  ? ChatHelper.getTextDirection(
                                    story.contentText ?? 'EN',
                                  )
                                  : TextDirection.ltr,
                          style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            fontFamily: null,
                            fontFamilyFallback: AppTypography.fontFallback,
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
                            Text(
                              '$viewCount',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                                fontSize: 13,
                              ),
                            ),
                            const Gap(4),

                            Icon(
                              Icons.visibility_rounded,
                              size: 16,
                              color: theme.primaryColor,
                            ),

                            if (reactions.isNotEmpty) ...[
                              const Gap(12),
                              Expanded(
                                child: _buildReactionsChip(context, reactions),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder:
                        (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                    child:
                        isPending
                            ? UploadingIndicatorStory(
                              key: const ValueKey('uploading'),
                              storyId: story.id,
                              fileSizeBytes: story.fileSizeBytes,
                              storiesCubit: storiesCubit,
                            )
                            : isDeleting
                            ? const Padding(
                              key: ValueKey('deleting'),
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CustomLoadingIndicator(),
                              ),
                            )
                            : isSelectionMode
                            ? Padding(
                              key: const ValueKey('checkbox'),
                              padding: const EdgeInsets.all(12.0),
                              child: _buildCircularCheckbox(theme),
                            )
                            : IconButton(
                              key: const ValueKey('delete-trash'),
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

  Widget _buildCircularCheckbox(ThemeData theme) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? theme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.primaryColor : AppColors.grey5,
            width: 2,
          ),
        ),
        child:
            isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
      ),
    );
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
              right: 2.4,
              bottom: 1.2,
              child: _DurationBadge(seconds: story.videoDurationSeconds),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailContent() {
    switch (story.storyType) {
      case StoryType.image:
        if (story.isPendingUpload) {
          return Image.file(
            File(story.imageUrl!),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          );
        }
        return CachedCloudinaryImage(
          secureUrl: story.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        );
      case StoryType.video:
        if (story.isPendingUpload) {
          return LocalVideoThumbnail(localPath: story.videoUrl!);
        }

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
          ],
        );

      case StoryType.text:
        Color bgColor = AppColors.grey6;
        if (story.backgroundColor != null) {
          String hex = story.backgroundColor!
              .replaceAll('#', '')
              .replaceAll('Color(0x', '')
              .replaceAll(')', '');
          final parsed = int.tryParse(hex, radix: 16);
          if (parsed != null) bgColor = Color(parsed);
        }

        return Container(
          color: bgColor,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: IgnorePointer(
            child: MentionRichText(
              text: story.contentText ?? '',
              mentions: story.mentions,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 6),
              onMentionTap: (userId, name) {},
              onLinkTap: null,
            ),
          ),
        );
    }
  }

  Widget _buildReactionsChip(
    BuildContext context,
    List<StoryReactorModel> reactions,
  ) {
    final counts = <String, int>{};

    for (final r in reactions) {
      counts[r.reaction] = (counts[r.reaction] ?? 0) + 1;
    }

    final entries =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Text.rich(
      TextSpan(
        children: [
          for (final entry in entries.take(4)) ...[
            TextSpan(
              text: '${entry.value} ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            TextSpan(
              text: EmojiHelper.normalize(entry.key),
              style: const TextStyle(
                fontFamily: null,
                fontFamilyFallback: AppTypography.fontFallback,
                fontSize: 12,
              ),
            ),
            const TextSpan(text: '  '),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$m:$s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
