import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/attachment/widgets/transfer_ring.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utilities/file_size_formatter.dart';
import '../cubit/stories_cubit/stories_cubit.dart';

class UploadingIndicatorStory extends StatelessWidget {
  final String storyId;
  final int? fileSizeBytes;
  final StoriesCubit storiesCubit;

  const UploadingIndicatorStory({
    super.key,
    required this.storyId,
    required this.fileSizeBytes,
    required this.storiesCubit,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: storiesCubit.progressNotifierFor(storyId),
      builder: (context, progress, _) {
        final ratioText = formatMediaFileSizeRatio(
          ((fileSizeBytes ?? 0) * progress).round(),
          fileSizeBytes,
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ratioText.isNotEmpty) ...[
              Text(
                ratioText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey6,
                ),
              ),
              const Gap(8),
            ],
            TransferRing(
              size: 32,
              progress: progress,
              icon: Icons.close_rounded,
              iconColor: Colors.red.shade700,
              onTap: () {
                storiesCubit.cancelStoryUpload(storyId);
              },
            ),
          ],
        );
      },
    );
  }
}
