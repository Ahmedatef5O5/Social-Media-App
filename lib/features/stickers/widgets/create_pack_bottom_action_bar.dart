import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/sticker_pack_detail_cubit/sticker_pack_detail_cubit.dart';
import '../cubit/sticker_pack_detail_cubit/sticker_pack_detail_state.dart';
import '../model/sticker_pack_model.dart';
import 'download_progress_bar_button.dart';

class CreatePackBottomActionBar extends StatelessWidget {
  final StickerPackModel pack;
  final BuildContext context;
  final ThemeData theme;
  final StickerPackDetailLoaded loaded;

  const CreatePackBottomActionBar({
    super.key,
    required this.pack,
    required this.context,
    required this.theme,
    required this.loaded,
  });

  @override
  Widget build(BuildContext context) {
    final status =
        loaded.isDownloaded
            ? DownloadButtonStatus.downloaded
            : (loaded.downloadProgress != null
                ? DownloadButtonStatus.downloading
                : DownloadButtonStatus.idle);
    final isDownloading = status == DownloadButtonStatus.downloading;
    final progress = loaded.downloadProgress ?? 0.0;
    final totalMb = pack.totalSizeBytes / (1024 * 1024);
    final downloadedMb = totalMb * progress;

    final label =
        '${downloadedMb.toStringAsFixed(1)}/${totalMb.toStringAsFixed(1)} MB  •  ${pack.stickerCount} Stickers';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDownloading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap:
                      () =>
                          context
                              .read<StickerPackDetailCubit>()
                              .cancelDownload(),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.9),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18 * .58,

                      color:
                          theme.colorScheme
                              .copyWith(onSurface: Colors.white)
                              .onSurface,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.grey6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          DownloadProgressBarButton(
            height: 56,
            status: status,
            progress: loaded.downloadProgress ?? 0,
            onDownload:
                () => context.read<StickerPackDetailCubit>().toggleDownloaded(),
            onRemove:
                () => context.read<StickerPackDetailCubit>().toggleDownloaded(),
          ),
        ],
      ),
    );
  }
}
