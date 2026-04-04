import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';

class FileAttachmentPreview extends StatelessWidget {
  final String url;
  final void Function()? onTap;
  const FileAttachmentPreview({super.key, required this.url, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fileName = url.split('/').last.split('?').first;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.blueGrey1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file,
              color: Theme.of(context).primaryColor,
            ),
            const Gap(10),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: AppColors.black),
              ),
            ),
            Icon(Icons.download_rounded, size: 20, color: AppColors.blueGrey3),
          ],
        ),
      ),
    );
  }
}
