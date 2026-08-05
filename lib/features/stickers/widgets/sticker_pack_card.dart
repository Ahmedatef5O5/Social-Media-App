import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../model/sticker_pack_model.dart';
import '../utils/byte_size_utils.dart';
import 'cancel_progress_bubble.dart';
import 'download_progress_bar_button.dart';

class StickerPackCard extends StatelessWidget {
  final StickerPackModel pack;
  final bool isDownloaded;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback onToggleDownload;
  final VoidCallback onCancelDownload;

  const StickerPackCard({
    super.key,
    required this.pack,
    required this.isDownloaded,
    required this.progress,
    required this.onTap,
    required this.onToggleDownload,
    required this.onCancelDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status =
        isDownloaded
            ? DownloadButtonStatus.downloaded
            : (progress != null
                ? DownloadButtonStatus.downloading
                : DownloadButtonStatus.idle);
    final isDownloading = status == DownloadButtonStatus.downloading;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: isDownloading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDownloaded
                    ? theme.primaryColor.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedCloudinaryImage(
                    secureUrl: pack.coverUrl,
                    fit: BoxFit.contain,
                    placeholder: (context) => const CustomLoadingIndicator(),
                    errorWidget:
                        (context, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.2),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            size: 32,
                          ),
                        ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                pack.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(4),
            Text(
              pack.totalSizeBytes > 0
                  ? '${pack.stickerCount} stickers  •  ${pack.totalSizeBytes.asReadableSize}'
                  : '${pack.stickerCount} stickers',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.grey6,
              ),
            ),
            const Gap(10),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Stack(
                clipBehavior: Clip.none,

                children: [
                  DownloadProgressBarButton(
                    status: status,
                    progress: progress ?? 0,
                    onDownload: onToggleDownload,
                    onRemove: onToggleDownload,
                  ),
                  CancelProgressBubble(
                    size: 16,
                    visible: status == DownloadButtonStatus.downloading,
                    onCancel: onCancelDownload,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
